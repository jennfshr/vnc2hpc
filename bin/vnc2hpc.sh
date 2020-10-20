#!/bin/bash
VERSION="0.0.2"
mydate=$(date +%m-%d-%y"-"%H.%m.%S)
# this script automates the creation of a ssh local tunnel connection to a LANL front-end
# it waits for the vncserver to return success - potentially catching and handling conflicts
# then it runs a vncviewer command that connects to the server via the tunnel to establish a window connection to the cluster

usage () {
    message -m "${0//*\//} v${VERSION}
          usage: ${0//*\//} [-m|--machine <machine>] (required)
                            [-c|--client <vncclient>] (required)
                            [-d|--debug] (optional)
	                    [-p|--port <display port>] (optional)
			    [-u|--user <hpcuserid> (required: if \$USER is different on remote host)
			    [-k|--keep] (optional)
			    [-r|--reconnect] (optional)
			    [-w|--wm <fvwm|mwm|xfwm4|openbox-session>] (optional)
			    [-h|--help]
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
    echo "ssh -o LogLevel=QUIET -fN -tt -L 59${PORT}:localhost:59${PORT} ${MACHUSER}@wtrw1.lanl.gov ssh -tt"
}

# This is unused, but worth investigating
setup_nogateway_tunnel () {
    echo "ssh -o LogLevel=QUIET -M -S ${tunnel_socket} -fNT -L $PORT:localhost:$PORT $MACHUSER@$machine"
}

# reusable string to setup ssh command via wtrw
setup_gateway_ssh () {
    echo "ssh -o LogLevel=QUIET -tt ${MACHUSER}@wtrw1.lanl.gov ssh"
}

# This is unused, but worth investigating
setup_nogateway_ssh () {
    echo "ssh -o LogLevel=QUIET -fN -tt ${MACHUSER}@${machine}"
}

# Colorize output
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

# Warn if something's amiss
warning () {
    message -y "NOTE" "$1" "$2" "$3"
}

# clean up tunnel before terminating shell, emit useful diagnostic info
die () {
    if kill -0 ${tunnel_pid} &>/dev/null ; then
        kill ${tunnel_pid} &>/dev/null
    fi
    message -r "ERROR" "$1" "$2" "$3"
    exit 2
}

# Informative messages to user
inform () {
    message -g "INFO" "$1" "$2" "$3"
}

# only used for extended debug output with -d or --debug
debug () {
    if [[ ${DEBUG}x != x ]] ; then
        message -g "DEBUG" "$1" "$2" "$3"
    fi
}

checkvncpasswd () {
    if ! $( ${GATEWAY_SSH} ${NO_GATEWAY_SSH} $MACHUSER@$machine "ls \$HOME/.vnc/passwd" &>/dev/null ); then 

        if echo ${SHELLOPTS} | grep xtrace &>/dev/null ; then
            warning "${0//*\//} detects xtrace set in your shell." "Potential clear casing of your vncpasswd could occur!"
            warning "Do you wish to proceed and assume the risk to revealing your password? [Y/N]"
            read CLEARCASE
            case $CLEARCASE in
                Y*|y*)
                    continue
                ;; 
                N*|n*)
                    warning "Unsetting the xtrace shellopt on your behalf!" 
                    set +x
                ;;
                *)
                    die "Didn't receive a Y or N response." "Exitting ${0//*\//}"
                ;;
            esac
        fi 
        inform "VNC passwd not available on $machine for $MACHUSER"
        inform "Do you want to setup a password now? [Y/N]"
        read PWREPLY

        case $PWREPLY in
            Y*|y*)
                inform "Enter your password (at least six characters long, up to eight)"
                read -s VNCPW
                inform "Reenter your password to confirm" 
                read -s REVNCPW
                if [[ "${VNCPW}" == "${REVNCPW}" ]] ; then 
                    inform "SETTING VNCPASSWD" "$machine for $MACHUSER"
                    ${GATEWAY_SSH} ${NO_GATEWAY_SSH} $MACHUSER@$machine "echo ${VNCPW} | /usr/bin/vncpasswd -f > \$HOME/.vnc/passwd && chmod 0600 \$HOME/.vnc/passwd"
                    if [[ $? -ne 0 ]] ; then 
                        die "SOMETHING WENT WRONG SETTING YOUR VNCPASSWD"
                    elif ! $( ${GATEWAY_SSH} ${NO_GATEWAY_SSH} $MACHUSER@$machine "ls \$HOME/.vnc/passwd" &>/dev/null ); then
                        die "SOMETHING WENT WRONG SETTING YOUR VNCPASSWD"
                    else 
                        inform "VNCPASSWD SET!"
                    fi 
                else 
                    die "FIRST AND SECOND PASSWORDS DIDN'T MATCH" 
                fi
                perms=$(${GATEWAY_SSH} ${NO_GATEWAY_SSH} $MACHUSER@$machine ""ls -al \$HOME/.vnc/passwd"")
                debug "CHECKING PERMS ON PASSWD FILE:" "$perms"
            ;;
            N*|n*)
                die "YOU MUST LOGIN TO $machine AND SETUP A VNC PASSWORD TO PROCEED" 
            ;;
            *)
                die "A password to use your vncserver on $machine is required!" 
            ;;
        esac
    fi 
}

