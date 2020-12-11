#!/bin/sh

echo "$1" | vncpasswd -f > $HOME/.vnc/passwd && chmod 0600 $HOME/.vnc/passwd

