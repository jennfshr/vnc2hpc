# vnc2hpc

## Quickstart
The usage output is available by running `./vnc2hpc.sh --help`


```
   vnc2hpc.sh v0.0.1

          usage: vnc2hpc.sh [-d|--debug]

                            [-p|--port <display port>]

                            [-m|--machine <machine>]

                            [-u|--user <hpcuserid>

                            [-c|--client <vncclient>]

                            [-k|--keep]

                            [-r|--reconnect]

                            [-h|--help]

                            [-w|--wm <mwm>]

```

### Usage Examples - Connecting to Snow

For instance, to launch a session to Snow’s sn-fey1:

`$> ./vnc2hpc.sh -c "/Applications/VNC\ Viewer.app/Contents/MacOS/vncviewer" -m sn-fey1`

Or to connect to a turquoise hosted system:

`$> ./vnc2hpc.sh -c “/Applications/VNC\ Viewer.app/Contents/MacOS/vncviewer” -m sn-fe1`

### Issues for v0.0.2 tag

- [ ] #1 initial passwd creation isn't implemented yet- start vncserver manually on the target machine, set a password, then use it to authenticate the connection when prompted.

```
ssh -l ${USER} <machine> 
$> vncpasswd 
>  Password:
>  Verify:
>  Would you like to enter a view-only password (y/n)? n
>  A view-only password is not used
$> exit
```

### Some usage details:

`--keep` your vncserver session, up to a Max of 3 (this likely will need to be reduced…)

`--user` is only required if the HPC system $USER is different from that of the $USER on the local system.

`--port` is specifiable – not yet as heavily exercised as I’d like, but the intent is to `--reconnect --port 03` or to --reconnect and it will auto-detect the port(s) available and connect to one and the kept vncserver session is one that you may return to as you want.

`--wm` is right now statically coded to just the Motif Window Manager, I’d like to harden the user facing scripts before I beef up the back end capabilities.

`--client` is the path to the Viewer client on the local host, put it in double-quotes, escaping any spaces in the directory names.

## Compatibility Table
| Version | OS | Viewer | Window Managers
| ------ | ------ | ------ | ------ |
| v0.0.1 | MacOSX v10.14.6 | VNC(R)Viewer-6.20.529 | motif-2.3.4 |
| v0.0.1 | MacOSX v10.14.6 | TigerVNC Viewer 32-bit v1.4.3 | motif-2.3.4 |
| v0.0.1 | MacOSX v10.14.6 | TigerVNC Viewer 64-bit v1.10.1 | motif-2.3.4 |
| v0.0.1 | Linux | UNTESTED | UNTESTED |
| v0.0.1 | Windows | UNTESTED | UNTESTED |

## What is VNC

Virtual Network Computing (VNC) is a graphical desktop-sharing system that uses the Remote Frame Buffer protocol (RFB) to remotely control another computer. It transmits the keyboard and mouse events from one computer to another, relaying the graphical-screen updates back in the other direction, over a network.

## In depth Explanation

