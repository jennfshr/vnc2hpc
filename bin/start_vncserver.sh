#!/bin/sh

displayport=$1
/usr/bin/vncserver :${displayport} -name "$USER at `hostname -s`:$displayport OPENBOX Session" -autokill -depth 16 -xstartup /usr/projects/hpcsoft/common/openbox/3.6.1/etc/xdg/openbox/xstartup &>/dev/null &
pid=$!
echo $pid
