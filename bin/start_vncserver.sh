#!/bin/sh
vnc2hpc_version="$1"
windowmanager="$2"
client="$3"
clientOS="$4"
geometry="$5"
pixeldepth="$6"
if [[ "${7}x" != x ]] ; then DISPLAYPORT=":${7}" ; fi 
LOG="/usr/projects/hpcsoft/vnc2hpc/${vnc2hpc_version}/logs/$(/usr/projects/hpcsoft/utilities/bin/sys_name)/${USER}_`hostname -s`.$(date +%F'_'%H'.'%M'.'%S)"
touch $LOG
[ -d $HOME/.vnc2hpc ] || mkdir -p $HOME/.vnc2hpc
cp /usr/projects/hpcsoft/vnc2hpc/${vnc2hpc_version}/bin/xstartup $HOME/.vnc2hpc/xstartup
export VNC2HPC_WM="$windowmanager" 
if [[ $geometry != "false" ]] ; then geoarg="-geometry ${geometry}" ; fi 
pixeldeptharg="-depth ${pixeldepth}" 
/usr/bin/vncserver ${DISPLAYPORT} ${geoarg} ${pixeldeptharg} -localhost -verbose -name "$USER at `hostname -s` VNC2HPC v$vnc2hpc_version $windowmanager `date`" -autokill ${pixeldeptharg} -xstartup "$HOME/.vnc2hpc/xstartup" &>$LOG

if [[ $? -ne 0 ]] ; then 
   displayport=FAILURE
else  
   displayport=$(awk -F: '/^New/ {print $NF}' $LOG) 
fi 
echo "RUNNING: /usr/bin/vncserver ${DISPLAYPORT} ${geoarg} ${pixeldeptharg} -localhost -verbose -name \"$USER at `hostname -s` VNC2HPC v$vnc2hpc_version $windowmanager `date`\" -autokill ${pixeldeptharg} -xstartup \"$HOME/.vnc2hpc/xstartup\"" &>>$LOG
echo $displayport
