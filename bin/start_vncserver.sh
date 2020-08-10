#!/bin/bash
vnc2hpc_version="$1"
windowmanager="$2"
client="$3"
clientOS="$4"
if [[ "${5}x" != x ]] ; then DISPLAYPORT=":${5}" ; fi 
LOG="/usr/projects/hpcsoft/vnc2hpc/${vnc2hpc_version}/logs/$(/usr/projects/hpcsoft/utilities/bin/sys_name)/${USER}_`hostname -s`.$(date +%F'_'%H'.'%M'.'%S)"
touch $LOG
/usr/bin/vncserver ${DISPLAYPORT} -name "$USER at `hostname -s`:$displayport $windowmanager" -autokill -depth 16 -xstartup "/usr/projects/hpcsoft/vnc2hpc/0.0.2/bin/xstartup $windowmanager" &>$LOG

if [[ $? -ne 0 ]] ; then 
   displayport=FAILURE ; 
else  
   displayport=$(awk -F: '/^New/ {print $3}' $LOG) 
fi 
echo "USER=$USER HOSTNAME=`hostname -s` DISPLAYPORT=${displayport} PID=$pid WINDOWMANAGER=$windowmanager VNC2HPC_VERSION=$vnc2hpc_version CLIENT=$client CLIENTOS=$clientOS COMMAND:(/usr/bin/vncserver -name "$USER at `hostname -s`:$displayport $windowmanager" -autokill -depth 16 -xstartup /usr/projects/hpcsoft/vnc2hpc/0.0.2/bin/xstartup &>/dev/null )" &> $LOG
echo $displayport
