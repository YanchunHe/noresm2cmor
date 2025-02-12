# submit comrisation for multiple realization
function runcmor {
#
local CaseName expid version years1 years2 year1 year2
local month1 month2 yyyy1 yyyy2 mm1 mm2 reals membs
local system mpi
local nmlroot logroot
#
if [ $# -eq 0 ] || [ $1 == "--help" ] 
 then
     printf "Usage:\n"
     printf 'runcmor -c=[CaseName] -m=[model] -e=[expid] -v=[version] -yrs1=["${years1[*]}"] -yrs2=["${years2[*]}"] \\ \n'
     printf '        -mon1=month1 -mon2=month2 \\ \n' 
     printf '        -r=["${reals[*]}"] -membs=["${membs[*]}"] \\ \n'
     printf '        -s=[system] -mpi=[DMPI] \n'
     return
 else
     while test $# -gt 0; do
         case "$1" in
             -c=*)
                 CaseName=$(echo $1|sed -e 's/^[^=]*=//g')
                 shift
                 ;;
             -m=*)
                 model=$(echo $1|sed -e 's/^[^=]*=//g')
                 shift
                 ;;
             -e=*)
                 expid=$(echo $1|sed -e 's/^[^=]*=//g')
                 shift
                 ;;
             -v=*)
                 version=$(echo $1|sed -e 's/^[^=]*=//g')
                 shift
                 ;;
             -r=*)
                 reals=($(echo $1|sed -e 's/^[^=]*=//g'))
                 shift
                 ;;
             -yrs1=*)
                 years1=($(echo $1|sed -e 's/^[^=]*=//g'))
                 shift
                 ;;
             -yrs2=*)
                 years2=($(echo $1|sed -e 's/^[^=]*=//g'))
                 shift
                 ;;
             -mon1=*)
                 month1=$(echo $1|sed -e 's/^[^=]*=//g')
                 shift
                 ;;
             -mon2=*)
                 month2=$(echo $1|sed -e 's/^[^=]*=//g')
                 shift
                 ;;
             -membs=*)
                 membs=($(echo $1|sed -e 's/^[^=]*=//g'))
                 shift
                 ;;
             -s=*)
                 system=$(echo $1|sed -e 's/^[^=]*=//g')
                 shift
                 ;;
             -mpi=*)
                 mpi=$(echo $1|sed -e 's/^[^=]*=//g')
                 shift
                 ;;
             * )
                 echo "ERROR: option $1 not allowed."

                 echo "*** EXITING THE SCRIPT"
                 exit 1
                 ;;
         esac
     done
 fi

echo -e "CaseName: $CaseName"
echo -e "expid   : $expid"
echo -e "model   : $model"
echo -e "version : $version"
if [ ! -z $system ]
then
    echo -e "system : $system"
fi
#echo -e "years1  : ${years1[*]}"
#echo -e "years2  : ${years2[*]}"
# ==========================================================
ulimit -c 0
ulimit -s unlimited
module purge
module load intel/2022a
export PATH=/usr/lib64/openmpi/bin:$PATH
cwd=$(pwd)

cd ${CMOR_ROOT}/bin
nmlroot=${CMOR_ROOT}/namelists/CMIP6_${model}/${expid}/${version}
logroot=${CMOR_ROOT}/logs/CMIP6_${model}/${expid}/${version}

if [ ! -d $logroot ]
then
    mkdir -p $logroot
fi
# check if sys mod var namelist exist
nf=$(ls ${nmlroot}/{mod*.nml,sys*.nml,var*.nml} |wc -l)
if [ $nf -lt 3 ]
then
    echo "ERROR: one or more ${nmlroot}/{mod*.nml,sys*.nml,var*.nml} does not exist"
    echo "EXIT..."
    exit
fi

# if CaseName and realization are defined
if [ ! -z $CaseName ]
then
    CaseName="_${CaseName}"
fi

