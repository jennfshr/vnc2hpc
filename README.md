[[_TOC_]]

_____

# VNC2HPC

VNC2HPC is a series of custom scripts that utilize available utilities on users' local machines and remote cluster resources to instantiate a VNC Client/Server connection to LANL HPC Resources.

_____

## What is VNC?

Virtual Network Computing (VNC) is a graphical desktop-sharing system that uses the Remote Frame Buffer protocol (RFB) to remotely control another computer. It transmits the keyboard and mouse events from one computer to another, relaying the graphical-screen updates back in the other direction, over a network.

**What does VNC2HPC do that isn't already supported by the VNCViewer utilities**

In order to use a VNC Viewer to connect to a headless server, such as that which we supply for Scientific Computing in HPC, there is a considerable amount of setup which is cumbersome and non-trivial to establish.  The point of this software is to automate the setup and abstract away from customers the complexity of establishing a manual client server connection.  We hope that this software helps you in your scientific endeavors on HPC systems. We encourage bug reports, issues, questions and feedback to be sent to consult@lanl.gov or the vnc2hpc@lanl.gov mailing list so that we can improve this product over time. 

_____

## Production Status
VNC2HPC is currently undergoing beta testing with a set of interested HPC customers at LANL. During this time, the software will be updated frequently to address requests and bug reports until hardened and ready for production.

_____

## Mailing list
You can subscribe to the mailing list if you'd like to be more involved in the development efforts for this product.  Discourse in software issues, improvements, and usage is encouraged in this mailing list while we incorporate improvements to this software.

**Subscribe to vnc2hpc@lanl.gov mailing list**

