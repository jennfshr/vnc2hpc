### Windows Subsystem for Linux

Since 2017, Windows has supplied the WSL tool in its Operating System.  The best version to run is WSL2, which offers vast improvements over WSL1, namely, running a real Linux kernel, which will be updated along with regular Windows 10 software updates.

### Prerequisites

Ensure you're running a compatible version of Windows.
- Check that the version of Windows 10 will support WSL 2 by opening a PowerShell and typing
`winver`
Version and Build must be higher than 1903 and 18362 respectively for x64 systems, or 2004 and 19041 respectively for ARM64.
- Windows 10 May 2020 (v2004)
- Windows 10 May 2019 (v1903 builds 18362.1049) with [Windows Update KB4566116](https://support.microsoft.com/en-us/topic/august-20-2020-kb4566116-os-builds-18362-1049-and-18363-1049-preview-c75c6a43-9c87-e412-9a9e-10a0dabac4d5:"KB4566116")
- Windows 10 November 2019 (v1909 with 18363.1049 [Windows Update KB4566116](https://support.microsoft.com/en-us/topic/august-20-2020-kb4566116-os-builds-18362-1049-and-18363-1049-preview-c75c6a43-9c87-e412-9a9e-10a0dabac4d5:"KB4566116") 

### WSL Setup (Microsoft Store)

If you're on a personal computer and have access to the Microsoft Store, you can setup WSL using [these instructions](https://docs.microsoft.com/en-us/windows/wsl/install-win10#manual-installation-steps). When you reach the point where you have to pick a Linux distribution, choose Ubuntu 20.04.


### WSL Setup (LANL Computer)

Normally, you would get this through the Microsoft Store, however, on LANL laptops, the Microsoft Store app isn't supplied.  


### WSL Enablement (LANL Computer)

You'll need an administrator account to enable WSL on your system.

**Enable Developer Mode in Windows 10**
- [Enable Developer Mode in Windows 10](https://answers.microsoft.com/en-us/insider/forum/insider_wintp-insider_install/how-to-enable-the-windows-subsystem-for-linux/16e8f2e8-4a6a-4325-a89a-fd28c7841775)
- Click Start > Settings > Update & security > For developers
- Select the Developer mode radio box then click Yes

**Enable Windows Subsystem Linux**
- Open a PowerShell with administrator privileges and run:
```
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
```

**Enable the Virtual Machine Platform**
- Open a PowerShell with administrator privileges and run
```
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

**Restart Windows 10 for changes to take effect**

**Linux Kernel Update for WSL1 > 2 upgrade**
- [Download wsl_update_x64.msi](https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi)
- Run file

**Set WSL2 as WSL default in a PowerShell**
```
wsl --set-default-version 2
```

#### Powershell installation method to install a Linux subsystem without MSStore access (i.e., LANL desktop)

**Use PowerShell to install already downloaded Ubuntu 20.04 Linux Subsystem**
- Navigate to Microsoft's website to download WSL Distribution [MS WSL Manual Installation](https://docs.microsoft.com/en-us/windows/wsl/install-manual)
- click on the link to Download and Select folder to Download to
**OR**
- Open PowerShell with elevated privileges and run:
```
Invoke-WebRequest -Uri https://aka.ms/wslubuntu2004 -OutFile Ubuntu_2004.appx -UseBasicParsing
```
(where "wslubuntu2004" and "Ubuntu_2004.appx" are replaced with values corresponding to the distribution of choice)
- Install the distribution by opening a PowerShell and running:
```
Add-AppxPackage .\app_name.appx
```
- *If PowerShell resists this (i.e., `wsl --list --verbose` doesn't indicate any available machines after the Add-AppxPackage command), you may need to:*
```
Rename-Item .\app_name.appx .\app_name.zip
Expand-Archive .\app_name.zip .\app_name
cd .\app_name
.\app_name.exe
``` 
- Walk through the prompts to setup a username and password in your new Linux machine (hint: set username to the same for HPC clusters, and you can avoid having to supply a --user argument to vnc2hpc)

#### Setup Windows 10 X Server for Graphical support in your Linux environment
**Install VcXsrv Windows X Server for Graphical Support for your WSL Ubuntu System**
- get the Windows X Server download here: [VcXsrv Windows X Server](https://sourceforge.net/projects/vcxsrv/files/latest/download)
- run the installer
- Click on Desktop icon or pinned Start Menu XLaunch to start the X Server on your Windows system
- Select display settings > Multiple Windows > Next
- Click radial button "Start no client" > Next
- Extra settings select "Disable access control" > Next > Finish

#### Starting and Configuring your new Linux machine for use
- First, check that wsl recognizes the new Linux system (in Powershell)
```
wsl --list --verbose
```
- Set the desired Linux Distro as default
```
wsl --set-default Ubuntu-20.04
```
- Start Ubuntu from PowerShell
```
wsl
```
- If not already done, create a username and password upon your initial sign-in when prompted.  This account will have elevated privileges (sudo)

#### Setting up the Aptitude Package Manager for Ubuntu on WSL2
- Using elevated privileges, create a file for "apt" to correctly use the LANL proxies
```
sudo vim /etc/apt/apt.conf.d/40lanlproxies
```
(insert the following contents, save and close file)
```
Acquire {
	HTTP::PROXY "http://proxyout.lanl.gov:8080";
	HTTPS::PROXY "http://proxyout.lanl.gov:8080";
	http::proxy "http://proxyout.lanl.gov:8080";
	https::proxy "http://proxyout.lanl.gov:8080";
}
```

#### Setup login environment for root and user
 
- Open the .bashrc for the root user and include the export commands for using the proxy for general internet access for root; append to the file the contents of the code block below; this file will be sourced upon "login" to make these settings persist between sessions for both root and user logins. 

1. Edit root's .bashrc file

`sudo vim /root/.bashrc`

2. Edit user's .bashrc

- Open your user .bashrc to include the same proxy settings for the regular user

`vim $HOME/.bashrc`

```
export HTTP_PROXY='http://proxyout.lanl.gov:8080'
export HTTPS_PROXY='http://proxyout.lanl.gov:8080'
export http_proxy='http://proxyout.lanl.gov:8080'
export https_proxy='http://proxyout.lanl.gov:8080'
export FTP_PROXY='http://proxyout.lanl.gov:8080'
export ftp_proxy='http://proxyout.lanl.gov:8080'
export NO_PROXY='localhost,127.0.0.1,.lanl.gov'
export no_proxy='localhost,127.0.0.1,.lanl.gov'
```

#### Configure DNS settings for WSL in a more permanent way

- Upon startup, WSL2 will auto-generate the /etc/resolv.conf configuration file.  This makes DNS resolution on LANL networks somewhat tricky.  The following steps will adjust WSL to make a more permanent configuration:
1. Turn off generation of /etc/resolv.conf

Using your Linux prompt, modify (or create) /etc/wsl.conf with the following content
```
[network]
generateResolvConf = false
```
*(Apparently there's a bug in the current release where any trailing whitespace on these lines will trip things up.)*

2. Restart the WSL2 Virtual Machine

Exit all of your Linux prompts and run the following Powershell command
```
wsl --shutdown
```
3. Create a custom /etc/resolv.conf

```
sudo cp /etc/resolv.conf /etc/resolv.conf.bak
```

If resolv.conf is soft linked to another file, remove the link with

```
sudo unlink /etc/resolv.conf
```

Create a permanent resolv.conf with the following steps to stage a ASCII Text File for the prior link, replacing the autogenerated one (where nameserver is defined to be a session specific and not persistent DNS IP address, especially when on the VPN connection) with the DNS servers for LANL, falling through to the Google DNS servers in the event you're using WSL without LANL network access.

```
sudo cp /etc/resolv.conf.bak /etc/resolv.conf
sudo vim /etc/resolv.conf
```

```
# This file was automatically generated by WSL. To stop automatic generation of this file, add the following entry to /etc/wsl.conf:
# [network]
# generateHosts = false
search lanl.gov localdomain
nameserver 128.165.0.53
nameserver 128.165.0.54
```

4. Test internet connectivity

```
ping 1.1.1.1
```

5. Test DNS resolution

```
ping google.com
ping hpc.lanl.gov
```
*If all ping commands indicate packet transmission, then you should now have networking fixed for the following steps*

6. Test persistence across reboot of the Ubuntu system

- In PowerShell, invoke this command to shutdown your Ubuntu system

`wsl --shutdown` 

- Restart Ubuntu and ensure that resolv.conf is unchanged

`wsl`
`cat /etc/resolv.conf`
`ping google.com`
`ping hpc.lanl.gov`

#### Setup Ubuntu for X capabilities

```
sudo apt-get update
sudo apt-get full-upgrade
sudo apt-get autoremove
sudo apt install x11-apps xvfb
sudo apt install xfce4
```

**Install VNC Viewer on Ubuntu**
- Download from https://www.realvnc.com/en/connect/download/viewer/linux the Debian package for your architecture (the following assumes x64)

```
cd /tmp
wget https://www.realvnc.com/download/file/viewer.files/VNC-Viewer-6.21.406-Linux-x64.deb
sudo apt install /tmp/VNC-Viewer-6.20.529-Linux-x86.deb
which vncviewer #to test that it got installed
```

**Set DISPLAY**
- Graphical tools require a $DISPLAY environment setting to operate.  Set these environmental variables in the aforementioned .bashrc files to use GUI apps, like VNCViewer, for instance

```
export DISPLAY=$(awk '/nameserver / {print $2; exit}' /etc/resolv.conf 2>/dev/null):0
export LIBGL_ALWAYS_INDIRECT=1
```

- Test the usability of the display (in conjunction with your newly updated system and XLaunch Windows client)

```
source ~/.bashrc
echo $DISPLAY
xeyes & # xeyes is backgrounded, can close the gui if it pops up, if it fails, revisit previous steps to ensure you have completed the steps correctly
```

#### Kerberos Configuration for LANL Linux systems
- Whereas this is not *required* for vnc2hpc to function, it will improve the quality of your experience by utilizing forwardable Kerberos tickets when using the tool, without having to re-authenticate.  It's highly recommended.

1. Install Kerberos Package

`sudo apt install krb5-user`
*the prompts will imply that the configuration is complete.  This is not the case.  Further configuration steps should be continued below.

2. Configure Kerberos for LANL kerberos authentication support

`sudo vim /etc/krb5.conf`

and edit, replacing the default configuration with the following:

```
[logging]
        default = FILE:/var/log/krb5libs.log
        kdc = FILE:/var/log/krb5kdc.log
        admin_server = FILE:/var/log/kadmind.log

[libdefaults]
        default_realm = lanl.gov
        dns_lookup_kdc = false
        dns_lookup_realm = false
        rdns = false
        allow_weak_crypto = true
        forwardable = true
        renew_lifetime = 7d
        ticket_lifetime = 10h

[realms]
        lanl.gov = {
                kdc = kerberos.lanl.gov
                kdc = kerberos-slaves.lanl.gov
                admin_server = kerberos.lanl.gov
                default_domain = lanl.gov
        }

[domain_realm]
        .lanl.gov = lanl.gov

[appdefaults]
        pam = {
            debug = false
        }
```

3. Test that it works

- This *should* generate a reusable and forwardable Kerberos ticket

```
kinit -f $USER
klist -l
```

- Test it by trying a connection to a HPC system

```
ssh sn-rfe2 -l $USER
```

#### Configure SSH to avoid issues with locale setting forwarding to HPC clusters

- Using elevated privileges, comment out `SendEnv LANG LC_*` in `/etc/ssh/ssh_config`

```
sudo vim /etc/ssh/ssh_config
```

- The line should now read: `#  SendEnv LANG LC_*`

#### Obtain vnc2hpc to use in your Ubuntu box

- There are a couple methods to get vnc2hpc in your Ubuntu session, depending on your access and desires

1. Download from this page the script or the full tarball for the vnc2hpc you want to use on Ubuntu on your Windows OS, this example assumes you have it in `C:\Users\${WINDOWS_USER}\Downloads`

```
cp /mnt/c/Users/${WINDOWS_USER}/Downloads/vnc2hpc-v0.0.13 $HOME
```

2. If you have access to the yellow network, you should be able to setup Git on Ubuntu to clone the project.  You'll need to generate ssh id_rsa.pub on Ubuntu, and register under your profile.  Refer to the directions for Cloning the Project in this documentation to clone the project. 

```
chmod +x vnc2hpc-v0.0.13
./vnc2hpc-v0.0.13 -m sn-rfe -c vncviewer
```

If you need help with WSL2 Ubuntu support, please don't hestitate to ask at consult@lanl.gov!
Enjoy your Linux appliance! 
