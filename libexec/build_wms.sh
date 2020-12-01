#!/bin/bash
REBUILD="true"
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

build () {
   local _url="${1}"
   local _version="${2}"
   local _product_name="${3}"
   local _build_dir="${4}"
   local _prefix="${5}"
   local _build_log="${6}"
   if [[ $REBUILD == "true" ]] ; then
            [ -d $_prefix ] && rm -Rf $_prefix
   fi
   module load gcc #ice requires newer stdc++
   mkclean_change ${_build_dir}
   wget ${_url} || echo "FAILURE AT: ${LINENO}"
   local _tar_name=$(ls)
   local _dirname=$(tardir $_tar_name)
   echo "**** Starting installation of ${_product_name}-${_version} on $OS for $ARCH" &>${_build_log}
   tar xfz ${_tar_name} && pushd ${_dirname} && pwd |& tee -a ${_build_log}
   date |& tee -a ${_build_log}
   [ -x ./bootstrap ] && ./bootstrap |& tee -a ${_build_log} || echo "No boostrap for ${_product_name} at ${LINENO}" |& tee -a ${_build_log}
   [ -x ./autogen.sh ] && ./autogen.sh |& tee -a ${_build_log} || echo "No autogen for ${_product_name} at ${LINENO}" |& tee -a ${_build_log}
   [ -x ./configure ] && ./configure --prefix=${_prefix} |& tee -a ${_build_log} || echo "No configure for ${_product_name} at ${LINENO}" |& tee -a ${_build_log}
   make -j PREFIX=${_prefix} install |& tee -a ${_build_log} || echo "Make failed for ${_product_name} at ${LINENO}" |& tee -a ${_build_log}
   fix_perms ${_prefix} |& tee -a ${_build_log} || echo "FAILURE AT: ${LINENO}" |& tee -a ${_build_log}
   ( [ -d ${_prefix} ] && echo "**** Finished installation of ${_product_name}-${_version} at ${_prefix}" |& tee -a ${_build_log} ) || echo "****  Failed installation of ${_product_name}-${_version} at ${_prefix}"
   date |& tee -a ${_build_log}
   module unload gcc
   popd #pop back out of source
   popd #revert pushd from mkclean_change
}

# Some global variables
HPCSOFT_COMMON="/usr/projects/hpcsoft/common"
OS=$(/usr/projects/hpcsoft/utilities/bin/sys_os)
ARCH=$(/usr/projects/hpcsoft/utilities/bin/sys_arch)
INSTALL_PATH=${HPCSOFT_COMMON}/${OS}/${ARCH}

# temp build dir
mkdir -p ${TEMP_INSTALL_LOCATION:="/tmp/vnc2hpc-deps"}

# setup proxies
export HTTP_PROXY=http://proxyout.lanl.gov:8080
export HTTPS_PROXY=http://proxyout.lanl.gov:8080
export http_proxy=http://proxyout.lanl.gov:8080
export https_proxy=http://proxyout.lanl.gov:8080

