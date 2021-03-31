[[_TOC_]]

_____

# VNC2HPC

VNC2HPC is a series of custom scripts that utilize available utilities on users' local machines and remote cluster resources to instantiate a VNC Client/Server connection to LANL HPC Resources.

_____

## What is VNC?

Virtual Network Computing (VNC) is a graphical desktop-sharing system that uses the Remote Frame Buffer (RFB) protocol to remotely control another computer. It transmits the keyboard and mouse events from one computer to another, relaying the graphical-screen updates back in the other direction, over a network.

_____

## What does VNC2HPC do that isn't already supported by the VNCViewer utilities

In order to use a VNC Viewer to connect to a headless server, such as that which we supply for Scientific Computing in HPC, there is a considerable amount of setup which is cumbersome and non-trivial to establish.  The point of this software is to automate the setup and abstract away from customers the complexity of establishing a manual client server connection.  We hope that this software helps you in your scientific endeavors on HPC systems. We encourage bug reports, issues, questions and feedback to be sent to consult@lanl.gov or the vnc2hpc@lanl.gov mailing list so that we can improve this product over time. 

_____

## Production Status
VNC2HPC is now fully supported, production software for Linux and MacOS desktop systems at LANL.  Support for VNC2HPC, such as assistance in use, feature requests and bug reports may be reported to consult@lanl.gov.

_____

## Mailing list
You can subscribe to the mailing list if you'd like to be more involved in the development efforts for this product.  Discourse in software issues, improvements, and usage is encouraged in this mailing list while we incorporate improvements to this software.

**Subscribe to vnc2hpc@lanl.gov mailing list**

