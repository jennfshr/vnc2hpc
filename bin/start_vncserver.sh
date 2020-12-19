#!/bin/bash
# process positional parameters
vnc2hpc_version="$1"
windowmanager="$2"
client="$3"
clientOS="$4"
geometry="$5"
pixeldepth="$6"
remote_install_path="$7"
vncserver_path="$8"

# some conditionals
if [[ "${9}x" != x ]] ; then REMOTE_DISPLAY=":${9}" ; fi 
if [[ $geometry != "default" ]] ; then geoarg="-geometry ${geometry}" ; fi 

# setup pixeldepth arg
pixeldeptharg="-depth ${pixeldepth}" 

# this is required for a weird xvnccrash with MCNP
backstore="-bs"

export VNC2HPC_INSTALL_PATH=${remote_install_path}
export VNC2HPC_WM="$windowmanager" 
HPCSOFT_PATH="/usr/projects/hpcsoft"
if touch ${HPCSOFT_PATH}/usage_logs/vnc2hpc.log &>/dev/null ; then 
   SPLUNK_LOG="${HPCSOFT_PATH}/usage_logs/vnc2hpc.log"
else
   SPLUNK_LOG="${remote_install_path}/vnc2hpc.log"
   touch ${SPLUNK_LOG}
fi

# generic setup if utilities aren't present
if ${HPCSOFT_PATH}/utilities/bin/sys_os &>/dev/null ; then
   OS=$(${HPCSOFT_PATH}/utilities/bin/sys_os)
else
   OS=$(uname -o | sed 's/\//_/g')
fi

# generic setup if utilities aren't present
if ${HPCSOFT_PATH}/utilities/bin/sys_arch &>/dev/null ; then
   ARCH=$(${HPCSOFT_PATH}/utilities/bin/sys_arch)
else
   ARCH=$(uname -p)
fi

# generic setup if utilities aren't present
if ${HPCSOFT_PATH}/utilities/bin/sys_name &>/dev/null ; then
   SYSNAME=$(${HPCSOFT_PATH}/utilities/bin/sys_name)
else
   SYSNAME=$(hostname -s)
fi

[ -d $HOME/.vnc2hpc ] || mkdir -p $HOME/.vnc2hpc

# setup log to capture stdout
if [[ -d "${HPCSOFT_PATH}/vnc2hpc/${vnc2hpc_version}/logs/${SYSNAME}" ]] ; then 
   LOG="${HPCSOFT_PATH}/vnc2hpc/${vnc2hpc_version}/logs/${SYSNAME}/${USER}_`hostname -s`.$(date +%F'_'%H'.'%M'.'%S)"
else
   LOG="${HOME}/.vnc2hpc/${USER}_`hostname -s`.$(date +%F'_'%H'.'%M'.'%S)"
fi 
touch $LOG

cp -f ${remote_install_path}/bin/xstartup $HOME/.vnc2hpc/xstartup || echo "FAILURE"

case ${VNC2HPC_WM} in
   awesome*)    WM="awesome"    ;;
   berry*)	WM="berry"	;;
   ice*)	WM="icewm"	;;
   fvwm)	WM="fvwm"	;;
   openbox)	WM="openbox"	;;
esac

if [[ ! -d "/usr/projects/hpcsoft/${OS}/common/${ARCH}/${VNC2HPC_WM}" || \
   ! -d "$HOME/.vnc2hpc/${OS}/common/${ARCH}/${VNC2HPC_WM}" || \
   ! $(which $VNC2HPC_WM &>/dev/null) ]] ; then
   ${VNC2HPC_INSTALL_PATH}/libexec/build_wms.sh -w $WM -p ${HOME}/.vnc2hpc &>>$LOG
   if [[ $? -ne 0 ]] ; then
      echo "Build of $WM FAILURE on $(hostname)"
      exit 1
   fi
fi

echo "RUNNING: ${vncserver_path} ${REMOTE_DISPLAY} ${backstore} ${geoarg} ${pixeldeptharg} -localhost -verbose -name \"$USER at `hostname -s` VNC2HPC v$vnc2hpc_version $windowmanager `date`\" -autokill ${pixeldeptharg} -xstartup \"$HOME/.vnc2hpc/xstartup\"" &>$LOG
${vncserver_path} ${REMOTE_DISPLAY} ${backstore} ${geoarg} ${pixeldeptharg} -localhost -verbose -name "$USER at `hostname -s` VNC2HPC v$vnc2hpc_version $windowmanager `date`" -autokill ${pixeldeptharg} -xstartup "$HOME/.vnc2hpc/xstartup" &>>$LOG

if [[ $? -ne 0 ]] ; then 
   remote_display="FAILURE: $(tail -n 1 ${LOG})"
   RESULT="FAIL"
else  
   remote_display=$(awk -F: '/^[New|Desktop]/ {print $NF}' $LOG) 
   if [[ "${remote_display}" =~ ^[0-9]+$ ]] ; then
      RESULT="PASS"
   else
      RESULT="FAIL"
   fi
fi 
REMOTE_DISPLAY=$remote_display
echo $REMOTE_DISPLAY
echo "$(date +%F' '%H':'%M':'%S) VNC2HPC_VERSION=${vnc2hpc_version} USER=${USER} CLIENT=${client} CLIENTOS=${clientOS} MACHINE=$(hostname -s) WINDOWMANAGER=${windowmanager} VNCSERVER=${vncserver_path} REMOTE_DISPLAY=${remote_display} BACKSTORE=${backstore} GEOMETRY=${geometry} PIXELDEPTH=${pixeldepth} RESULT=${RESULT}" &>>$SPLUNK_LOG