for wm in ${@}; do
   case "$wm" in
      icewm)
         # WMs to build: icewm, berry, openbox, fvwm
         ICEWM_URL="https://github.com/ice-wm/icewm/archive/1.9.2.tar.gz"
         ICEWM_VERSION="1.9.2"
         ICEWM_PRODUCT_NAME="icewm"
         ICEWM_BUILD_DIR="${TEMP_INSTALL_LOCATION}/${ICEWM_PRODUCT_NAME}-${ICEWM_VERSION}"
         ICEWM_PREFIX="${INSTALL_PATH}/${ICEWM_PRODUCT_NAME}/${ICEWM_VERSION}"
         ICEWM_BUILD_LOG="${TEMP_INSTALL_LOCATION}/${ICEWM_PRODUCT_NAME}-${ICEWM_VERSION}/build.log"
         build ${ICEWM_URL} ${ICEWM_VERSION} ${ICEWM_PRODUCT_NAME} ${ICEWM_BUILD_DIR} ${ICEWM_PREFIX} ${ICEWM_BUILD_LOG}
      ;;
      berry)
         BERRY_URL="https://github.com/JLErvin/berry/archive/0.1.7.tar.gz"
         BERRY_VERSION="0.1.7"
         BERRY_PRODUCT_NAME="berry"
         BERRY_BUILD_DIR="${TEMP_INSTALL_LOCATION}/${BERRY_PRODUCT_NAME}-${BERRY_VERSION}" && mkdir -p ${BERRY_BUILD_DIR}
         BERRY_PREFIX="${INSTALL_PATH}/${BERRY_PRODUCT_NAME}/${BERRY_VERSION}"
         BERRY_BUILD_LOG="${TEMP_INSTALL_LOCATION}/${BERRY_PRODUCT_NAME}-${BERRY_VERSION}/build.log"
         build ${BERRY_URL} ${BERRY_VERSION} ${BERRY_PRODUCT_NAME} ${BERRY_BUILD_DIR} ${BERRY_PREFIX} ${BERRY_BUILD_LOG}
      ;;
      openbox)
         OPENBOX_URL="https://github.com/Mikachu/openbox/archive/release-3.6.1.tar.gz"
         OPENBOX_VERSION="3.6.1"
         OPENBOX_PRODUCT_NAME="openbox"
         OPENBOX_BUILD_DIR="${TEMP_INSTALL_LOCATION}/${OPENBOX_PRODUCT_NAME}-${OPENBOX_VERSION}" && mkdir -p ${OPENBOX_BUILD_DIR}
         OPENBOX_PREFIX="${INSTALL_PATH}/${OPENBOX_PRODUCT_NAME}/${OPENBOX_VERSION}"
         OPENBOX_BUILD_LOG="${TEMP_INSTALL_LOCATION}/${OPENBOX_PRODUCT_NAME}-${OPENBOX_VERSION}/build.log"
         build ${OPENBOX_URL} ${OPENBOX_VERSION} ${OPENBOX_PRODUCT_NAME} ${OPENBOX_BUILD_DIR} ${OPENBOX_PREFIX} ${OPENBOX_BUILD_LOG}
      ;;
      fvwm)
         FVWM_URL="https://github.com/fvwmorg/fvwm/archive/2.6.9.tar.gz"
         FVWM_VERSION="2.6.9"
         FVWM_PRODUCT_NAME="fvwm"
         FVWM_BUILD_DIR="${TEMP_INSTALL_LOCATION}/${FVWM_PRODUCT_NAME}-${FVWM_VERSION}" && mkdir -p ${FVWM_BUILD_DIR}
         FVWM_PREFIX="${INSTALL_PATH}/${FVWM_PRODUCT_NAME}/${FVWM_VERSION}"
         FVWM_BUILD_LOG="${TEMP_INSTALL_LOCATION}/${FVWM_PRODUCT_NAME}-${FVWM_VERSION}/build.log"
         build ${FVWM_URL} ${FVWM_VERSION} ${FVWM_PRODUCT_NAME} ${FVWM_BUILD_DIR} ${FVWM_PREFIX} ${FVWM_BUILD_LOG}
      ;;
      ##TODO <jgreen> needs newer libbson - this doesn't work
      fvwm3)
         set -x 
         #module load gcc
         LIBBSON_URL="https://github.com/mongodb/libbson/releases/download/1.9.3/libbson-1.9.3.tar.gz"
         LIBBSON_VERSION="1.9.3"
         LIBBSON_PRODUCT_NAME="libbson"
         LIBBSON_BUILD_DIR="${TEMP_INSTALL_LOCATION}/${LIBBSON_PRODUCT_NAME}-${LIBBSON_VERSION}" && mkdir -p ${LIBBSON_BUILD_DIR}
         LIBBSON_PREFIX="${INSTALL_PATH}/${LIBBSON_PRODUCT_NAME}/${LIBBSON_VERSION}"
         LIBBSON_BUILD_LOG="${TEMP_INSTALL_LOCATION}/${LIBBSON_PRODUCT_NAME}-${LIBBSON_VERSION}/build.log"
         build ${LIBBSON_URL} ${LIBBSON_VERSION} ${LIBBSON_PRODUCT_NAME} ${LIBBSON_BUILD_DIR} ${LIBBSON_PREFIX} ${LIBBSON_BUILD_LOG}
         FVWM3_URL="https://github.com/fvwmorg/fvwm3/archive/1.0.1.tar.gz"
         FVWM3_VERSION="1.0.1"
         FVWM3_PRODUCT_NAME="fvwm3"
         FVWM3_BUILD_DIR="${TEMP_INSTALL_LOCATION}/${FVWM3_PRODUCT_NAME}-${FVWM3_VERSION}" && mkdir -p ${FVWM3_BUILD_DIR}
         FVWM3_PREFIX="${INSTALL_PATH}/${FVWM3_PRODUCT_NAME}/${FVWM3_VERSION}"
         FVWM3_BUILD_LOG="${TEMP_INSTALL_LOCATION}/${FVWM3_PRODUCT_NAME}-${FVWM3_VERSION}/build.log"
         build ${FVWM3_URL} ${FVWM3_VERSION} ${FVWM3_PRODUCT_NAME} ${FVWM3_BUILD_DIR} ${FVWM3_PREFIX} ${FVWM3_BUILD_LOG}
         #[ -x ./configure ] && libbson_CFLAGS="-I${LIBBSON_PREFIX}/include/${LIBBSON_PRODUCT_NAME}-1.0" libbson_LDFLAGS="-L${LIBBSON_PREFIX}/lib/ -lbson" LDFLAGS="-L${LIBBSON_PREFIX}/lib -lbson-1.0" ./configure --prefix=${FVWM3_PREFIX} |& tee -a ${FVWM3_BUILD_LOG} || echo "FAILURE AT: ${LINENO}"
      ;;
   esac
done

exit
