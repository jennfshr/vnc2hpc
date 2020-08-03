#!/bin/bash
VERSION="0.0.1"
# this script automates the creation of a ssh local tunnel connection to a LANL front-end 
# it autogenerates a port number to avoid conflicts with others running on vnc ports
# it waits for the vncserver to return success - potentially catching and handling conflicts?
# then it runs a vncviewer command that connects to the server via the tunnel to establish a window connection to the cluster

check_network () {
    local_machine=$1
    case $local_machine in
        *loginy*|*fey*) 
            network="YELLOW"
	    ;;
        ic*|fi*|cy*|tr*|vm*)
	    network="RED"
	    ;;
	*)
	    network="TURQUOISE"
	    ;;
    esac
    echo $network
}

setup_gateway_tunnel () { 
    echo "ssh -fN -t -L 59$PORT:localhost:59$PORT $MACHUSER@wtrw1.lanl.gov"
}

setup_gateway () {
    echo "ssh -t $MACHUSER@wtrw1.lanl.gov"
}
message () {
    local color
    local OPTIND
    local opt
    while getopts "rgymn" opt; do
        case $opt in
            r) 
                color=$(tput setaf 1) ;;
	    g) 
		color=$(tput setaf 2) ;;
	    y)
		color=$(tput setaf 3) ;; 
	    m)
		color=$(tput setaf 5) ;;
            *)
                color=$(tput sgr0) ;; 
        esac
    done
    shift $(($OPTIND -1))
    printf "${color}%-10s %-50s %-30s\n" "$1" "$2" "$3"
    tput sgr0
}

kill_vnc () { 
    LOCAL_PORT=$1
    $GATEWAY ssh $MACHUSER@$machine vncserver -kill :${LOCAL_PORT} 2>&1 
}

warning () {
    message -m "WARN" "$1" "$2" "$3"
}

note () {
    message -y "NOTE" "$1" "$2" "$3"
}

die () {
    message -r "DIE" "$1" "$2" "$3"
    exit 2
}

debug () {
    if [[ ${DEBUG}x != x ]] ; then 
        message -g "DEBUG" "$1" "$2" "$3"
    fi
}

usage () { 
    note "${0//*\//} v${VERSION}
          usage: ${0//*\//} [-d|--debug] [-p|--port <display port>] [-m|--machine <machine>] [-u|--user <hpcuserid> 
	                    [-c|--client <vncclient>] [-k|--keep] [-r|--reconnect] [-h|--help] [-w|--wm] <mwm> 
			    "
}

get_vnc_connections () { 
   declare -a LOCAL_VNC_CONS
   for pt in $(if ! $GATEWAY ssh $MACHUSER@$machine "ps aux| grep -Po \"/usr/bin/Xvnc :([0-9]+)\"|awk -F: '{print \$2}'"; then die "FAILURE CONNECTING TO:" "$machine" ; fi); do 
      LOCAL_VNC_CONS=( $(printf "%s " "${pt}") ${LOCAL_VNC_CONS[@]} )
   done
   echo "${LOCAL_VNC_CONS[@]}"
} 

list_vncservers () { 
   vncservers_list=( $(if ! $GATEWAY ssh $MACHUSER@$machine "vncserver -list|grep -v DISPLAY |grep -v TigerVNC"| awk '{print $1}' |sed 's/://g'; then die "FAILURE CONNECTING TO" "$machine" ; fi) )
   echo "${vncservers_list[@]}"
}

client_version () { 
   "${client}" -help 2>&1 | head -n 2 | awk '/./ {print $1$2"-"$3}' |head -n 1
}

clientOS () { 
   uname -a | awk '{print $2"-"$1}'
}

for arg in "$@"; do
   shift
   case "$arg" in
      *client)    set -- "$@" "-c" 
 	          ;;
      *debug)     set -- "$@" "-d" 
   	          ;;
      *help)      set -- "$@" "-h"
 	          ;;
      *keep)      set -- "$@" "-k"
 	          ;;
      *machine)   set -- "$@" "-m"
 	          ;;
      *port)      set -- "$@" "-p"
                  ;; 
      *user)      set -- "$@" "-u"
 	          ;;
      *wmw)       set -- "$@" "-w"
	          ;;
      *)          set -- "$@" "$arg"
 	          ;;
   esac
done

OPTIND=1

