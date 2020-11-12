#!/bin/sh
vnc2hpc_version="$1"
windowmanager="$2"
client="$3"
clientOS="$4"
if [[ "${5}x" != x ]] ; then DISPLAYPORT=":${5}" ; fi 
LOG="/usr/projects/hpcsoft/vnc2hpc/${vnc2hpc_version}/logs/$(/usr/projects/hpcsoft/utilities/bin/sys_name)/${USER}_`hostname -s`.$(date +%F'_'%H'.'%M'.'%S)"
touch $LOG
[ -d $HOME/.vnc2hpc ] || mkdir -p $HOME/.vnc2hpc
cp /usr/projects/hpcsoft/vnc2hpc/${vnc2hpc_version}/bin/xstartup $HOME/.vnc2hpc/xstartup
export VNC2HPC_WM="$2" 
/usr/bin/vncserver ${DISPLAYPORT} -localhost -verbose -name "$USER at `hostname -s` VNC2HPC v$vnc2hpc_version $windowmanager `date`" -autokill -depth 16 -xstartup "$HOME/.vnc2hpc/xstartup" &>$LOG

if [[ $? -ne 0 ]] ; then 
   displayport=FAILURE
else  
   displayport=$(awk -F: '/^New/ {print $NF}' $LOG) 
fi 
echo "RUNNING: /usr/bin/vncserver ${DISPLAYPORT} -localhost -verbose -name \"$USER at `hostname -s` VNC2HPC v$vnc2hpc_version $windowmanager `date`\" -autokill -depth 16 -xstartup \"$HOME/.vnc2hpc/xstartup\"" &>>$LOG
echo $displayport
