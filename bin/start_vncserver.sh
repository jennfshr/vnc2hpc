#!/bin/bash
LOG="/usr/projects/hpcsoft/vnc2hpc/logs/$(/usr/projects/hpcsoft/utilities/bin/sys_name)/${USER}_`hostname -s`.$(date +%F'_'%H'.'%M'.'%S)"
displayport=$1
vnc2hpc_version=$2
windowmanager=$3
client=$4
clientOS=$5
/usr/bin/vncserver :$displayport -name "$USER at `hostname -s`:$displayport $windowmanager" -autokill -depth 16 -xstartup /usr/projects/hpcsoft/vnc2hpc/0.0.2/bin/xstartup  &>$LOG &
pid=$!
while kill -0 "$pid"&>/dev/null; do
   sleep 1
done 
#New 'jgreen at fg-fey1:14 mwm' desktop is fg-fey1.lanl.gov:17
displayport=$(awk -F: '/^New/ {print $3}' $LOG) 
echo "USER=$USER HOSTNAME=`hostname -s` PID=$pid WINDOWMANAGER=$windowmanager VNC2HPC_VERSION=$vnc2hpc_version CLIENT=$client CLIENTOS=$clientOS COMMAND:(/usr/bin/vncserver :$displayport -name "$USER at `hostname -s`:$displayport $windowmanager" -autokill -depth 16 -xstartup /usr/projects/hpcsoft/vnc2hpc/0.0.2/bin/xstartup &>/dev/null )" &> $LOG
echo $displayport