while getopts "c:m:n:p:u:w:dhrk" opt ; do 
   case "${opt}" in 
      d) 
         DEBUG=true
      ;;
      p) 
         port="$OPTARG"
         debug "RECEIVED REQUEST TO CONNECT TO:" "$machine at port $port" 
      ;; 
      m) 
         machine="$OPTARG"
         debug "RECEIVED REQUEST TO CONNECT TO:" "$machine" 
      ;; 
      n)
	 network="$OPTARG"
	 debug "RECEIVED REQUEST TO CONNECT TO:" "$network" 
      ;; 
      c)
	 client="$OPTARG" 
	 client=$(echo $OPTARG | sed 's/\\//g') 
	 client=${client//\~/$HOME}
	 if [[ -x "${client}" ]] ; then 
	    debug "PATH TO CLIENT IS" "$client"
         else
            debug "PATH TO CLIENT IS INVALID" "$client" 
         fi 
      ;;
      k)
	 KEEP_VNC_SERVER_ACTIVE=true
      ;;
      r) 
	 RECONNECT=true
      ;; 	    
      h) 
	 usage
	 exit 0
      ;;
      u)
         MACHUSER="${OPTARG}"
      ;;
      w)
         WINDOWMANAGER="${OPTARG}"
      ;; 
   esac	
done

if [[ "${client}"x == x ]] ; then die "A PATH TO A VNC CLIENT MUST BE SUPPLIED TO ${0/\*/}!" ; fi 
# grab some important details for logging
# vncclient version information
CLIENT_VERSION=$(client_version) 
debug "VNC CLIENT INFO:" "$CLIENT_VERSION" 

# uname output on local host
CLIENTOS=$(clientOS) 
debug "LOCALHOST OS INFO:" "$CLIENTOS"

# ensure MACHUSER is overriden by $USER if not specified
MACHUSER=${MACHUSER:=$USER}
debug "REMOTE USER:" "$MACHUSER" 

# ensure WINDOWMANAGER arg has a value
WINDOWMANAGER=${WINDOWMANAGER:=mwm}
debug "WINDOWMANAGER:" "$WINDOWMANAGER" 

if [[ "${port}x" == x ]] ; then
    # generate a random port number between 1-99
    port=0
    RANGE=99
    FLOOR=0
    while [ "$port" -le $FLOOR ] ; do
        port=$RANDOM
        let "port %= $RANGE"
    done
elif [[ "${port}x" != x ]] ; then
    debug "USER SPECIFIED PORT" "${port}"
fi