[Register.lanl.gov](https://register.lanl.gov/lists/subscribe.php) 
*LANL CryptoCard Authentication Required*

**Engage with beta-testers and developers on the Mailing List**
*Have questions, feature requests, concerns?  Email: vnc2hpc@lanl.gov*

_____

## System Requirements
This software requires a VNC Client installation on the system where it is running. Testing of VNC2HPC is conducted against RealVNC and TigerVNC.  

**Requirements**
Additionally, you'll need to have:

**System packages**

* A terminal application (i.e., Xterm, Terminal) 
* BASH >=v3.x
* SSH client (where ssh is in your $PATH).

**Downloadable VNC Viewer Clients Links**

* [VNCViewer](https://www.realvnc.com/en/connect/download/viewer/)
* [TigerVNC](https://bintray.com/tigervnc/stable/tigervnc/1.11.0)

**Obtain VNC2HPC Tool**

*Note: In the future, will be supplied via LANL Self Services Application Catalog*

**Two methods to obtain VNC2HPC**

**Direct Download**

* Click here to download the script directly: [VNC2HPC](https://git.lanl.gov/hpcsoft/vnc2hpc/-/raw/master/bin/vnc2hpc?inline=false)

**Clone the project**
* `git clone git@git.lanl.gov:hpcsoft/vnc2hpc.git`

*Note:  as we beta test this product, a clone makes updating master as simple as `git pull`, so it's probably the simplest way to keep an updated copy on your system*

_____

## Quickstart

**Setup Software on your System**

**Install a VNC Viewer**

VNC Viewer downloads are supplied as a *DMG* (disk image) installer on MacOS, and are supplied in various packaging system formats, or from source installs on Linux.

<details>
  <summary markdown="span">Expand section for details on finding the install path on MacOS</summary>

Install the viewer you prefer whichever way you desire to install it.  The critical part is knowing the path to the vncviewer executable. 

There are a couple options for finding this, for instance, on a Mac/Linux system you can use the find command on the command line.  

On a Mac, it's sometimes difficult via the Finder App to determine the path to a file.  

Here's one way to do that:

1. Open the Finder app
2. Navigate to the VNC Viewer Application you just installed
* If you used a .dmg installation, it generally installs to Macintosh HD/Applications/VNC Viewer
* If you have trouble, you can use the search bar to search for "VNC Viewer"
3. Right click your mouse on the VNC Viewer in Finder, then select "Show Package Contents" to expose the subdirectory structure of the application
4. You can use Search again to find where vncviewer lives under the application container. Generally, it's in a subdirectory path like: Contents > MacOS > vncviewer
5. When you've found vncviewer in Finder, open another finder window, and click the Go button on the toolbar for Finder, then "Go to Folder" in the submenu.  In the window, drag the first Finder window's vncviewer file to the "Go to the Folder" field, and it will reveal the full path to the client, which you can then copy to your clipboard and use in the terminal for vnc2hpc.
6. Once you have that path, you can set an environment variable in your shell to reuse it.

*Note: spaces in file paths and filenames is common practice, and without escaping those paths when directing the vnc2hpc script to use them, it will fail to resolve the path.*

*Use '\ ' to escape spaces in the path to the viewer: `/Applications/VNC\ Viewer.app/Contents/MacOS`*

7. Set a variable in your .bashrc file:

	`export VNCV="/Applications/VNC\ Viewer.app/Contents/MacOS/vncviewer"`

	`source ~/.bashrc`

	`echo ${VNCV}`

* Note: this variable should be now set to be exported in your shell environment whenever you login to the system. If you set your environment up this way, you can simply use the variable to access the path to your viewer, rather than supplying the full path*

	`./vnc2hpc -m tt-fey -c ${VNCV}` 

</details>

_____

*Install the vnc2hpc script*

<details>
  <summary markdown="span">Expand section for guidance on setting up VNC2HPC</summary>

You can download here: [vnc2hpc](https://git.lanl.gov/hpcsoft/vnc2hpc/-/raw/master/bin/vnc2hpc?inline=false)

One you have done this, you'll need to change permissions to make the script executable:
`chmod +x vnc2hpc`

It's recommended to setup a directory to house this script, then set your user $PATH variable to point to that directory:

`mkdir -p ~/vnc2hpc`

`mv ~/Downloads/vnc2hpc ~/vnc2hpc/`

And if you add this line to your ~/.bashrc file, it will setup the $PATH to have vnc2hpc as a ready command in your shell:

`export PATH=~/vnc2hpc:${PATH}`

`source ~/.bashrc`

`which vnc2hpc`

*Alternative approach (perhaps preferable) is to clone the repository to your local machine, that way, the directory will already by in place, and a simple `git pull` while sitting in that directory will update your software to the latest stable version.* 

Again, if you do this, be sure to adjust the `export PATH` command in your .bashrc to prepend PATH with the bin subdirectory of the repository, where the vnc2hpc script is in the repository. 

</details>

_____

## Usage Output

The usage output is available by running

`./vnc2hpc --help`

```vnc2hpc v0.0.2

          usage: vnc2hpc    [-m|--machine <machine>] (required)
                            [-c|--client <vncclient>] (required)
                            [-d|--debug] (optional)
	                    [-p|--port <display port>] (optional)
			    [-u|--user <hpcuserid>] (required: if $USER is different on remote host)
			    [-k|--keep] (optional)
			    [-r|--reconnect] (optional)
			    [-w|--wm <fvwm|mwm|xfwm4] (optional)  Default: [-w mwm] (Motif Window Manager)
			    [-h|--help]

          Questions?        <vnc2hpc@lanl.gov> 
          Need Help?        https://git.lanl.gov/hpcsoft/vnc2hpc/-/blob/master/README.md
```

_____

## Machines Supported

**Machines supported**

<details>
	<summary markdown="span">Expand to see LANL Machines VNC2HPC Supports</summary>

Snow:
* sn-fe
* sn-fey
Badger
* ba-fe
Capulin
* cp-login
* cp-loginy
Grizzly
* gr-fe
* gr-fey
Kodiak
* ko-fe
* ko-fey
Fog
* fg-fey
Woodchuck
* wc-fe
Trinitite
* tt-fey
Fire
* fi-fe
Ice
* ic-fe
Cyclone
* cy-fe
Trinity
* tr-fe

</details>

_____

## Basic usage

vnc2hpc knows about all LANL HPC supported resources in the yellow, turquoise and red networks.  Here's the list of the front-ends you potentially can run a VNC session on:

*To launch a session to Snow’s Yellow frontend*

`$> ./vnc2hpc -c "/Applications/VNC\ Viewer.app/Contents/MacOS/vncviewer" -m sn-fey1`

*To launch a session to Snow's Turquoise frontend*

`$> ./vnc2hpc -c “/Applications/VNC\ Viewer.app/Contents/MacOS/vncviewer” -m sn-fe1`

**Round Robin Aliases**

As our customers are aware, LANL HPC supplies round-robin aliases to make access to the clusters simpler for the customers, and the vnc2hpc tool supports their use, too.  

**Reconnecting to a running VNCServer session**

Additionally, you can direct the tool to a specific front-end node, which is especially important when re-connecting to a listening vncserver session.  The tool upon disconnecting to a session when run with the `-k` (keep alive) flag, will supply the hostname where the kept session is running.  To reconnect, use that for the machine parameter upon reconnection. 

**VNC Password Setup is Required the First Time Running `vncserver`**

VNC Server (on the cluster) requires a password to be set before a client>server connection is possible.  This password is housed on the server side by default at `$HOME/.vnc/passwd`.  

If you have never run VNC Server before, vnc2hpc will walk you through the initial setup, as detailed below. 

*Note: whereas the password generated by vncserver isn't encrypted, it's also not human readable.  There are several known exploits to decode the vncserver passwd file, so it's important to protect the password.  vnc2hpc sets a new password based on the user supplied and confirmed password supplied by the user.  If you've established a password for vncserver in a non-standard location, to use this script, you maybe able to soft-link at `~/.vnc/passwd` to your password file and have success.* 

vnc2hpc does some sanity testing when run, to ensure it has all it needs to successfully connect the client to the server on the remote system. 
If the script is unable to find `$HOME/.vnc/passwd`, it will walk the user through the password creation for the vncserver:

```
$> vnc2hpc -m sn-fey -w fvwm -k -c "${VNCV}"
INFO       VNC CLIENT INFO:                                   VNC(R)Viewer-6.20.529 
INFO       LOCALHOST OS INFO:                                 pike.lanl.gov-Darwin
INFO       REMOTE USER:                                       jgreen
INFO       WINDOWMANAGER:                                     fvwm
INFO       MACHINE:                                           sn-fey
INFO       NETWORK:                                           YELLOW
jgreen@sn-fey's password:
jgreen@sn-fey1.lanl.gov's password:
INFO       VNC CLIENT vncviewer LOGGING                       /Users/jgreen/.vnc2hpc/sn-fey1.lanl.gov/vncclient.log.11-02-20-06.11.26     
INFO       VNC SERVER LOGGING                                 /Users/jgreen/.vnc2hpc/sn-fey1.lanl.gov/vncserver.log.11-02-20-06.11.26
INFO       VNC passwd not available on sn-fey1.lanl.gov for jgreen
INFO       Do you want to setup a password now? [Y/N]
y
INFO       Enter your password (at least six characters long, up to eight)
INFO       Reenter your password to confirm                                
INFO       SETTING VNCPASSWD                                  sn-fey1.lanl.gov for jgreen                                                       
INFO       VNCPASSWD SET!                                                       
```

Once this password is set on the "network" for the remote-host (i.e., Yellow, Turquoise, Red), it's sharable among all remote hosts on that network due to the shared home directories on LANL networks.

_____

**Whoops, I forgot my vncpasswd! Now what?!**

If you forget your password, it's easy enough to remove it; though the file itself isn't encrypted, it's not in a readable format, so the simplest solution it to remove it:

**Reset VNCPasswd**
```
$>  ssh -l $USER sn-fey1
jgreen@sn-fey1>  rm ~/.vnc/passwd
jgreen@sn-fey1>  exit
$>  vnc2hpc -m sn-fey1 -c /Applications/VNC\ Viewer/Contents/MacOS/vncviewer
# walk through the password recreation process once again
```

_____

**Manually Set VNC Passwd**

The vnc2hpc software will help you set your password.  If you would like to do this outside the tool, it's pretty simple.  Here's how:

```bash
ssh -l ${USER} <machine>
$> vncpasswd
>  Password:
>  Verify:
>  Would you like to enter a view-only password (y/n)? n
>  A view-only password is not used
$> exit
```

_____

## Arguments

### [-m|--machine <machine>] (required)

This flag specifies the front-end node's hostname you wish to connect to.  If you want to connect
to a system on the turquoise network, just pass the front-end hostname to the script and it will detect
the network, and setup the gateway hop appropriately.

*NOTE: LANL HPC Systems round-robin aliases are permittable arguments.
When used, a remote /etc/hosts lookup will be performed in order to construct a list of valid hosts, from which a random hostname will be selected.  If the `--keep` option is supplied to the script, output will instruct which hostname was used, as a reconnect to that vncserver will require a specific hostname.*

_____

### [-c|--client <vncclient>] (required)

The client flag is how you direct vnc2hpc to the vncviewer on your desktop to use to connect to the vncserver.
It's a required option that will fail if not supplied.  A full path to the vncviewer executable is required if the executable
isn't in your $PATH.  To determine if the executable is in your path, in a terminal window, run `which vncviewer`.

`$> ./vnc2hpc -c “/Applications/VNC\ Viewer.app/Contents/MacOS/vncviewer” -m sn-fe1`

*NOTE: it's not required to pass the client in double quotes to the script, and tab-completion on the command-line to resolve the full path to the client is supported.* 

_____

### [-d|--debug] (optional)

To have more visibility into the script's progression, you can run with --debug or -d

_____

### [-k|--keep] (optional)

To preserve your vncserver session for later reuse, run the script with --keep or -k

`$> ./vnc2hpc -c "/Applications/VNC\ Viewer.app/Contents/MacOS/vncviewer" -m sn-fey1 --keep`

To reconnect to this, you can request a reconnect with later invocations with a --reconnect or -r flag

`$> ./vnc2hpc -c "/Applications/VNC\ Viewer.app/Contents/MacOS/vncviewer" -m sn-fey1 --reconnect`

The --reconnect flag sets a sentinel to "keep" the reconnected session upon closing the viewer

*NOTE: if a vncserver is left running on a host, the next attempt to vnc2hpc connect to that host will see that it's running and provide you a chance to `Kill it, Ignore It, or Reuse it`, interactively.*

_____

### [-p|--port <display port>] (optional)

One can request a specific port, and that port will passed to the vncserver command.  However, if the 
vncserver invocation on that port doesn't succeed, vncserver (on the cluster) will attempt to auto-select a port.
That value then will be passed back to the client to use for connection to the machine. 

`$> ./vnc2hpc -c "/Applications/VNC\ Viewer.app/Contents/MacOS/vncviewer" -m sn-fey1 --port 15`

*NOTE: There is a limit of one vncserver service running per user per remote host, and the script will enforce this.*


_____

### [-u|--user <hpcuserid>] (required: if $USER is different on remote host)

Sometimes the user id of the user running on the desktop system where vnc2hpc is invoked doesn't match the corresponding user id for the remote system.  If you have different user ids, you need to pass the remote userid (a.k.a. moniker) to the script

`$> ./vnc2hpc -c "/Applications/VNC\ Viewer.app/Contents/MacOS/vncviewer" -m sn-fey1 -u jgreen`

_____

### [-w|--wm <fvwm|mwm|xfwm4>] (optional) Default: [-w mwm] (Motif Window Manager)

Currently, three window managers are supported.  The window manager supplies the graphical interface to the system you're connecting to with the tool.  The window managers are deliberately selected among those that use the least resources, so you'll note that the gnome-session is unavailable under vnc2hpc.  

*NOTE: Investigations into openbox support is on-going, as it is a more modern stacking interface than those currently offered.*

_____

## Window Managers

The motivation for the VNC2HPC product is to make a VNC setup accessible for the purpose of running GUI applications on the headless nodes of HPC Clusters at LANL.  There's an important distinction between the desktop environment (i.e., KDE/Gnome/Xfce) and the window manager environment, which this setup strives to support.  A Desktop Environment would place more demand on the shared resources on our cluster front-ends, therefore we don't offer those environments via the VNC2HPC software connection. 

| Product | Product Info | URL |
| ------ | ------ | ------ |
| Motif Window Manager (mwm) | X window manager based on the Motif toolkit. | http://motif.ics.com/ |
| F ? Virtual Window Manager (fvwm) | ICCCM Compliant minimal WM | https://www.fvwm.org/ |
| Xfce 4 Window Manager (xfwm4) | Part of the Xfce Desktop Environment | https://docs.xfce.org/xfce/xfwm4/start |

_____

## Session Management

The script will prompt for an action on the command line if a port is already running for the user.

`$> ./vnc2hpc -m cp-loginy -c /Applications/VNC\ Viewer.app/Contents/MacOS/vncviewer -w fvwm`

`WARN       jgreen HAS ONE OR MORE VNCSERVER SESSIONS RUNNING!`

`WARN       ACTIVE VNCSERVER PORTS FOR jgreen ON cp-loginy     47`

`WARN       DO YOU WISH TO KILL OR REUSE THIS SESSION?         [Y - yes, N - exit, R - reuse]?`

*NOTE: the script is set to utilize the 5900 port range so the port supplied to the script should be limited to two characters*

If that port returns a conflict when the vncserver script is invoked, the vnc2hpc script will utilize the vncserver selected port.

Port is optional, as the script will randomly generate a port number between 1 and 99 to offer less likelihood that you don't have `localhost:$port` tunnel conflicts on the client side.

_____

## Client Compatibility Table
| Version | OS | Viewer | Window Managers
| ------ | ------ | ------ | ------ |
| v0.0.2 | MacOSX v10.14.6 | VNC(R)Viewer-6.20.529 | fvwm, mwm, xfwm4 |
| v0.0.2 | MacOSX v10.14.6 | TigerVNC Viewer 32-bit v1.4.3 | fvwm, mwm, xfwm4 |
| v0.0.2 | MacOSX v10.14.6 | TigerVNC Viewer 64-bit v1.10.1 | fvwm, mwm, xfwm4 |
| v0.0.2 | Linux | UNTESTED | UNTESTED |
| v0.0.2 | Windows | UNTESTED | UNTESTED |
