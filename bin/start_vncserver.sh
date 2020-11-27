#!/bin/sh
vnc2hpc_version="$1"
windowmanager="$2"
client="$3"
clientOS="$4"
geometry="$5"
pixeldepth="$6"
backstore="-bs"
HPCSOFT_PATH="/usr/projects/hpcsoft"
SPLUNK_LOG="${HPCSOFT_PATH}/usage_logs/vnc2hpc.log"
if [[ "${7}x" != x ]] ; then DISPLAYPORT=":${7}" ; fi 
[ -d $HOME/.vnc2hpc ] || mkdir -p $HOME/.vnc2hpc
if [[ -d "/usr/projects/hpcsoft/vnc2hpc/${vnc2hpc_version}/logs/$(/usr/projects/hpcsoft/utilities/bin/sys_name)" ]] ; then 
   LOG="/usr/projects/hpcsoft/vnc2hpc/${vnc2hpc_version}/logs/$(/usr/projects/hpcsoft/utilities/bin/sys_name)/${USER}_`hostname -s`.$(date +%F'_'%H'.'%M'.'%S)"
else
   # this script shouldn't fail if the logtree structure doesn't exist, fall back to $HOME
   LOG="$HOME/.vnc2hpc/${USER}_`hostname -s`.$(date +%F'_'%H'.'%M'.'%S)"
fi 
touch $LOG
cp -f /usr/projects/hpcsoft/vnc2hpc/${vnc2hpc_version}/bin/xstartup $HOME/.vnc2hpc/xstartup || echo  "FAILURE"
export VNC2HPC_WM="$windowmanager" 
if [[ $geometry != "default" ]] ; then geoarg="-geometry ${geometry}" ; fi 
pixeldeptharg="-depth ${pixeldepth}" 
echo "RUNNING: /usr/bin/vncserver ${DISPLAYPORT} ${backstore} ${geoarg} ${pixeldeptharg} -localhost -verbose -name \"$USER at `hostname -s` VNC2HPC v$vnc2hpc_version $windowmanager `date`\" -autokill ${pixeldeptharg} -xstartup \"$HOME/.vnc2hpc/xstartup\"" &>$LOG
/usr/bin/vncserver ${DISPLAYPORT} ${backstore} ${geoarg} ${pixeldeptharg} -localhost -verbose -name "$USER at `hostname -s` VNC2HPC v$vnc2hpc_version $windowmanager `date`" -autokill ${pixeldeptharg} -xstartup "$HOME/.vnc2hpc/xstartup" &>>$LOG

if [[ $? -ne 0 ]] ; then 
   displayport=FAILURE
   RESULT="FAIL"
else  
   displayport=$(awk -F: '/^New/ {print $NF}' $LOG) 
   RESULT="PASS"
fi 
echo $displayport
echo "$(date +%F' '%H':'%M':'$S) VNC2HPC_VERSION=${vnc2hpc_version} USER=${USER} CLIENT=${CLIENT} CLIENTOS=${CLIENTOS} $MACHINE=$(hostname -s) WINDOWMANAGER=${windowmanager} VNCSERVER=$(which vncserver) DISPLAYPORT=${displayport} BACKSTORE=${backstore} GEOMETRY=${geoarg} PIXELDEPTH=${pixeldepth} RESULT=${RESULT}" &>>$SPLUNK_LOG
