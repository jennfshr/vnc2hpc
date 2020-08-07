#!/bin/bash

usage () {
    echo "$0 runs on LANL HPC systems where $moddir exist"
    echo "It generates or ensures a tree structure that will capture PVSC logs"
    echo "in the form \${PVSC_ROOT}/log/\$machine"
    echo "and ensures permissions are set for hpcsoft unix group readability"
} 

REALPATH=$(realpath "${0}")
ROOT=$(dirname ${REALPATH%\/*})
moddir="/usr/projects/hpcsoft/modulefiles"

if [ ! -d $moddir ]
then
    echo "$moddir doesn't exist on `hostname`!"
    echo "$0 cannot run!"
    usage
    exit 2
fi
if [ ! -d ${ROOT}/logs ]
then
    mkdir -p ${ROOT}/logs
fi
chgrp -Rf hpcsoft ${ROOT}/logs
chmod -Rf 2773 ${ROOT}/logs

# iterate through the subdirectories of os versions in the modulefile tree for machines- ignore templates directories
for os in  $(ls $moddir | grep "^[a-z].*[0-9]$" )
do
    for machine in $(ls ${moddir}/${os}/)
    do
        if [ ! -d ${ROOT}/logs/${machine} ]
        then
            mkdir -p ${ROOT}/logs/${machine}
            chgrp -Rf hpcsoft ${ROOT}/logs/${machine}
            chmod -Rf 2773 ${ROOT}/logs/${machine}
        fi
    done
done
