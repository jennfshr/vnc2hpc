# vnc2hpc

## Quickstart
The usage output is available by running

`./vnc2hpc --help`

```vnc2hpc v0.0.2

          usage: vnc2hpc [-m|--machine <machine>] (required)
                            [-c|--client <vncclient>] (required)
                            [-d|--debug] (optional)
	                    [-p|--port <display port>] (optional)
			    [-u|--user <hpcuserid> (required: if $USER is different on remote host)
			    [-k|--keep] (optional)
			    [-r|--reconnect] (optional)
			    [-w|--wm <fvwm|mwm|xfwm4|openbox-session>] (optional)
			    [-h|--help]

          Questions?        <vnc2hpc@lanl.gov> 
          Need Help?        https://git.lanl.gov/hpcsoft/vnc2hpc/-/blob/master/README.md
```
### Usage Examples - Connecting to Snow

#### Initial Setup on the Remote

VNC2HPC does some sanity testing when run, to ensure it has all it needs to successfully connect the client to the server on the remote system. 
If the script is unable to find `$HOME/.vnc/passwd`, it will walk the user through the password creation for the vncserver:

```
...
INFO       VNC passwd not available on sn-fey1 for jgreen                                                       
INFO       Do you want to setup a password now? [Y/N]                                                           
y
INFO       Enter your password (at least six characters long, up to eight)                                                   
INFO       Reenter your password to confirm                                          
```

Once this is setup on the "network" for the remote-host (i.e., Yellow, Turquoise, Red), it's sharable among all
remote hosts on that network thanks to common home directories on LANL networks.

##### Whoops, I forgot my vncpasswd! Now what?

If you forget your password, it's easy enough to remove it; though the file itself isn't encrypted, it's not in a readable format:

```
$>  ssh -l $USER sn-fey1
jgreen@sn-fey1>  rm ~/.vnc/passwd
jgreen@sn-fey1>  exit
$>  vnc2hpc -m sn-fey1 -c /Applications/VNC\ Viewer/Contents/MacOS/vncviewer
# walk through the password recreation process once again
```

##### Manually Set VNC Passwd

```bash
ssh -l ${USER} <machine>
$> vncpasswd
>  Password:
>  Verify:
>  Would you like to enter a view-only password (y/n)? n
>  A view-only password is not used
$> exit
```

#### Basic usage

##### To launch a session to Snow’s sn-fey1:

`$> ./vnc2hpc -c "/Applications/VNC\ Viewer.app/Contents/MacOS/vncviewer" -m sn-fey1`

##### To launch a session to Snow's turquoise frontend

`$> ./vnc2hpc -c “/Applications/VNC\ Viewer.app/Contents/MacOS/vncviewer” -m sn-fe1`

### Features

#### --client | -c

The client flag is how you direct vnc2hpc to the vncviewer on your desktop to use to connect to the vncserver.
It's a required option that will fail if not supplied.  A full path to the vncviewer executable is required if the executable
isn't in your $PATH.  To determine if the executable is in your path, in a terminal window, run `which vncviewer`.

`$> ./vnc2hpc -c “/Applications/VNC\ Viewer.app/Contents/MacOS/vncviewer” -m sn-fe1`
* note, it's not required to pass the client in double quotes to the script

#### --debug | -d

To have more visibility into the script's progression, you can run with --debug or -d

#### --machine | -m

This flag specifies the front-end node's short hostname you wish to connect to.  If you want to connect
to a system on the turquoise network, just pass the front-end short hostname to the script and it will detect
the network, and setup the gateway hop appropriately.

#### --keep | -k

To preserve your vncserver session for later reuse, run the script with --keep or -k

`$> ./vnc2hpc -c "/Applications/VNC\ Viewer.app/Contents/MacOS/vncviewer" -m sn-fey1 --keep`

To reconnect to this, you can request a reconnect with later invocations with a --reconnect or -r flag

`$> ./vnc2hpc -c "/Applications/VNC\ Viewer.app/Contents/MacOS/vncviewer" -m sn-fey1 --reconnect`

The --reconnect flag sets a sentinel to "keep" the reconnected session upon closing the viewer

#### --port | -p

One can request a specific port, and that port will be attempted to be connected to upon starting the vncserver

`$> ./vnc2hpc -c "/Applications/VNC\ Viewer.app/Contents/MacOS/vncviewer" -m sn-fey1 --port 15`

There is a limit of one vncserver service running per user per remote host, and the script will enforce this.
The script will prompt for an action on the command line if a port is already running for the user.

`$ ./vnc2hpc -m cp-loginy -c /Applications/VNC\ Viewer.app/Contents/MacOS/vncviewer -w fvwm`
`WARN       jgreen HAS ONE OR MORE VNCSERVER SESSIONS RUNNING!`
`WARN       ACTIVE VNCSERVER PORTS FOR jgreen ON cp-loginy     47`
`WARN       DO YOU WISH TO KILL OR REUSE THIS SESSION?         Y - yes, N - exit, R - reuse]?`

Note: the script is set to utilize the 5900 port range so the port supplied to the script should be limited to two characters

If that port returns a conflict when the vncserver script is invoked, the vnc2hpc script will utilize the newport.

Port is optional, as the script will randomly generate a port number between 1 and 99 to offer less likelihood that you
don't have localhost:port tunnel conflicts on the client side.

#### --user | -u

Sometimes the userid of the user running on the desktop system where vnc2hpc is invoked doesn't match the corresponding
userid for the remote system.  If you have different userids, you need to pass the remote userid (a.k.a. moniker) to the script

`$> ./vnc2hpc -c "/Applications/VNC\ Viewer.app/Contents/MacOS/vncviewer" -m sn-fey1 -u jgreen`

### Issues resolved for v0.0.2 tag

- [√] #2 xstartup script needs to be replicated to HOME before invoked
- [√] #1 initial passwd creation isn't implemented yet- start vncserver manually on the target machine, set a password, then use it to authenticate the connection when prompted.
- [√] #5 ssh -fN is suppressing remote commands
- [√] #3 xstartup script should use environment variable to set the window manager, rather than positional parameters
- [√] #4 feature request for fvwm support (os/arch specific builds- fix xstartup to find the right version)


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

