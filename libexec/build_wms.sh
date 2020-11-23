#!/bin/bash
#This is a simple automation for building out the non-system window manager installations

#Some global variables
HPCSOFT_COMMON="/usr/projects/hpcsoft/common"
OS=$(/usr/projects/hpcsoft/utilities/bin/sys_os)
ARCH=$(/usr/projects/hpcsoft/utilities/bin/sys_arch)

#WMs to build: icewm, berry, openbox, fvwm
icewm_url="https://github.com/ice-wm/icewm/archive/1.9.2.tar.gz"
icewm_version="1.9.2"
berry_url="https://github.com/JLErvin/berry/archive/0.1.7.tar.gz"
berry_version="0.1.7"
openbox_url="http://openbox.org/dist/openbox/openbox-3.6.1.tar.gz"
openbox_version="3.6.1"
fvwm_url="https://github.com/fvwmorg/fvwm/archive/2.6.9.tar.gz"
fvwm_version="2.6.9"
fvwm3_url="https://github.com/fvwmorg/fvwm3/archive/1.0.1.tar.gz"
fvwm3_version="1.0.1"
mkdir -p ${TEMP_INSTALL_LOCATION:="/tmp/vnc2hpc-deps"}

export HTTP_PROXY=http://proxyout.lanl.gov:8080
export HTTPS_PROXY=http://proxyout.lanl.gov:8080
export http_proxy=http://proxyout.lanl.gov:8080
export https_proxy=http://proxyout.lanl.gov:8080

#Setup temp install directories for each WM
ICEWM_BUILD_DIR=${TEMP_INSTALL_LOCATION}/ICEWM && mkdir -p ${ICEWM_BUILD_DIR}
BERRY_BUILD_DIR=${TEMP_INSTALL_LOCATION}/BERRY && mkdir -p ${BERRY_BUILD_DIR}
OPENBOX_BUILD_DIR=${TEMP_INSTALL_LOCATION}/OPENBOX && mkdir -p ${OPENBOX_BUILD_DIR}
FVWM_BUILD_DIR=${TEMP_INSTALL_LOCATION}/FVWM && mkdir -p ${FVWM_BUILD_DIR}
FVWM3_BUILD_DIR=${TEMP_INSTALL_LOCATION}/FVWM3 && mkdir -p ${FVWM3_BUILD_DIR}

# Build ice-wm
pushd ${ICEWM_BUILD_DIR}
wget ${icewm_url}
tar_name=$(ls)
echo $tar_name
exit 




