#!/bin/sh
vnc2hpc_version="$1"
windowmanager="$2"
client="$3"
clientOS="$4"
geometry="$5"
pixeldepth="$6"
remote_install_path="$7"
export VNC2HPC_INSTALL_PATH=${remote_install_path}
if [[ "${8}x" != x ]] ; then DISPLAYPORT=":${8}" ; fi 
[ -d $HOME/.vnc2hpc ] || mkdir -p $HOME/.vnc2hpc
if [[ -d "/usr/projects/hpcsoft/vnc2hpc/${vnc2hpc_version}/logs/$(/usr/projects/hpcsoft/utilities/bin/sys_name)" ]] ; then 
   LOG="/usr/projects/hpcsoft/vnc2hpc/${vnc2hpc_version}/logs/$(/usr/projects/hpcsoft/utilities/bin/sys_name)/${USER}_`hostname -s`.$(date +%F'_'%H'.'%M'.'%S)"
else
   # this script shouldn't fail if the logtree structure doesn't exist, fall back to $HOME
   LOG="${HOME}/.vnc2hpc/${USER}_`hostname -s`.$(date +%F'_'%H'.'%M'.'%S)"
fi 
touch $LOG
cp ${remote_install_path}/bin/xstartup $HOME/.vnc2hpc/xstartup
export VNC2HPC_WM="$windowmanager" 
if [[ $geometry != "default" ]] ; then geoarg="-geometry ${geometry}" ; fi 
pixeldeptharg="-depth ${pixeldepth}" 
/usr/bin/vncserver ${DISPLAYPORT} ${geoarg} ${pixeldeptharg} -localhost -verbose -name "$USER at `hostname -s` VNC2HPC v$vnc2hpc_version $windowmanager `date`" -autokill ${pixeldeptharg} -xstartup "$HOME/.vnc2hpc/xstartup" &>$LOG

if [[ $? -ne 0 ]] ; then 
   displayport=FAILURE
else  
   displayport=$(awk -F: '/^New/ {print $NF}' $LOG) 
fi 
echo "RUNNING: /usr/bin/vncserver ${DISPLAYPORT} ${geoarg} ${pixeldeptharg} -localhost -verbose -name \"$USER at `hostname -s` VNC2HPC v$vnc2hpc_version $windowmanager `date`\" -autokill ${pixeldeptharg} -xstartup \"$HOME/.vnc2hpc/xstartup\"" &>>$LOG
echo $displayport
