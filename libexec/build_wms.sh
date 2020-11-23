#!/bin/bash
#This is a simple automation for building out the non-system window manager installations

fix_perms () {
   local _PREFIX_PATH=$1
   chgrp -Rf hpcsoft ${_PREFIX_PATH} || exit 2
   chmod -Rf g+wrX,a+rX ${_PREFIX_PATH} || exit 2
}

mkclean_change () {
   local _BUILD_DIR=$1
   rm -Rf ${_BUILD_DIR} && mkdir -p ${_BUILD_DIR}
   pushd ${_BUILD_DIR}
}

tardir () {
   local _tar_name=$1
   tar tf $_tar_name | head -n 1 | sed 's/\///g'
}

# Some global variables
HPCSOFT_COMMON="/usr/projects/hpcsoft/common"
OS=$(/usr/projects/hpcsoft/utilities/bin/sys_os)
ARCH=$(/usr/projects/hpcsoft/utilities/bin/sys_arch)

# WMs to build: icewm, berry, openbox, fvwm
ICEWM_URL="https://github.com/ice-wm/icewm/archive/1.9.2.tar.gz"
ICEWM_VERSION="1.9.2"
BERRY_URL="https://github.com/JLErvin/berry/archive/0.1.7.tar.gz"
BERRY_VERSION="0.1.7"
OPENBOX_URL="http://openbox.org/dist/openbox/openbox-3.6.1.tar.gz"
OPENBOX_VERSION="3.6.1"
FVWM_URL="https://github.com/fvwmorg/fvwm/archive/2.6.9.tar.gz"
FVWM_VERSION="2.6.9"
FVWM3_URL="https://github.com/fvwmorg/fvwm3/archive/1.0.1.tar.gz"
FVWN3_VERSION="1.0.1"

# temp build dir
mkdir -p ${TEMP_INSTALL_LOCATION:="/tmp/vnc2hpc-deps"}

# setup proxies
export HTTP_PROXY=http://proxyout.lanl.gov:8080
export HTTPS_PROXY=http://proxyout.lanl.gov:8080
export http_proxy=http://proxyout.lanl.gov:8080
export https_proxy=http://proxyout.lanl.gov:8080

#Setup temp install directories for each WM
ICEWM_PRODUCT_NAME="icewm"
ICEWM_BUILD_DIR="${TEMP_INSTALL_LOCATION}/${ICEWM_PRODUCT_NAME}-${ICEWM_VERSION}"
ICEWM_PREFIX="${HPCSOFT_COMMON}/${OS}/${ARCH}/${ICEWM_PRODUCT_NAME}/${ICEWM_VERSION}"
ICEWM_BUILD_LOG="${TEMP_INSTALL_LOCATION}/${ICEWM_PRODUCT_NAME}-${ICEWM_VERSION}/build.log"
BERRY_PRODUCT_NAME="berry"
BERRY_BUILD_DIR="${TEMP_INSTALL_LOCATION}/${BERRY_PRODUCT_NAME}-${BERRY_VERSION}" && mkdir -p ${BERRY_BUILD_DIR}
BERRY_PREFIX="${HPCSOFT_COMMON}/${OS}/${ARCH}/${BERRY_PRODUCT_NAME}/${BERRY_VERSION}"
BERRY_BUILD_LOG="${TEMP_INSTALL_LOCATION}/${BERRY_PRODUCT_NAME}-${BERRY_VERSION}/build.log"
OPENBOX_PRODUCT_NAME="openbox"
OPENBOX_BUILD_DIR="${TEMP_INSTALL_LOCATION}/${OPENBOX_PRODUCT_NAME}-${OPENBOX_VERSION}" && mkdir -p ${OPENBOX_BUILD_DIR}
OPENBOX_PREFIX="${HPCSOFT_COMMON}/${OS}/${ARCH}/${OPENBOX_PRODUCT_NAME}/${OPENBOX_VERSION}"
OPENBOX_BUILD_LOG="${TEMP_INSTALL_LOCATION}/${OPENBOX_PRODUCT_NAME}-${OPENBOX_VERSION}/build.log"
FVWM_PRODUCT_NAME="fvwm"
FVWM_BUILD_DIR="${TEMP_INSTALL_LOCATION}/${FVWM_PRODUCT_NAME}-${FVWM_VERSION}" && mkdir -p ${FVWM_BUILD_DIR}
FVWM_PREFIX="${HPCSOFT_COMMON}/${OS}/${ARCH}/${FVWM_PRODUCT_NAME}/${FVWM_VERSION}"
FVWM_BUILD_LOG="${TEMP_INSTALL_LOCATION}/${FVWM_PRODUCT_NAME}-${FVWM_VERSION}/build.log"
FVWM3_PRODUCT_NAME="fvwm3"
FVWM3_BUILD_DIR="${TEMP_INSTALL_LOCATION}/${FVWM3_PRODUCT_NAME}-${FVWM3_VERSION}" && mkdir -p ${FVWM3_BUILD_DIR}
FVWM3_PREFIX="${HPCSOFT_COMMON}/${OS}/${ARCH}/${FVWM3_PRODUCT_NAME}/${FVWM3_VERSION}"
FVWM3_BUILD_LOG="${TEMP_INSTALL_LOCATION}/${FVWM3_PRODUCT_NAME}-${FVWM3_VERSION}/build.log"

