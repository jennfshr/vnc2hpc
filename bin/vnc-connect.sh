#!/bin/bash

# this script automates the creation of a ssh local tunnel connection to a LANL front-end 
# it autogenerates a port number to avoid conflicts with others running on vnc ports
# it waits for the vncserver to return success - potentially catching and handling conflicts?
# then it runs a vncviewer command that connects to the server via the tunnel to establish a window connection to the cluster

message () {
    # Like echo, but with options for color.
    local color
    local OPTIND
    local opt

    while getopts "rgybmc" opt; do
        case $opt in
            r)
                color=31;;
            g)
                color=32;;
            y)
                color=33;;
            b)
                color=34;;
            m)
                color=35;;
            c)
                color=36;;
            *)
                color=37;;
        esac
    done

    shift $(($OPTIND - 1))
    echo -e "\e[${color}m$@\e[0m"
}

note () {
    message -g "$@"
}

die () {
    message -r "$@"
    exit 2
}
unset KEEP_VNC_SERVER_ACTIVE
while getopts "p:m:n:c:kr" opt ; do 
    case "${opt}" in 
	p ) 
            port="$OPTARG"
	    message "REQUEST TO CONNECT TO $machine at port $port RECEIVED" 
	;; 
	m ) 
            machine="$OPTARG"
	    message "REQUEST TO CONNECT TO $machine RECEIVED" 
	;; 
        n )
	    network="$OPTARG"
	    message "REQUEST TO CONNECT TO $network RECEIVED" 
	;; 
        c )
	    client="$OPTARG" 
	    client=$(echo $OPTARG | sed 's/\\//g') 
	    client=${client//\~/$HOME}
	    if [[ -x "${client}" ]] ; then 
	        message "PATH TO CLIENT IS $client"
            else
                message "PATH TO CLIENT IS INVALID: $client" 
            fi 
	;;
        k )
	    KEEP_VNC_SERVER_ACTIVE=true
        ;;
        r ) 
	    RECONNECT=true
        ;; 	    
    esac	
done

# generate a random port number between 1-99
if ! [[ -n $port ]] ; then
    port=0
    RANGE=99
    FLOOR=0
    while [ "$port" -le $FLOOR ] ; do 
        port=$RANDOM
        let "port %= $RANGE"
    done
fi 

# attempt to reconnect to the first vncserver -list display available to $USER if port isn't specified
if $RECONNECT && ! [ -n $port ] ; then 
    vncserverfulllist=( $(ssh $USER@$machine vncserver -list|grep -v DISPLAY |grep -v TigerVNC) )
    vncserverlist=${vncserverfulllist//:/} 
    port=${vncserverlist}
    message "RECONNECTING TO FOUND PORT $port on $machine" 
fi 

if [ ${#port} -lt 2 ] ; then
    port=0${port}
fi
message "PORT: $port"
# establish a ssh local tunnel to $machine 
ssh -fN -L 59$port:localhost:59$port $machine

# test the return value of the tunnel ssh command
if [ $? -eq 0 ] ; then	
    sleep 2.5
    ssh $USER@$machine /usr/projects/hpcsoft/vnc-connect/bin/start_vncserver.sh $port
    sleep 2.5
    pid=$(ssh $USER@$machine ps aux|grep "Xvnc :$port" | awk '{print $2}')
    if ! [ -n $pid ] ; then die "ERROR OCCURRED STARTING VNCSERVER."; fi 
    "$client" localhost:59$port 
    set -x 
    if [[ "${KEEP_VNC_SERVER_ACTIVE}"x != x ]]; then 
	message "KEEPING VNC SERVER RUNNING ON $machine AT PORT $port Active"
    else
	message "KILLING VNC SERVER RUNNING ON $machine AT PORT $port"
        ssh $USER@$machine vncserver -kill :$port
    fi 
else
    die "TUNNEL COMMAND FAILED" 
fi
exit 