1. Click on link to register for the mailing list: [Register.lanl.gov](https://register.lanl.gov/lists/subscribe.php) (*LANL Weblogin Required*)

2. Enter: "vnc2hpc@lanl.gov" in the field

3. Then click: "Subscribe" button

**Engage the Mailing List**

*Have questions, requests, concerns?  Feel free to email: vnc2hpc@lanl.gov*

_____

## System Requirements
This software requires a VNC Client installation on the system where it is running. Testing of VNC2HPC is conducted against RealVNC and TigerVNC.  

_____ 

**Requirements**
Additionally, you'll need to have:

**System packages**

* A terminal application (i.e., Xterm, Terminal) 
* BASH >=v4.x
* SSH client (where ssh is in your $PATH).

_____

**Downloadable VNC Viewer Clients Links**

* [VNCViewer](https://www.realvnc.com/en/connect/download/viewer/)
* [TigerVNC](https://bintray.com/tigervnc/stable/tigervnc/1.11.0)

_____

**Obtain VNC2HPC Tool**

*Note: In the future, will be supplied via LANL Self Services Application Catalog*

**Two methods to obtain VNC2HPC**

**Direct Download**

* Click here to download the script directly: [VNC2HPC](https://git.lanl.gov/hpcsoft/vnc2hpc/-/blob/0.0.8/bin/vnc2hpc)

**Clone the project**
* `git clone git@git.lanl.gov:hpcsoft/vnc2hpc.git`

*Note:  A git repository clone makes updating the project branches as simple as `git pull`, so it's probably the simplest way to keep an updated copy on your system*

_____

## Quickstart

**Setup Software on your System**

_____

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

	`echo "${VNCV}"`

* Note: this variable should be now set to be exported in your shell environment whenever you login to the system. If you set your environment up this way, you can simply use the variable to access the path to your viewer, rather than supplying the full path*

	`./vnc2hpc -m tt-fey -c "${VNCV}"` 

</details>

_____

*Install the vnc2hpc script*

<details>
  <summary markdown="span">Expand section for guidance on setting up VNC2HPC</summary>

You can download vnc2hpc here: [vnc2hpc](https://git.lanl.gov/hpcsoft/vnc2hpc/-/blob/0.0.8/bin/vnc2hpc)

One you have done this, you'll need to change permissions to make the script executable:

`chmod +x vnc2hpc`

It's recommended to setup a directory to house this script, then set your user $PATH variable to point to that directory:

`mkdir -p ~/vnc2hpc`

`mv ~/Downloads/vnc2hpc ~/vnc2hpc/`

And if you add this line to your ~/.bashrc file, it will setup the $PATH to have vnc2hpc as a ready command in your shell:

`export PATH=~/vnc2hpc:${PATH}`

`source ~/.bashrc`

`which vnc2hpc`

*The preferred approach is to clone the repository to your local machine, that way, the directory will already by in place, and a simple `git pull` while sitting in that directory will update your software to the latest stable version.* 

Again, if you do this, be sure to adjust the `export PATH` command in your .bashrc to prepend PATH with the bin subdirectory of the repository, where the vnc2hpc script is in the repository. 

</details>

_____

## Usage Output

The usage output is available by running

`./vnc2hpc --help`

`vnc2hpc v0.0.11`

`		usage: vnc2hpc`

`			[-m|--machine <machine>]				(required)`

`			[-c|--client <vncclient>]				(required)`

`			[-u|--user <hpcuserid>] 				(optional) Default: $USER on localhost` 

`			[-v|--verbose]						(optional)`

`			[-d|--display <display>]				(optional)`

`			[-k|--keep]						(optional)`

`			[-r|--reconnect]					(optional)`

`			[-w|--wm icewm|berry|fvwm|mwm|xfwm4|openbox>]		(optional) Default: [-w mwm] (Motif Window Manager)`

`			[-g|--geometry <int>x<int>]                 		(optional) Default: xdpyinfo |grep dimensions`

`			[-a|--agent]					        (optional) Start the WM under the auspices of an ssh-agent`

`			[-p|--pixeldepth <int>]                     		(optional) Default: 24 - others: 16,32`

`			[-s|--source /path/to/source.tar.gz]			(optional) Only Required for systems with no backend installation and no yellow connection`

`			[-h|--help]`

`			[-J|--jobid <jobid>]					(optional) Attach to running job`

`		OPTIONS FOR INTERACTIVE JOB SUBMISSION:`

`			[-I|--interactive]					(optional) Run vncserver inside an interactive job on $MACHINE`

`			[-A|--account]						(optional) Without, vnc2hpc submits job with $USER default account in Slurm`

`			[-Q|--qos]						(optional) Without, vnc2hpc submits job with $USER qos defaults in Slurm`

`			[-R|--reservation]					(optional) For use when targeting nodes in a Slurm reservation`

`			[-T|--time]						(optional) Without, vnc2hpc submits job with $USER walltime defaults in Slurm`

`			[-C|--constraint]					(optional) For use when targeting nodes with Slurm Constraints`

`			[-P|--partition]					(optional) For use when targeting nodes in Slurm partition`

`			[-N|--numnodes]						(optional) Default: 1`

`		Questions?       <vnc2hpc@lanl.gov>`

`		Need Help?       https://git.lanl.gov/hpcsoft/vnc2hpc/-/blob//README.md`

_____

## Machines Supported

vnc2hpc knows about all LANL HPC supported resources in the yellow, turquoise and red networks.  Here's the list of the front-ends you potentially can run a VNC session on:

**Machines supported**

<details>
	<summary markdown="span">Expand to see LANL Machines VNC2HPC Supports</summary>

| Machine | Front-ends (Round-Robin Aliases) | Notes |
| -- | -- | -- |
| Snow | sn-fe, sn-fey, sn-rfe ||
| Badger | ba-fe ||
| Capulin | cp-login, cp-loginy ||
| Chicoma | ch-fe1, ch-fe2 | fvwm, icewm only |
| Gadget | ga-fe ||
| Grizzly | gr-fe, gr-fey ||
| Kodiak | ko-fe, ko-fey ||
| Fog | fg-fey ||
| Trinitite | tt-fey | berry segfaults |
| Darwin | darwin-fe | openbox build deps unmet |
| Fire | fi-fe ||
| Ice | ic-fe ||
| Cyclone | cy-fe ||
| Trinity | tr-fe ||
| Viewmaster | vm3-fe ||

</details>

_____

## Basic usage

This project strives to make the connection command simple, with as few required arguments as possible.  The two required arguments are "machine" (front-end node of cluster you're connecting to), and "client" (path to the local VNC Viewer that will attach to the remote VNC Server session.)  Additional arguments are in place to allow better control of the behavior, so a user may wish to switch to a different Window Manager (-w fvwm), launch a "persisting" VNCServer session on the target machine (--keep), or reattach to a previously launched session (-r).  Controls to try different screen resolution of the VNCServer Display and pixel depth are available if you have a desire to change from the defaults.  

Simple launch instructions follow.  As demonstrated below, the script is knowledgeable of LANL's various networks, and will match the requested front-end to the appropriate network to account for changes in the SSH command.  All you need to supply is the hostname (or round-robin alias) of the cluster's front-end where you wish to launch a VNC Session. 

*To launch a session to Snow’s Yellow frontend*

`$> ./vnc2hpc -c "/Applications/VNC\ Viewer.app/Contents/MacOS/vncviewer" -m sn-fey1`

*To launch a session to Snow's Turquoise frontend*

`$> ./vnc2hpc -c “/Applications/VNC\ Viewer.app/Contents/MacOS/vncviewer” -m sn-fe1`

**Avoiding cluster password prompt(s)**

*Initialize a forwardable Kerberos Ticket on your desktop system before running vnc2hpc*

`kinit -f ${USER}`

*Target a specific Darwin front-end*

`./vnc2hpc -m darwin-fe1 -c "/Applicatoins/VNC\ Viewer.app/Contents/MacOS/vncviewer"`

*Unavoidable authentication requirement for Turquoise systems to authenticate via wtrw gateway once - likely to change soon with the OUCH project*

**Stopping the Connection**

There are a couple ways to terminate your session, you can CTRL+C on the command line to kill the script, which will then kill your VNC Viewer connection to the tunnel, and terminate the session.  It's cleaner, however, to close the VNC Viewer window.  If you run the script with a `--keep` the session will remain on the targeted machine, so pointing vnc2hpc to use that machine subsequent to a 'kept' session will offer you the option to re-use that session.  Likewise, `--reconnect` will detect the vncserver session, and reuse that port, recreating the tunnel to re-attach to that same session. 

**Round Robin Aliases**

As our customers are aware, LANL HPC supplies round-robin aliases to make access to the clusters simpler for the customers, and the vnc2hpc tool supports their use, too.  

**Reconnecting to a running VNCServer session**

Additionally, you can direct the tool to a specific front-end node, which is especially important when re-connecting to a listening vncserver session.  The tool upon disconnecting to a session when run with the `-k` (keep alive) flag, will supply the hostname where the kept session is running.  To reconnect, use that same hostname for the machine parameter to auto-reconnect to a running vncserver. 

**VNC Password Setup is Required the First Time Running `vncserver`**

VNC Server (on the cluster) requires a password to be set before a client>server connection is possible.  This password is housed on the server side by default at `$HOME/.vnc/passwd`.  

If you have never run VNC Server before, vnc2hpc will walk you through the initial setup, as detailed below. 

*Note: whereas the password generated by vncserver isn't encrypted, it's not human readable.  There are several known exploits to decode the vncserver passwd file, so it's important to protect the password.  vnc2hpc sets a new password based on the user supplied and confirmed password supplied by the user.  If you've established a password for vncserver in a non-standard location, to use this script, you maybe able to soft-link at `~/.vnc/passwd` to your password file and have success.* 

vnc2hpc checks for basic requirements when run, to ensure it has all it needs to successfully connect the client to the server on the remote system. 
If the script is unable to find `$HOME/.vnc/passwd`, it will walk the user through the password creation for the vncserver:

```
$> vnc2hpc -m sn-fey -w fvwm -k -c "${VNCV}"
INFO       VNC2HPC VERSION:								0.0.5
INFO       RECEIVED REQUEST TO CONNECT TO:						sn-fey
INFO       VNC CLIENT INFO:								VNC(R)Viewer-6.20.529
INFO       LOCALHOST OS INFO:								pike.lanl.gov-Darwin
INFO       REMOTE USER:									jgreen
INFO       WINDOWMANAGER:								fvwm
INFO       GEOMETRY:									default
INFO       PIXELDEPTH:									24
INFO       MACHINE:									sn-fey
INFO       NETWORK:									YELLOW
INFO       VNC CLIENT vncviewer LOGGING:						/Users/jgreen/.vnc2hpc/sn-fey2.lanl.gov/vncclient.log.12-17-20-09.35.39
INFO       VNC SERVER LOGGING:								/Users/jgreen/.vnc2hpc/sn-fey2.lanl.gov/vncserver.log.12-17-20-09.35.39
INFO       VNC passwd not available or is of zero size on sn-fey2.lanl.gov for jgreen
INFO       Do you want to setup a password now? [Y/N]
y
INFO       Enter your password (at least six characters long, up to eight)
INFO       Reenter your password to confirm
INFO       SETTING VNCPASSWD								sn-fey2.lanl.gov for jgreen
INFO       VNCPASSWD SUCCESSFULLY SET!
```

Once this password is set on the "network" for the remote-host (i.e., Yellow, Turquoise, Red), it's sharable among all remote hosts on that network due to the shared home directories on LANL networks.

_____

**Whoops, I forgot my vncpasswd! Now what?!**

If you forget your password, the simplest solution it to remove it:

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

## Slurm integration

If you need to use a GUI inside of Slurm allocation on the target cluster, you'll find better windowing responsiveness if you use the Slurm attach or interactive features of vnc2hpc.  GLXGears benchmarking of a job where vncserver is running on the headnode of a job, versus one where the vncserver is launched on the front-end and X11 is forwarded to the job, demonstrates an order of magnitude improvement in the FPS rate.  Either ask vnc2hpc to allocate the job for you:
`vnc2hpc -m sn-fey1 -c "${VNCV}" -I -A <myaccount> -Q <myqos> -T <mywalltime>` or attach to an already running allocation `vnc2hpc -m sn-fey1 -c "${VNCV}" -J <jobid>`. 

_____

## Arguments

### [-m|--machine \<machine\>] (required)

This flag specifies the front-end node's hostname you wish to connect to.  If you want to connect
to a system on the turquoise network, just pass the front-end hostname to the script and it will detect
the network, and setup the gateway hop appropriately.

*NOTE: LANL HPC Systems round-robin aliases are permittable arguments.
When used, a remote /etc/hosts lookup will be performed in order to construct a list of valid hosts, from which a random hostname will be selected.  If the `--keep` option is supplied to the script, output will instruct which hostname was used, as a reconnect to that vncserver will require a specific hostname.*

_____

### [-c|--client \<vncclient\>] (required)

The client flag is how you direct vnc2hpc to the vncviewer on your desktop to use to connect to the vncserver.
It's a required option that will fail if not supplied.  A full path to the vncviewer executable is required if the executable
isn't in your $PATH.  To determine if the executable is in your path, in a terminal window, run `which vncviewer`.

`$> ./vnc2hpc -c “/Applications/VNC\ Viewer.app/Contents/MacOS/vncviewer” -m sn-fe1`

*NOTE: it's not required to pass the client in double quotes to the script, and tab-completion on the command-line to resolve the full path to the client is supported.* 

_____

### [-v|--verbose] (optional)

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

### [-d|--display \<display\>] (optional)

The display value that one may pass to the vnc2hpc script via the `-d <int>` option can be a integer between 1-58999, and the vncserver invocation will try to launch a server that listens on that particular display port.  Without a port argument, the script will randomly generate an integer in the higher range, and check to see whether there are other Xvnc processes listening on that port, then proceed with attempting to launch the VNCServer targeting that port.  
If one wants to reconnect to a vncserver session, the script will detect it upon invocation, and prompt for a response to "reuse" that session, otherwise, kill it and relaunch a new one. 

*NOTE: If the vncserver invocation on that port doesn't succeed, vncserver (on the cluster) will attempt to auto-select a port. That value then will be passed back to the client to use for connection to the machine.*

`$> ./vnc2hpc -c "/Applications/VNC\ Viewer.app/Contents/MacOS/vncviewer" -m sn-fey1 --display 12345`

*NOTE: There is a limit of one vncserver service running per user per remote host, and the script will enforce this.*

_____

### [-u|--user \<hpcuserid\>] (optional) Default: $USER on localhost

Sometimes the user id of the user running on the desktop system where vnc2hpc is invoked doesn't match the corresponding user id for the remote system.  If you have different user ids, you need to pass the remote userid (a.k.a. moniker) to the script

`$> ./vnc2hpc -c "/Applications/VNC\ Viewer.app/Contents/MacOS/vncviewer" -m sn-fey1 -u jgreen`

_____

### [-w|--wm \<icewm|berry|fvwm|mwm|xfwm4|openbox\>] (optional) Default: [-w mwm] (Motif Window Manager)

Currently, six window managers are supported.  The window manager supplies the graphical interface to the system you're connecting to with the tool.  On systems where non-system supplied window managers are absent, the script will attempt to build them on behalf of the user.  The resulting builds will be found in `~/.vnc2hpc/${os}/common/${arch}/${wm_product_name}/${wm_version}`.

*NOTE: ~/.vnc2hpc/vnc2hpc-${branch}/libexec/build_wms.sh is called when a requested Window Manager is absent on the remote machine.  The temporary build locations is set to `/tmp/vnc2hpc-deps_$USER`, where the `build.log` should supply some indication as to the cause for the failure.  In the circumstance that the Window Manager requires building before usage, `start_vncserver.sh` may take a while, as that script makes a call to `build_wms.sh` to accomplish the build.*

*Currently, openbox doesn't build on Darwin; Berry segfaults upon invocation on Trinitite.  As we refine the list of Window Managers we want to support, we'll address these limitations*

-----

### [-a|--agent] (optional) Start the WM under the auspices of an ssh-agent

ssh-agent is a key manager for SSH. It holds your keys and certificates in memory, unencrypted, and ready for use by ssh.  This feature benefits certain developer workflows by enabling ssh authentication automation.

-----

### [-g|--geometry \<int\>x\<int\>] (optional) Default: xdpyinfo |grep dimensions

To pass custom geometry dimensions to the vncserver instantiation on the remote machine, you can use this option with a dimension argument to describe the desired resolution of the vncserver window manager session. Supply as a argument to the -g flag a resolution in the form \<int\>x\<int\>, where the first value is the X-axis dimension (width), the second represents the Y-axis dimension (height).  If no argument is supplied to vnc2hpc, the default setting will be used, 1024x768. 

-----

### [-p|--pixeldepth \<int\>] (optional) Default: 24 - others: 16,32

To change the pixel depth of the desktop to be started, call the script with a `-P <int>` argument, where the integer represents the depth in bits.  The default value is 24, and other viable options are 16 and 32.  Other values of -P may cause odd behavior with certain applications.

-----

### [-J|--jobid \<jobid\>] (optional) Attach to running job

Pass `-J <jobid>` if you wish to launch and connect to a vncserver inside a running job on a cluster. The script uses the jobid supplied by this argument to query the scheduler for the headnode of the allocation, then extend the ssh tunnel to launch a vncserver on the headnode, rather than the front-end node.  If a vncseerver was previously launched with a `-k` option, the vncserver will continue to run the in context of the job, and a re-connect to that vncserver is accomplished by `vnc2hpc -m <machinename> -J <jobid> -r -d <display> -c "${VNCV}"`

-----

### [-I|--interactive] (optional) Run vncserver inside an interactive job on $MACHINE

Pass -I to the script to request a vncserver launched within an interactive allocation on the cluster.

-----

### [-A|--account \<accountname\>] (optional)

Pass `-A <accountname>` if you'd like to schedule the interactive allocation under a particular Slurm Account.

-----

### [-Q|--qos \<qos\>] (optional)

Use `-Q <qos>` to run Slurm interactive allocation under a particular Slurm quality of service (qos). 

-----

### [-R|--reservation \<reservation\>] (optional)

Use `-R <reservation>` to target a Slurm reservation on the cluster. 

-----

### [-T|--time \<HH:MM:SS\>] (optional)

Use `-T <time>` in the HH:MM:SS format required by slurm to allocate a job with the non-default walltime.

-----

### [-C|--constraint \<constraint\>] (optional)

Use `-C <constraint>` if a particular constraint is required on the desired target nodes.

-----

### [-P|--partition \<partition\>] (optional)

Use `-P <partition>` if you want your job to run under a non-default partition on the cluster. 

-----

### [-N|--numnodes \<numnodes\>] (optional)

Use `-N <numnodes>` to adjust how many nodes are requested in your Slurm allocation invocation. Defaults to the cluster's Slurm default, usually 1. 

-----

## Window Managers

The motivation for the VNC2HPC product is to make a VNC setup accessible for the purpose of running GUI applications on the headless nodes of HPC Clusters at LANL.  There's an important distinction between the desktop environment (i.e., KDE/Gnome/Xfce) and the window manager environment, that this setup strives to support.  A Desktop Environment would place more demand on the shared resources on our cluster front-ends, therefore we don't offer those environments via the VNC2HPC software connection. 

| Product | Product Info | URL |
| ------ | ------ | ------ |
| Motif Window Manager (mwm) | X window manager based on the Motif toolkit. | http://motif.ics.com/ |
| F ? Virtual Window Manager (fvwm) | ICCCM Compliant minimal WM | https://www.fvwm.org/ |
| Xfce 4 Window Manager (xfwm4) | Part of the Xfce Desktop Environment | https://docs.xfce.org/xfce/xfwm4/start |
| Openbox (openbox) | a highly configurable, next generation window manager with extensive standards support | https://openbox.org/wiki/Main_Page |
| IceWM (icewm) | The goal is speed, simplicity, and not getting in the user’s way | https://ice-wm.org |
| Berry (berry) | A healthy, bite-sized window manager written in C for unix systems | https://berrywm.org/ |


_____

## Session Management

The script will prompt for an action on the command line if a port is already running for the user.

`$> ./vnc2hpc -m cp-loginy -c /Applications/VNC\ Viewer.app/Contents/MacOS/vncviewer -w fvwm`

`WARN       jgreen HAS ONE OR MORE VNCSERVER SESSIONS RUNNING!`

`WARN       ACTIVE VNCSERVER PORTS FOR jgreen ON cp-loginy     47`

`WARN       DO YOU WISH TO KILL OR REUSE THIS SESSION?         [Y - yes, N - exit, R - reuse]?`

If that port returns a conflict when the vncserver script is invoked, the vnc2hpc script will utilize the vncserver selected port.

_____

## Client Compatibility Table
| Version | OS | Viewer | Window Managers
| ------ | ------ | ------ | ------ |
| v0.0.11 | MacOSX v10.14.6 | VNC(R)Viewer-6.20.529 | fvwm, mwm, xfwm4, berry, openbox, icewm |
| v0.0.11 | MacOSX v10.14.6 | TigerVNC Viewer 32-bit v1.4.3 | fvwm, mwm, xfwm4, berry, openbox, icewm |
| v0.0.11 | MacOSX v10.14.6 | TigerVNC Viewer 64-bit v1.10.1 | fvwm, mwm, xfwm4, berry, openbox, icewm |
| v0.0.11 | Linux Ubuntu | TigerVNC Viewer 64-bit v1.10.0 | fvwm, mwm, xfwm4, berry, openbox, icewm |
| v0.0.11 | Linux Ubuntu | VNC(R)Viewer-6.20.529 | fvwm, mwm, xfwm4, berry, openbox, icewm |
| v0.0.11 | Linux Centos8 | TigerVNC Viewer 64-bit v1.9.0 | fvwm, mwm xfwm4, berry, openbox icewm |
| v0.0.11 | Windows | UNSUPPORTED | UNSUPPORTED |

_____

## FAQs

#### How do I enable copy and paste on VNC?

Under UNIX or Linux, for VNC Server in Virtual Mode, a program called `vncconfig` may not be running. If this is the case, no VNC Server icon is displayed in the Notification Area, and copy and paste is disabled. To enable it again, type `vncconfig` in a Terminal window, and press the ENTER key.

#### I cannot access git.lanl.gov and want to run on a system where there are no backend installations!  How can I do this?

The git.lanl.gov resides in the yellow network, which isn't accessible by everyone.  If you find yourself hitting an error with the "curl" command performing the download of the repo contents for staging to your home directory on systems where there are no back-end installations (i.e., Darwin), the following sequence should make this work:

1. Download the compressed tarball of the project from https://hpc.lanl.gov/software/hpc-provided-software/vnc2hpc.html (Direct Download section) where the version matches the client version you wish to use. 
2. `scp <path-to>/vnc2hpc-v<version>.tar.gz $USER@$MACHINE:/tmp/.`
3. `./vnc2hpc-v<version> -m $MACHINE -s <path-to>/vnc2hpc-v<version>.tar.gz -c <client> <etc>`



