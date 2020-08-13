#!/bin/bash
VERSION="0.0.2"
# this script automates the creation of a ssh local tunnel connection to a LANL front-end 
# it waits for the vncserver to return success - potentially catching and handling conflicts?
# then it runs a vncviewer command that connects to the server via the tunnel to establish a window connection to the cluster

usage () { 
    message -m "${0//*\//} v${VERSION}
          usage: ${0//*\//} [-d|--debug] 
	                    [-p|--port <display port>] 
			    [-m|--machine <machine>] 
			    [-u|--user <hpcuserid> 
	                    [-c|--client <vncclient>] 
			    [-k|--keep] 
			    [-r|--reconnect] 
			    [-h|--help] 
			    [-w|--wm <fvwm|mwm|xfwm4|openbox-session>]
               "
}

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
    echo "ssh -o LogLevel=QUIET -fN -tt -L 59$PORT:localhost:59$PORT $MACHUSER@wtrw1.lanl.gov ssh -tt"
}

setup_gateway () {
    echo "ssh -o LogLevel=QUIET -tt $MACHUSER@wtrw1.lanl.gov ssh"
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
    printf "${color}%-10s %-50s %-50s\n" "$1" "$2" "$3"
    tput sgr0
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

kill_vnc () { 
    LOCAL_PORT=$1
    kill_vnc_response=$(${GATEWAY_SSH} ${NO_GATEWAY_SSH} $MACHUSER@$machine vncserver -kill :${LOCAL_PORT} 2>&1)
    echo "${kill_vnc_response%$'\r'}" 
}

get_vnc_connections () { 
    declare -a LOCAL_VNC_CONS
    for pt in $(if ! ${GATEWAY_SSH} ${NO_GATEWAY_SSH} $MACHUSER@$machine "ps ax| grep -E \"/usr/bin/Xvnc :([0-9]+)\" | awk '{ gsub(\":\",\"\",\$6) } {print \$6}'" 2>/dev/null ; then die "FAILURE CONNECTING TO:" "$machine" ; fi); do
       LOCAL_VNC_CONS=( $(printf "%s " "${pt%$'\r'}") "${LOCAL_VNC_CONS[@]}" )
    done
    echo "${LOCAL_VNC_CONS[@]}"
} 

list_vncservers () { 
    vncservers_list=( $(if ! ${GATEWAY_SSH} ${NO_GATEWAY_SSH} $MACHUSER@$machine "vncserver -list|grep -v DISPLAY |grep -v TigerVNC"| awk '{print $1}' |sed 's/://g'; then die "FAILURE CONNECTING TO" "$machine" ; fi) )
    for item in ${vncservers_list[@]} ; do 
        VNCSERVERS_LIST=( $(printf "%s " "${item%$'\r'}") "${VNCSERVERS_LIST[@]}" )
    done
    echo "${VNCSERVERS_LIST[@]}" 
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
            KEEP_VNC_SERVER_ACTIVE=true
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

# ensure we know what network requirements there are to connect to machine
network=$(check_network $machine) 

if [[ "$network" =~ TURQUOISE ]] ; then 
    GATEWAY_SSH=$(setup_gateway)
    debug "GATEWAY FOR $network:" "${GATEWAY_SSH}" 
else
    NO_GATEWAY_SSH="ssh -o LogLevel=QUIET"
    debug "GATEWAY FOR $network:" "${NO_GATEWAY_SSH}" 
fi 
debug "NETWORK FOR $machine:" "$network"

# some client side logs, the second one is only in the event of a failure
CLIENT_LOG=${PWD}
SERVER_LOG=${PWD}/vncserver.log.$(date +%d-%m-%y"-"%H.%m.%S) 

# grab all Xvnc pid running, parse out the ports
all_active_vncserver_ports=( $(get_vnc_connections) )
debug "ALL ACTIVE VNCSERVER PORTS:" "$(echo ${all_active_vncserver_ports[@]})" 
active_vncserver_ports=( $(list_vncservers) )
debug "$MACHUSER ACTIVE VNCSERVER PORTS:" "$(echo ${active_vncserver_ports[@]})"

# test connecting to remote and scraping ps output for Xvnc 
if [[ "${all_active_vncserver_ports[@]}" =~ FAILURE ]] ; then
    die "DETECTED FAILURE WITH SSH TO: $machine"
elif [[ ${#all_active_vncserver_ports[@]} -eq 0 ]] ; then
    debug "NOT FINDING OTHER VNCSERVERS RUNNING ON" "$machine"
else
    debug "ALL USERS XVNC SESSIONS ON $machine:" "$(echo ${all_active_vncserver_ports[@]})" 
fi 

# test connecting to remote and scraping vncserver -list output for user specific displays
if [[ "${active_vncserver_ports[@]}" =~ FAILURE ]] ; then 
    die "FAILURE CONNECTING TO:" "$machine"
else
    debug "XVNC SESSIONS ON $machine FOR $MACHUSER" "$(echo ${active_vncserver_ports[@]})"
fi 

# attempt to reconnect to the first vncserver -list display available to $USER if port isn't specified
if [[ "${RECONNECT}"x != x ]] ; then 
    if [[ "${port}"x == x ]] ; then 
        debug "RECONNECT REQUESTED WITHOUT PORT ARGUMENT"
	debug "WILL REUSE PORT ${active_vncserver_ports}" 
	port=${active_vncserver_ports}
    elif ! [[ "${active_vncserver_ports[@]}" =~ $port ]] ; then 
        die "PORT $port NOT RUNNING VNCSERVER PORT FOR" "$MACHUSER on $machine"
    else
        debug "ATTEMPTING CONNECTION TO PORT" "$port" 
    fi 
fi 

# ensure that we don't have exploits on this service, if there are more than one vncservers running for $MACHUSER, force a kill, exit, or reuse of that server
if [[ "${port}"x == x ]] && [[ ${#active_vncserver_ports[@]} -ge 1 ]] ; then 
    warning "$MACHUSER HAS ONE OR MORE VNCSERVER SESSIONS RUNNING!"
    warning "ACTIVE VNCSERVER PORTS FOR $MACHUSER ON $machine" "${active_vncserver_ports}" 
    warning "DO YOU WISH TO KILL OR REUSE THIS SESSION?" "Y - yes, N - exit, R - reuse]?"
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
        R*|r*)
	    debug "WILL REUSE PORT ${active_vncserver_ports}"
            debug "WILL ALSO KEEP PORT ACTIVE UPON DISCONNECT"
	    KEEP_VNC_SERVER_ACTIVE=true
            port=${active_vncserver_ports}
	;; 
    esac
fi

# generate a random port number between 1-99 that will be padded with 59 later
if [[ "${port}"x == x ]] ; then
    port=0
    RANGE=99
    FLOOR=0
    while [ "$port" -le $FLOOR ] ; do
        port=$RANDOM
        let "port %= $RANGE"
        done
fi

# manage some details on the port formats
if [[ ${#port} -lt 2 ]] && [[ -n ${port} ]]; then
    PORT=0${port}
else 
    PORT=${port}
fi
# strip leading zeros from lower-case port
port=${port#0}


if ! [[ "${active_vncserver_ports[@]}" =~ $port ]] ; then 
    newport=$(${GATEWAY_SSH} ${NO_GATEWAY_SSH} $MACHUSER@$machine "/usr/projects/hpcsoft/vnc2hpc/${VERSION}/bin/start_vncserver.sh \"${VERSION}\" \"${WINDOWMANAGER}\" \"${CLIENT_VERSION}\" \"${CLIENTOS}\" \"${PORT}\"")
    # turquoise network connection requires parsing weird carriage return characters
    newport=${newport%$'\r'}
    if [[ "${newport}" =~ FAIL ]] ; then 
        die "STARTUP SCRIPT FOR VNCSERVER" "FAILED!" 
    else
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
else
    debug "VNCSERVER RUNNING AS $USER ALREADY on $port" "WILL USE THIS PORT $port"
fi
   
#need the tunnel to include the port as determined above
if [[ "${network}" =~ TURQUOISE ]] ; then 
    GATEWAY_TUNNEL=$(setup_gateway_tunnel)
    debug "GATEWAY_TUNNEL FOR $network:" "$GATEWAY_TUNNEL"
fi 

#port forwarding connection using zero padded port number
if [[ ${GATEWAY_TUNNEL}x != x ]] ; then
    ${GATEWAY_TUNNEL} -L 59$PORT:localhost:59$PORT $machine &>/dev/null & 
    tunnel_pid=$!
else
    ${NO_GATEWAY_SSH} -N -L 59$PORT:localhost:59$PORT $machine &>/dev/null &
    tunnel_pid=$!
fi 

# establish a ssh local tunnel to $machine 
debug "STARTING PORT FORWARDING `hostname -s` TO $machine ON PORT 59$PORT"
debug "TUNNEL PID IS:" "${tunnel_pid}"
if [[ -n ${tunnel_pid} ]] ; then 
    #hate this but it seems needed
    sleep 15
else 
    die "TUNNEL CONNECTION FAILED!" 
fi 

#test that the Xvnc process on $port was instantiated
remote_pid=$(${GATEWAY_SSH} ${NO_GATEWAY_SSH} $MACHUSER@$machine "ps aux | grep -e \"/usr/bin/Xvnc :$port \" -e \"/usr/bin/Xvnc :$PORT \"" 2>/dev/null |grep -v grep | grep -v bash | awk '{print $2}')
debug "XVNC PID IS:" "${remote_pid}"

#fail if not
if [[ "${remote_pid}x" == x ]] ; then die "ERROR OCCURRED STARTING VNCSERVER."; fi 

#hate this but it seems needed
sleep 15

#connect client to localhost
"$client" -EnableUdpRfb=false -WarnUnencrypted=0 -LogDir=${CLIENT_LOG} localhost:59$PORT 

#test client connection return code
if [[ $? -ne 0 ]] ; then
    ${GATEWAY_SSH} ${NO_GATEWAY_SSH} $MACHUSER@$machine "cat ~/.vnc/${machine}*:$port.log" >> $SERVER_LOG 
    die "FAILURE CONNECTING:" "$client TO $PORT" 
fi 

#if -k is passed to the script, don't kill the process 
if [[ "${KEEP_VNC_SERVER_ACTIVE}"x != x ]]; then 
    debug "KEEPING VNC SERVER RUNNING ON:" "$machine AT PORT $port Active"
else
    debug "KILLING VNC SERVER RUNNING ON:" "$machine AT PORT $port"
    kill_vnc_output=$(kill_vnc $port)
    debug "OUTPUT FROM KILL VNC:" "${kill_vnc_output[@]}" 
fi 

#killing the tunnel to $machine
if kill -0 ${tunnel_pid} &>/dev/null ; then 
    kill ${tunnel_pid} &>/dev/null
fi
exit 

