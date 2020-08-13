# vnc2hpc

## Quickstart
The usage output is available by running 

`./vnc2hpc.sh --help`

```    vnc2hpc.sh v0.0.2
        usage: vnc2hpc.sh 
                    [-d|--debug] 
    	            [-p|--port <display port>]
    	            [-m|--machine <machine>] 
    	            [-u|--user <hpcuserid> 
                    [-c|--client <vncclient>] 
                    [-k|--keep] 
                    [-r|--reconnect] 
                    [-h|--help] 
                    [-w|--wm <mwm|xfwm4|openbox-session|fvwm>]
```
### Usage Examples - Connecting to Snow

#### Initial Setup on the Remote

It's necessary to create a password that the client will use to connect to the vncserver upon connection before
using the vnc2hpc.sh script.  Eventually, automation of this step is ideal. 

Once this is setup on the "network" for the remote-host (i.e., Yellow, Turquoise, Red), it's sharable among all
remote hosts on that network. 

```bash
ssh -l ${USER} <machine> 
$> vncpasswd 
>  Password:
>  Verify:
>  Would you like to enter a view-only password (y/n)? n
>  A view-only password is not used
$> exit
```

For instance, to launch a session to Snow’s sn-fey1:

`$> ./vnc2hpc.sh -c "/Applications/VNC\ Viewer.app/Contents/MacOS/vncviewer" -m sn-fey1`

Or to connect to a turquoise hosted system:

`$> ./vnc2hpc.sh -c “/Applications/VNC\ Viewer.app/Contents/MacOS/vncviewer” -m sn-fe1`

### Features

#### --client | -c 

The client flag is how you direct vnc2hpc.sh to the vncviewer on your desktop to use to connect to the vncserver. 
It's a required option that will fail if not supplied.  A full path to the vncviewer executable is required if the executable
isn't in your $PATH.  To determine if the executable is in your path, in a terminal window, run `which vncviewer`.

`$> ./vnc2hpc.sh -c “/Applications/VNC\ Viewer.app/Contents/MacOS/vncviewer” -m sn-fe1`

#### --debug | -d 

To have more visibility into the script's progression, you can run with --debug or -d

#### --machine | -m 

This flag specifies the front-end node's short hostname you wish to connect to.  If you want to connect
to a system on the turquoise network, just pass the front-end short hostname to the script and it will detect
the network, and setup the gateway hop appropriately.

#### --keep | -k

To preserve your vncserver session for later reuse, run the script with --keep or -k

`$> ./vnc2hpc.sh -c "/Applications/VNC\ Viewer.app/Contents/MacOS/vncviewer" -m sn-fey1 --keep`

To reconnect to this, you can request a reconnect with later invocations with a --reconnect or -r flag

`$> ./vnc2hpc.sh -c "/Applications/VNC\ Viewer.app/Contents/MacOS/vncviewer" -m sn-fey1 --reconnect`
                    
The --reconnect flag sets a sentinel to "keep" the reconnected session upon closing the viewer

#### --port | -p 

One can request a specific port, and that port will be attempted to be connected to upon starting the vncserver

`$> ./vnc2hpc.sh -c "/Applications/VNC\ Viewer.app/Contents/MacOS/vncviewer" -m sn-fey1 --port 15`

There is a limit of one vncserver service running per user per remote host, and the script will enforce this. 
The script will prompt for an action on the command line if a port is already running for the user.

`$ ./vnc2hpc.sh -m cp-loginy -c /Applications/VNC\ Viewer.app/Contents/MacOS/vncviewer -w fvwm`
`WARN       jgreen HAS ONE OR MORE VNCSERVER SESSIONS RUNNING!`
`WARN       ACTIVE VNCSERVER PORTS FOR jgreen ON cp-loginy     47`                                         
`WARN       DO YOU WISH TO KILL OR REUSE THIS SESSION?         Y - yes, N - exit, R - reuse]?`

Note: the script is set to utilize the 5900 port range so the port supplied to the script should be limited to two characters

If that port returns a conflict when the vncserver script is invoked, the vnc2hpc.sh script will utilize the newport. 

Port is optional, as the script will randomly generate a port number between 1 and 99 to offer less likelihood that you
don't have localhost:port tunnel conflicts on the client side. 

#### --user | -u 

Sometimes the userid of the user running on the desktop system where vnc2hpc.sh is invoked doesn't match the corresponding
userid for the remote system.  If you have different userids, you need to pass the remote userid (a.k.a. moniker) to the script

`$> ./vnc2hpc.sh -c "/Applications/VNC\ Viewer.app/Contents/MacOS/vncviewer" -m sn-fey1 -u jgreen`

### Issues resolved for v0.0.2 tag

- [ ] #2 xstartup script needs to be replicated to HOME before invoked
- [ ] #1 initial passwd creation isn't implemented yet- start vncserver manually on the target machine, set a password, then use it to authenticate the connection when prompted.
- [ ] #5 ssh -fN is suppressing remote commands
- [ ] #3 xstartup script should use environment variable to set the window manager, rather than positional parameters
- [ ] #4 feature request for fvwm support (os/arch specific builds- fix xstartup to find the right version)


## Client Compatibility Table
| Version | OS | Viewer | Window Managers
| ------ | ------ | ------ | ------ |
| v0.0.2 | MacOSX v10.14.6 | VNC(R)Viewer-6.20.529 | fvwm, mwm, openbox-session, xfwm4 |
| v0.0.2 | MacOSX v10.14.6 | TigerVNC Viewer 32-bit v1.4.3 | fvwm, mwm, openbox-session, xfwm4 |
| v0.0.2 | MacOSX v10.14.6 | TigerVNC Viewer 64-bit v1.10.1 | fvwm, mwm, openbox-session, xfwm4 |
| v0.0.2 | Linux | UNTESTED | UNTESTED |
| v0.0.2 | Windows | UNTESTED | UNTESTED |

## What is VNC

Virtual Network Computing (VNC) is a graphical desktop-sharing system that uses the Remote Frame Buffer protocol (RFB) to remotely control another computer. It transmits the keyboard and mouse events from one computer to another, relaying the graphical-screen updates back in the other direction, over a network.

## In depth Explanation