pid=$$
# copy template namelist and submit
for (( i = 0; i < ${#years1[*]}; i++ )); do

    year1=${years1[i]}
    year2=${years2[i]}
    yyyy1=$(printf "%04i\n" $year1)
    yyyy2=$(printf "%04i\n" $year2)
    mm1=$(printf "%02i\n" $month1)
    mm2=$(printf "%02i\n" $month2)
    echo year month : ${yyyy1}${mm1}-${yyyy2}${mm2}

    for (( j = 0; j < ${#reals[*]}; j++ )); do
        # keep maximumn 8 jobs
        flag=true
        while $flag ; do
            njobs=$(ps ax |grep -v 'grep' |grep -c 'noresm2cmor3')
            npidchild=$(pgrep -P $pid |wc -l)
            # if there are running jobs, but they do not belongs to this shell
            if [ $njobs -ge 1 ] && [ $npidchild -eq 1 ]; then
                sleep 300s
            else
                sleep 30s
            fi
            if [ $njobs -lt 8 ]; then
                flag=false
            fi
        done

        real=${reals[j]}
        memb=${membs[j]}
        echo real member: ${real} ${memb}
        cd ../namelists
        cp CMIP6_NorESM2-LM/${expid}/template/exp${CaseName}.nml \
           CMIP6_NorESM2-LM/${expid}/${version}/exp.nml
        if [ $? -ne 0 ]
        then
            echo "ERROR: copy template exp_*.nml"
            exit
        fi
        sed -i "s/vyyyymmdd/${version}/" \
           CMIP6_NorESM2-LM/${expid}/${version}/exp.nml
        sed -i "s/year1         =.*/year1         = ${year1},/g" \
           CMIP6_NorESM2-LM/${expid}/${version}/exp.nml
        sed -i "s/yearn         =.*/yearn         = ${year2},/g" \
           CMIP6_NorESM2-LM/${expid}/${version}/exp.nml
        sed -i "s/month1        =.*/month1        = ${month1},/g" \
           CMIP6_NorESM2-LM/${expid}/${version}/exp.nml
        sed -i "s/monthn        =.*/monthn        = ${month2},/g" \
           CMIP6_NorESM2-LM/${expid}/${version}/exp.nml
        sed -i "s/realization   =.*/realization   = ${real},/g" \
           CMIP6_NorESM2-LM/${expid}/${version}/exp.nml
        sed -i "s/membertag     =.*/membertag     = ${memb}/g" \
           CMIP6_NorESM2-LM/${expid}/${version}/exp.nml
        mv CMIP6_NorESM2-LM/${expid}/${version}/exp.nml \
           CMIP6_NorESM2-LM/${expid}/${version}/exp_${yyyy1}${mm1}-${yyyy2}${mm2}_r${real}.nml

        cd ../bin

        if [ ! -z $mpi ] && [ $mpi == "DMPI" ]
        then
            nohup mpirun -n 8 ./noresm2cmor3_mpi \
                ${nmlroot}/sys${system}.nml \
                ${nmlroot}/mod.nml \
                ${nmlroot}/exp_${yyyy1}${mm1}-${yyyy2}${mm2}_r${real}.nml \
                ${nmlroot}/var.nml \
                1>${logroot}/${yyyy1}${mm1}-${yyyy2}${mm2}_r${real}.log \
                2>${logroot}/${yyyy1}${mm1}-${yyyy2}${mm2}_r${real}.err &
        else
            nohup ./noresm2cmor3 \
                ${nmlroot}/sys${system}.nml \
                ${nmlroot}/mod.nml \
                ${nmlroot}/exp_${yyyy1}${mm1}-${yyyy2}${mm2}_r${real}.nml \
                ${nmlroot}/var.nml \
                1>${logroot}/${yyyy1}${mm1}-${yyyy2}${mm2}_r${real}.log \
                2>${logroot}/${yyyy1}${mm1}-${yyyy2}${mm2}_r${real}.err &
        fi
    done
done

cd $cwd

}