# command to kill the vncserver
kill_vnc () {
    LOCAL_PORT=$1
    kill_vnc_response=$(${GATEWAY_SSH} ${NO_GATEWAY_SSH} $MACHUSER@$machine vncserver -kill :${LOCAL_PORT} 2>&1)
    # strange characters in stdout via wtrw filtered in the substitution below
    echo "${kill_vnc_response%$'\r'}"
}

# command to get all users Xvnc instances on remote
get_vnc_connections () {
    for pt in $(if ! ${GATEWAY_SSH} ${NO_GATEWAY_SSH} $MACHUSER@$machine "ps ax| grep -E \"/usr/bin/Xvnc :([0-9]+)\" | awk '{ gsub(\":\",\"\",\$6) } {print \$6}'" 2>/dev/null ; then die "FAILURE CONNECTING TO:" "$machine" ; fi); do
       LOCAL_VNC_CONS=( $(printf "%s " "${pt%$'\r'}") "${LOCAL_VNC_CONS[@]}" )
    done
    echo "${LOCAL_VNC_CONS[@]}"
}

# command to get Users Vncserver list
list_vncservers () {
    vncservers_list=( $(if ! ${GATEWAY_SSH} ${NO_GATEWAY_SSH} $MACHUSER@$machine "vncserver -list|egrep -v 'DISPLAY|TigerVNC|^$'"| awk '{gsub(/\:/,"",$1); print $1}'; then die "FAILURE CONNECTING TO" "$machine" ; fi) )
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

remotelog () {
    ${GATEWAY_SSH} ${NO_GATEWAY_SSH} $MACHUSER@$machine "cat ~/.vnc/${machine}*:*$PORT.log" >> ${PWD}/log/${machine}/${SERVER_LOG_FILE}
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
        *reconnect) set -- "$@" "-r"
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

# need to have a viable vncclient to use on the local machine
if [[ "${client}"x == x ]] ; then usage; die "A PATH TO A VNC CLIENT MUST BE SUPPLIED TO ${0/\*/}!" ; fi

# ensure $machine is set
if [[ "${machine}"x == x ]] ; then usage; die "MACHINE must be specified to ${0/\*/}!" ; fi

# vncclient version information
CLIENT_VERSION=$(client_version)
inform "VNC CLIENT INFO:" "$CLIENT_VERSION"

# uname output on local host
CLIENTOS=$(clientOS)
inform "LOCALHOST OS INFO:" "$CLIENTOS"

# ensure MACHUSER is overriden by $USER if not specified
MACHUSER=${MACHUSER:=$USER}
inform "REMOTE USER:" "$MACHUSER"

# ensure WINDOWMANAGER arg has a value
WINDOWMANAGER=${WINDOWMANAGER:=mwm}
inform "WINDOWMANAGER:" "$WINDOWMANAGER"

# ensure we know what network requirements there are to connect to machine
network=$(check_network $machine)

# setup the appropriate ssh commands for the network
if [[ "$network" =~ TURQUOISE ]] ; then
    GATEWAY_SSH=$(setup_gateway_ssh)
    debug "GATEWAY FOR $network:" "${GATEWAY_SSH}"
else
    NO_GATEWAY_SSH="ssh -o LogLevel=QUIET"
    debug "GATEWAY FOR $network:" "${NO_GATEWAY_SSH}"
fi

inform "NETWORK FOR $machine:" "$network"

# some client side logs, the second one is only in the event of a failure
CLIENT_LOG_FILE="vncclient.log.$mydate"
inform "VNC CLIENT ${client//*\//} LOGGING" "${PWD}/log/${machine}/${CLIENT_LOG_FILE}"
mkdir -p ${PWD}/log/${machine}

# TODO: some fixing to do with getting this in the event of a failure
SERVER_LOG_FILE="vncserver.log.$mydate"
inform "VNC SERVER LOGGING" "${PWD}/log/${machine}/${SERVER_LOG_FILE}"

# check vncpasswd
checkvncpasswd

# grab all Xvnc pid running, parse out the ports
all_active_vncserver_ports=( $(get_vnc_connections) )
inform "ALL USERS VNCSERVER PORTS ON $machine:" "$(echo ${all_active_vncserver_ports[@]})"

# grab user specific vncserver from vncserver -list command on remote
active_vncserver_ports=( $(list_vncservers) )
inform "$MACHUSER ACTIVE VNCSERVER PORTS ON $machine:" "$(echo ${active_vncserver_ports[@]})"

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
        inform "RECONNECT REQUESTED WITHOUT PORT ARGUMENT"
	port=${active_vncserver_ports}
	inform "ATTEMPTING TO RECONNECT TO PORT ${port}"
    elif ! [[ "${active_vncserver_ports[@]}" =~ $port ]] ; then
        die "PORT $port NOT RUNNING VNCSERVER PORT FOR" "$MACHUSER on $machine"
    else
        inform "ATTEMPTING CONNECTION TO REQUESTED PORT" "localhost:59$port"
    fi
fi

# ensure that we limit ports to one per user per host, if there are more than one vncservers running for $MACHUSER, force a kill, exit, or reuse of that server
# KEEPING FOR NOW... if [[ "${port}"x == x ]] && [[ ${#active_vncserver_ports[@]} -ge 1 ]] ; then
if [[ "${#active_vncserver_ports[@]}" -ge 1 ]] && [[ $RECONNECT != "true" ]] ; then
    warning "ACTIVE VNCSERVER PORTS FOR $MACHUSER ON $machine" "${active_vncserver_ports[@]}"
    warning "DO YOU WISH TO KILL OR REUSE THIS SESSION?" "Y - yes (kill it), N - exit (keep it, exit), R - reuse]?"
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

# generate a random port number between 5901 5999
if [[ "${port}"x == x ]] ; then
    port=0
    FLOOR=2
    RANGE=99
    while [ "$port" -le $FLOOR ] || [ "$port" -gt $RANGE ] ; do
        port=$RANDOM
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

# if the port requested isn't already actively listening for USER, call startvncserver script remotely
if ! [[ "${active_vncserver_ports[@]}" =~ $port ]] ; then
    newport=$(${GATEWAY_SSH} ${NO_GATEWAY_SSH} $MACHUSER@$machine "/usr/projects/hpcsoft/vnc2hpc/${VERSION}/bin/start_vncserver.sh \"${VERSION}\" \"${WINDOWMANAGER}\" \"${CLIENT_VERSION}\" \"${CLIENTOS}\" \"${PORT}\"")
    # turquoise network connection requires parsing weird carriage return characters
    newport=${newport%$'\r'}
    if [[ "${newport}" =~ FAIL ]] ; then
        remotelog
        die "STARTUP SCRIPT FOR VNCSERVER" "FAILED!"
    else
        # reassign port here to the actual port vncserver established
        port="${newport}"
        # strip leading zeros from lower-case port
        port=${port#0}
        # zero pad single digit ports this still is needed in case a vncserver autoselects low port number
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
    debug "VNCSERVER RUNNING AS $USER ALREADY on $port" "WILL USE THIS PORT $port"
fi

#TODO:# setup socket name
#tunnel_socket="VNC2HPC-${mydate}-${machine}"

#need the tunnel to include the port as determined above
if [[ "${network}" =~ TURQUOISE ]] ; then
    GATEWAY_TUNNEL=$(setup_gateway_tunnel)
    debug "GATEWAY_TUNNEL FOR $network:" "$GATEWAY_TUNNEL"
#else
#    NO_GATEWAY_TUNNEL=$(setup_nogateway_tunnel)
#    debug "NO_GATEWAY_TUNNEL FOR $network:" "$NO_GATEWAY_TUNNEL"
fi

#port forwarding connection using zero padded port number
if [[ ${GATEWAY_TUNNEL}x != x ]] ; then
    debug "RUNNING:" "${GATEWAY_TUNNEL} -L 59${PORT}:localhost:59${PORT} $machine &"
    ${GATEWAY_TUNNEL} -L 59${PORT}:localhost:59${PORT} ${machine} &>/dev/null &
else
    debug "RUNNING:" "${NO_GATEWAY_SSH} -fN -L 59${PORT}:localhost:59${PORT} ${MACHUSER}@${machine} &"
    ${NO_GATEWAY_SSH} -fN -L 59${PORT}:localhost:59${PORT} ${MACHUSER}@${machine} &>/dev/null &
fi
tunnel_pid=$!

# establish a ssh local tunnel to $machine
debug "STARTING PORT FORWARDING" "`hostname -s` TO $machine ON PORT 59${PORT}"
debug "TUNNEL PID IS:" "${tunnel_pid}"

#test that the Xvnc process on $port was instantiated
#Make this better!
remote_pid=$(${GATEWAY_SSH} ${NO_GATEWAY_SSH} $MACHUSER@$machine "ps aux | grep -e \"/usr/bin/Xvnc :$port \" -e \"/usr/bin/Xvnc :$PORT \"" 2>/dev/null |grep -v grep | grep -v bash | awk '{print $2}')
debug "XVNC PID IS:" "${remote_pid}"

#fail if not
if [[ "${remote_pid}x" == x ]] ; then 
    remotelog
    die "ERROR OCCURRED STARTING VNCSERVER."
fi

#connect client to localhost
"$client" localhost:59${PORT} -EnableUdpRfb=false -WarnUnencrypted=0 -LogDir=${PWD}/log/${machine} -LogFile=${CLIENT_LOG_FILE}

#test client connection return code
if [[ $? -ne 0 ]] ; then
    remotelog
    die "FAILURE CONNECTING:" "$client TO $PORT"
fi

#if -k is passed to the script, don't kill the process
if [[ "${KEEP_VNC_SERVER_ACTIVE}"x != x ]]; then
    inform "KEEPING VNC SERVER RUNNING ON:" "$machine AT PORT $port Active"
else
    inform "KILLING VNC SERVER RUNNING ON:" "$machine AT PORT $port"
    kill_vnc_output=$(kill_vnc $port)
    debug "OUTPUT FROM KILL VNC:" "${kill_vnc_output[@]}"
fi

#killing the tunnel to $machine
if kill -0 ${tunnel_pid} &>/dev/null ; then
    kill ${tunnel_pid} &>/dev/null
fi
exit
