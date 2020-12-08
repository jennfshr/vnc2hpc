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
backstore="-bs"
HPCSOFT_PATH="/usr/projects/hpcsoft"
SPLUNK_LOG="${HPCSOFT_PATH}/usage_logs/vnc2hpc.log"
[ -d $HOME/.vnc2hpc ] || mkdir -p $HOME/.vnc2hpc
if [[ -d "/usr/projects/hpcsoft/vnc2hpc/${vnc2hpc_version}/logs/$(/usr/projects/hpcsoft/utilities/bin/sys_name)" ]] ; then 
   LOG="/usr/projects/hpcsoft/vnc2hpc/${vnc2hpc_version}/logs/$(/usr/projects/hpcsoft/utilities/bin/sys_name)/${USER}_`hostname -s`.$(date +%F'_'%H'.'%M'.'%S)"
else
   LOG="${HOME}/.vnc2hpc/${USER}_`hostname -s`.$(date +%F'_'%H'.'%M'.'%S)"
fi 
cp -f ${remote_install_path}/bin/xstartup $HOME/.vnc2hpc/xstartup || echo "FAILURE"
touch $LOG
export VNC2HPC_WM="$windowmanager" 
if [[ -x /usr/projects/hpcsoft/utilities/bin/sys_os ]] ; then
   OS=$(/usr/projects/hpcsoft/utilities/bin/sys_os)
else
   OS=$(uname -o | sed 's/\//_/g')
fi
if [[ -x /usr/projects/hpcsoft/utilities/bin/sys_arch ]] ; then
   ARCH=$(/usr/projects/hpcsoft/utilities/bin/sys_arch)
else
   ARCH=$(uname -p)
fi
case ${VNC2HPC_WM} in
   berry*)	WM="berry"	;;
   ice*)	WM="icewm"	;;
   fvwm)	WM="fvwm"	;;
   openbox)	WM="openbox"	;;
esac
if ! [[ -d /usr/projects/hpcsoft/${OS}/${ARCH}/${VNC2HPC_WM} ]] ; then
   ${VNC2HPC_INSTALL_PATH}/libexec/build_wms.sh -w $WM -p ${HOME}/.vnc2hpc
fi
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
echo "$(date +%F' '%H':'%M':'%S) VNC2HPC_VERSION=${vnc2hpc_version} USER=${USER} CLIENT=${client} CLIENTOS=${clientos} MACHINE=$(hostname -s) WINDOWMANAGER=${windowmanager} VNCSERVER=$(which vncserver) DISPLAYPORT=${displayport} BACKSTORE=${backstore} GEOMETRY=${geometry} PIXELDEPTH=${pixeldepth} RESULT=${RESULT}" &>>$SPLUNK_LOG