# Build ice-wm
if [[ $REBUILD == "true" ]] ; then
   [ -d $ICEWM_PREFIX ] && rm -Rf $ICEWM_PREFIX
fi
module load gcc #ice requires newer stdc++
mkclean_change ${ICEWM_BUILD_DIR}
wget ${ICEWM_URL} || ( echo ${BASH_LINENO} ; exit 1 )
tar_name=$(ls)
dirname=$(tardir $tar_name)
tar xfz $tar_name && pushd $dirname
echo "**** Starting installation of ${ICEWM_PRODUCT_NAME}-${ICEWM_VERSION} on $OS for $ARCH" &>${ICEWM_BUILD_LOG}
date &>>${ICEWM_BUILD_LOG}
./autogen.sh &>>${ICEWM_BUILD_LOG} || ( echo ${BASH_LINENO} ; exit 1 )
./configure --prefix=${ICEWM_PREFIX} &>>${ICEWM_BUILD_LOG}
make -j &>>${ICEWM_BUILD_LOG} || ( echo ${BASH_LINENO} ; exit 1 )
make install &>>${ICEWM_BUILD_LOG} || ( echo ${BASH_LINENO} ; exit 1 )
fix_perms ${ICEWM_PREFIX} &>>${ICEWM_BUILD_LOG} || ( echo ${BASH_LINENO} ; exit 1 )
echo "**** Finished installation of ${ICEWM_PRODUCT_NAME}-${ICEWM_VERSION} on $OS for $ARCH" &>>${ICEWM_BUILD_LOG}
date &>>${ICEWM_BUILD_LOG}
module unload gcc
popd #pop back out of source
popd #revert pushd from mkclean_change

exit 
# Build berry
if [[ $REBUILD == "true" ]] ; then
   [ -d $BERRY_PREFIX ] && rm -Rf $BERRY_PREFIX
fi
mkclean_change ${BERRY_BUILD_DIR}
wget ${BERRY_URL} || ( echo ${BASH_LINENO} ; exit 1 )
tar_name=$(ls)
dirname=$(tardir $tar_name)
tar xfz $tar_name && pushd $dirname
echo "**** Starting installation of ${BERRY_PRODUCT_NAME}-${BERRY_VERSION} on $OS for $ARCH" &>${BERRY_BUILD_LOG}
date &>>${BERRY_BUILD_LOG}
./autogen.sh &>>${BERRY_BUILD_LOG} || (echo ${BASH_LINENO} ; exit 1 )
./configure --prefix=${BERRY_PREFIX} &>>${BERRY_BUILD_LOG}
make -j &>>${BERRY_BUILD_LOG} || ( echo ${BASH_LINENO} ; exit 1 )
make install &>>${BERRY_BUILD_LOG} || ( echo ${BASH_LINENO} ; exit 1 )
fix_perms ${BERRY_PREFIX} &>>${BERRY_BUILD_LOG} || ( echo ${BASH_LINENO} ; exit 1 )
echo "**** Finished installation of ${BERRY_PRODUCT_NAME}-${BERRY_VERSION} on $OS for $ARCH" &>>${BERRY_BUILD_LOG}
date &>>${BERRY_BUILD_LOG}
popd #pop back out of source
popd #revert pushd from mkclean_change

# Build openbox
if [[ $REBUILD == "true" ]] ; then
   [ -d $OPENBOX_PREFIX ] && rm -Rf $OPENBOX_PREFIX