if [ ${#port} -lt 2 ] ; then
    PORT=0${port}
else 
    PORT=${port}
fi

network=$(check_network $machine) 

debug "NETWORK FOR $machine" "$network"

if [[ "$network" =~ TURQUOISE ]] ; then 
    GATEWAY=$(setup_gateway)
    GATEWAY_TUNNEL=$(setup_gateway_tunnel)
    debug "GATEWAY FOR $network" "$GATEWAY" 
    debug "GATEWAY_TUNNEL FOR $network" "GATEWAY_TUNNEL"
fi 

# grab all Xvnc pid running, parse out the ports
all_active_vncserver_ports=$(get_vnc_connections) 
active_vncserver_ports=( $(list_vncservers) )

# test connecting to remote and scraping ps output for Xvnc 
if [[ "${all_active_vncserver_ports[@]}" =~ FAILURE ]] ; then
   die "DETECTED FAILURE WITH SSH TO: $machine"
elif [[ ${#all_active_vncserver_ports[@]} -eq 0 ]] ; then
   debug "NOT FINDING OTHER VNCSERVERS RUNNING ON" "$machine"
else
   debug "ALL USERS XVNC SESSIONS ON $machine:" "${all_active_vncserver_ports[@]}" 
fi 

# test connecting to remote and scraping vncserver -list output for user specific displays
if [[ "${active_vncserver_ports[@]}" =~ FAILURE ]] ; then 
   die "FAILURE CONNECTING TO:" "$machine"
else
   debug "XVNC SESSIONS ON $machine FOR $MACHUSER" "${active_vncserver_ports[@]}"
fi 

# attempt to reconnect to the first vncserver -list display available to $USER if port isn't specified
if [[ "${RECONNECT}"x != x ]] ; then 
   if [[ "${port}"x == x ]] ; then 
      debug "RECONNECT REQUESTED WITHOUT PORT ARGUMENT"
   elif ! [[ "${active_vncserver_ports[@]}" =~ $port ]] ; then 
      die "PORT $port NOT RUNNING VNCSERVER PORT FOR" "$MACHUSER on $machine"
   else
      debug "ATTEMPTING CONNECTION TO PORT" "$port" 
   fi 
fi 

for y in ${vncserverfulllist[@]} ; do 
   debug "CHECKING DISPLAY PORT: $y"
   if [[ "$port" != $y ]] ; then 
      debug "NO CONFLICT FOUND ON DISPLAY PORT" "${port}"
      break
   else
      debug "CONFLICT FOUND ON DISPLAY PORT" "${port}" 
   fi
done 

if [[ "${port}x" == x ]] && [[ ${#active_vncserver_ports[@]} -gt 2 ]] ; then 
      warning "$MACHUSER HAS MORE THAN 2 VNCSERVER SESSIONS RUNNING!"
      warning "DO YOU WISH TO KILL THESE SESSIONS?" "[Y/N]?"
      read RESPONSE
      case $RESPONSE in
	 Y*|y*) 
	    for p in ${active_vncserver_ports[@]} ; do 
               output=$(kill_vnc $p)
	       warning "$output" 
            done
	 ;;
          N*|n*)
	    warning "YOU HAVE ${#active_vncserver_ports[@]} VNCSERVER SESSIONS RUNNING!"
	    warning "YOUR LISTENING VNC SESSIONS ARE RUNNING ON" "$(for p in ${active_vncserver_ports[@]}; do printf "%s " $p ; done)"
	    die "YOU MUST KILL SOME SESSIONS OR SPECIFY" "${0} \"-p \$port\""
	 ;; 
      esac
fi

# strip leading zeros from lower-case port
port=${port#0}

# zero pad single digit ports
if [ ${#port} -lt 2 ] ; then
    PORT=0${port}
else 
    PORT=${port}
fi

if ! [[ "${active_vncserver_ports[@]}" =~ $port ]] ; then 
   newport=$(if ! $GATEWAY ssh $MACHUSER@$machine "/usr/projects/hpcsoft/vnc2hpc/${VERSION}/bin/start_vncserver.sh \"$PORT\" \"$VERSION\" \"$WINDOWMANAGER\" \"$CLIENT_VERSION\" \"$CLIENTOS\"" ; then echo "FAIL" ; fi )
   if [[ "${newport}" =~ FAIL ]] ; then 
      die "STARTUP SCRIPT FOR VNCSERVER" "FAILED!" 
   elif [[ "${newport}" != "${port}" ]] ; then 
      note "VNCSERVER REQUEST TO START ON:"  "${PORT} FAILED"
      note "VNCSERVER WAS STARTED ON:" "${newport}" 
      # reassign port here to the actual port vncserver established
      port="${newport}"
      # strip leading zeros from lower-case port
      port=${port#0}
      # zero pad single digit ports
      if [ ${#port} -lt 2 ] ; then
         PORT=0${port}
      else
         PORT=${port}
      fi
      debug "PORT NUMBER ADJUSTED FOR ZERO PADDING" "$PORT"
      debug "PORT NUMBER ADJUSTED TO REMOVE ZEROS" "$port"
   fi 
   sleep 2.5
else
   debug "VNCSERVER RUNNING AS $USER ALREADY" "WILL USE THIS PORT $port"
fi
   
# establish a ssh local tunnel to $machine 
debug "STARTING PORT FORWARDING" "`hostname -s` TO $machine" "ON PORT 59$PORT"

#port forwarding connection using zero padded port number
$GATEWAY_TUNNEL ssh -fN -L 59$PORT:localhost:59$PORT $machine &>/dev/null &

#test that the Xvnc process on $port was instantiated
pid=$($GATEWAY ssh $MACHUSER@$machine ps aux | grep -e "Xvnc :$port" -e "Xvnc :$PORT" | awk '{print $2}')

#fail if not
if [[ "${pid}x" == x ]] ; then warning "ERROR OCCURRED STARTING VNCSERVER."; fi 

#connect client to localhost
"$client" localhost:59$PORT 

#test client connection return code
if [[ $? -ne 0 ]] ; then
   die "FAILURE CONNECTING" "$client TO $PORT" 
fi 

#if -k is passed to the script, don't kill the process 
if [[ "${KEEP_VNC_SERVER_ACTIVE}"x != x ]]; then 
   debug "KEEPING VNC SERVER RUNNING ON" "$machine AT PORT $port Active"
else
   debug "KILLING VNC SERVER RUNNING ON" "$machine AT PORT $port"
   debug "PORT is"  "$PORT"
   debug "pORT is"  "$port"
   if ! kill_output=$(kill_vnc $PORT) ; then kill_output=$(kill_vnc $port) ; fi 
   debug "OUTPUT FROM $machine vncserver -kill"  "${kill_output}"
fi 
exit 

