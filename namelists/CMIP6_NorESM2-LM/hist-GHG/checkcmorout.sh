#!/bin/bash

version=v20191108
expid=hist-GHG
model=NorESM2-LM
years1=(1849 $(seq 1850 10 2000) 2010)
years2=(1859 $(seq 1859 10 2009) 2014)
years1+=(2015)
years2+=(2020)


if [ $(hostname -f |grep 'ipcc') ]
then
    wfroot=/scratch/NS9034K/noresm2cmor/workflow
else
    wfroot=~/noresm2cmor/workflow
fi
${wfroot}/cmorCheck.sh -v=$version -e=$expid -m=$model -yrs1="${years1[*]}" -yrs2="${years2[*]}"