fi
mkclean_change ${OPENBOX_BUILD_DIR}
wget ${OPENBOX_URL} || ( echo ${BASH_LINENO} ; exit 1)
tar_name=$(ls)
dirname=$(tardir $tar_name)
tar xfz $tar_name && pushd $dirname
echo "**** Starting installation of ${OPENBOX_PRODUCT_NAME}-${OPENBOX_VERSION} on $OS for $ARCH" &>${OPENBOX_BUILD_LOG}
date &>>${OPENBOX_BUILD_LOG}
./autogen.sh &>>${OPENBOX_BUILD_LOG} || ( echo ${BASH_LINENO} ; exit 1 )
./configure --prefix=${OPENBOX_PREFIX} &>>${OPENBOX_BUILD_LOG}
make -j &>>${OPENBOX_BUILD_LOG} || ( echo ${BASH_LINENO} ; exit 1 )
fix_perms ${OPENBOX_PREFIX} &>>${OPENBOX_BUILD_LOG} || ( echo ${BASH_LINENO} ; exit 1 )
echo "**** Finished installation of ${OPENBOX_PRODUCT_NAME}-${OPENBOX_VERSION} on $OS for $ARCH" &>>${OPENBOX_BUILD_LOG}
date &>>${OPENBOX_BUILD_LOG}
popd #pop back out of source
popd #revert pushd from mkclean_change

# Build FVWM
if [[ $REBUILD == "true" ]] ; then
   [ -d $FVWM_PREFIX ] && rm -Rf $FVWM_PREFIX
fi
mkclean_change ${FVWM_BUILD_DIR}
wget ${FVWM_URL} || ( echo ${BASH_LINENO} ; exit 1)
tar_name=$(ls)
dirname=$(tardir $tar_name)
tar xfz $tar_name && pushd $dirname
echo "**** Starting installation of ${FVWM_PRODUCT_NAME}-${FVWM_VERSION} on $OS for $ARCH" &>${FVWM_BUILD_LOG}
date &>>${FVWM_BUILD_LOG}
./autogen.sh &>>${FVWM_BUILD_LOG} || ( echo ${BASH_LINENO} ; exit 1 )
./configure --prefix=${FVWM_PREFIX} &>>${FVWM_BUILD_LOG}
make -j &>>${FVWM_BUILD_LOG} || ( echo ${BASH_LINENO} ; exit 1 )
fix_perms ${FVWM_PREFIX} &>>${FVWM_BUILD_LOG} || ( echo ${BASH_LINENO} ; exit 1 )
echo "**** Finished installation of ${FVWM_PRODUCT_NAME}-${FVWM_VERSION} on $OS for $ARCH" &>>${FVWM_BUILD_LOG}
date &>>${FVWM_BUILD_LOG}
popd #pop back out of source
popd #revert pushd from mkclean_change

# Build FVWM3
if [[ ${REBUILD} == "true" ]] ; then
   [ -d ${FVWM3_PREFIX} ] && rm -Rf ${FVWM3_PREFIX}
fi
mkclean_change ${FVWM3_BUILD_DIR}
wget ${FVWM3_URL} || ( echo ${BASH_LINENO} ; exit 1)
tar_name=$(ls)
dirname=$(tardir $tar_name)
tar xfz $tar_name && pushd $dirname
echo "**** Starting installation of ${FVWM3_PRODUCT_NAME}-${FVWM3_VERSION} on $OS for $ARCH" &>${FVWM3_BUILD_LOG}
date &>>${FVWM3_BUILD_LOG}
./autogen.sh &>>${FVWM3_BUILD_LOG} || ( echo ${BASH_LINENO} ; exit 1 )
./configure --prefix=${FVWM3_PREFIX} &>>${FVWM3_BUILD_LOG}
make -j &>>${FVWM3_BUILD_LOG} || ( echo ${BASH_LINENO} ; exit 1 )
fix_perms ${FVWM3_PREFIX} &>>${FVWM3_BUILD_LOG} || ( echo ${BASH_LINENO} ; exit 1 )
echo "**** Finished installation of ${FVWM3_PRODUCT_NAME}-${FVWM3_VERSION} on $OS for $ARCH" &>>${FVWM3_BUILD_LOG}
date &>>${FVWM3_BUILD_LOG}
popd #pop back out of source
popd #revert pushd from mkclean_change
exit 




