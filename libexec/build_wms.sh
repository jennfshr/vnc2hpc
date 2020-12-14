#!/bin/bash
source /etc/profile
#This is a simple automation for building out the non-system window manager installations

get_package() {
   _STAGE_DIR="${1}"
   _URL="${2}"
   mk_change ${_STAGE_DIR}
   wget ${_URL} &>/dev/null || echo "FAILURE AT: ${LINENO}"
   echo "Downloaded ${_URL} to ${_STAGE_DIR}"
   popd &>/dev/null
}

grab () {
   local _URL="${1}"
   local _METHOD="${2}"
   echo "Grabbing ${_URL} using ${_METHOD} from ${DOWNLOAD_DIR}"
   if [[ "${_METHOD}" == "download" ]] ; then
      wget "${_URL}"
   elif [[ "${_METHOD}" == "copy" ]] ; then
      find ${DOWNLOAD_DIR} -name "${_URL//*\/}" -exec cp '{}' . \;
   fi
}

fix_perms () {
   local _PREFIX_PATH="${1}"
   local _group="${2}"
   chgrp -Rf ${_group} ${_PREFIX_PATH%\/*} || exit 2
   chmod -Rf g+wrX,a+rX ${_PREFIX_PATH%\/*} || exit 2
}

mk_change () {
   local _STAGE_DIR="${1}"
   mkdir -p ${_STAGE_DIR}
   pushd ${_STAGE_DIR} &>/dev/null
}

mkclean_change () {
   local _BUILD_DIR=$1
   rm -Rf ${_BUILD_DIR} && mkdir -p ${_BUILD_DIR}
   pushd ${_BUILD_DIR} &>/dev/null
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
   local _method="${7}"
   if [[ "${REBUILD}x" != "x" ]] ; then
      rm -Rf $_prefix
   else
      if [[ -d ${_prefix} ]] ; then
         echo "Installation at $_prefix already exists- to rebuild, pass the -r flag to the script"
         exit 0
      else
         echo "Installation at ${_prefix} doesn't exist- will build it"
      fi
   fi
   echo "**** Starting installation of ${_product_name}-${_version} on $OS for $ARCH $(date)" | tee -a ${_build_log}
   module load gcc && CC=gcc
   mkclean_change ${_build_dir}
   grab ${_url} ${_method} || echo "FAILURE AT: ${LINENO}"
   local _tar_name=$(ls)
   local _dirname=$(tardir $_tar_name)
   tar xfz ${_tar_name} && pushd ${_dirname} &> /dev/null && pwd &>> ${_build_log}
   [ -x ./bootstrap ] && ./bootstrap &>> ${_build_log} || echo "No boostrap for ${_product_name} at ${LINENO}" &>> ${_build_log}
   [ -x ./autogen.sh ] && ./autogen.sh &>> ${_build_log} || echo "No autogen for ${_product_name} at ${LINENO}" &>> ${_build_log}
   [ -x ./configure ] &&  ./configure --prefix=${_prefix} &>> ${_build_log} || echo "No configure for ${_product_name} at ${LINENO}" &>> ${_build_log}
   make -j CC=$CC PREFIX=${_prefix} install &>> ${_build_log} || echo "Make failed for ${_product_name} at ${LINENO}" &>> ${_build_log}
   if [[ "${GROUP}x" != "x" ]] ; then fix_perms ${_prefix} ${GROUP} &>> ${_build_log} ; fi || echo "FAILURE AT: ${LINENO}" &>> ${_build_log}
   ( [ -d ${_prefix} ] && echo "**** Finished installation of ${_product_name}-${_version} at ${_prefix} $(date)" | tee -a ${_build_log} ) || echo "****  Failed installation of ${_product_name}-${_version} at ${_prefix} $(date)" | tee -a ${_build_log}
   module unload gcc
   popd &>/dev/null #pop back out of source
   popd &>/dev/null #revert pushd from mkclean_change
}

usage () {
   echo "${0/*\/} v${VERSION}

          usage: build-wms.sh
                            [-d|--debug]                                        (optional)
                            [-D|--download-dir]					(optional) Default: wget <package>
                            [-s|--stage]					(optional) Stages downloads directory: -s </fullpath/to/dir>
			    [-w|--wm <icewm|berry|fvwm|fvwm3|openbox>]          (required) For multiple: -w <wm> -w <wm>
                            [-p|--prefix <string>]                     	        (optional) Default: ${TOP_PREFIX}
			    [-h|--help]
                            [-r|--rebuild]					(optional) Default: FALSE
                            [-g|--group]					(optional)

          Questions?        <vnc2hpc@lanl.gov>
          Need Help?        https://git.lanl.gov/hpcsoft/vnc2hpc/-/blob/${VERSION}/README.md"
}

# Some global variables
TOP_PREFIX="/usr/projects/hpcsoft"
if /usr/projects/hpcsoft/utilities/bin/sys_os &>/dev/null ; then
   OS=$(/usr/projects/hpcsoft/utilities/bin/sys_os)
else
   OS=$(uname -o | sed 's/\//_/g')
fi

if /usr/projects/hpcsoft/utilities/bin/sys_arch &>/dev/null ; then
   ARCH=$(/usr/projects/hpcsoft/utilities/bin/sys_arch)
else
   ARCH=$(uname -p)
fi

VERSION="0.0.5"

# Parse positional parameters passed to script
#for arg in "$@"; do
#    shift
#    case "$arg" in
#        *debug)       set -- "$@" "-d"   ;;
#        *download*)   set -- "$@" "-D"   ;;
#        *help)        set -- "$@" "-h"   ;;
#        *wm)          set -- "$@" "-w"   ;;
#        *prefix*)     set -- "$@" "-p"   ;;
#        *)            set -- "$@" "$arg" ;;
#    esac
#done

OPTIND=1

while getopts "rdg:D:p:w:hs:-" opt ; do
    case "${opt}" in
        d)  DEBUG="true"					;;
        g)  GROUP="${OPTARG}"					;;
        r)  REBUILD="true"					;;
        h)  usage && exit 0					;;
        w)  WINDOWMANAGER=( "${OPTARG}" "${WINDOWMANAGER[@]}" )	;;
        p)  TOP_PREFIX="${OPTARG}"				;;
        D)  DOWNLOAD_DIR="${OPTARG}"				;;
        s)  [ -x "${OPTARG%\/*}" ] && STAGE_DIR="${OPTARG}"     ;;
        -)  continue						;;
    esac
done

INSTALL_PATH=${TOP_PREFIX}/${OS}/common/${ARCH}

# temp build dir
[[ -d ${TEMP_INSTALL_LOCATION} ]] && rm -Rf ${TEMP_INSTALL_LOCATION}
mkdir -p ${TEMP_INSTALL_LOCATION:="/tmp/vnc2hpc-deps_${USER}"}

# setup proxies
export HTTP_PROXY=http://proxyout.lanl.gov:8080
export HTTPS_PROXY=http://proxyout.lanl.gov:8080
export http_proxy=http://proxyout.lanl.gov:8080
export https_proxy=http://proxyout.lanl.gov:8080

# Source package URLs
ICEWM_URL="https://github.com/ice-wm/icewm/archive/1.9.2.tar.gz"
BERRY_URL="https://github.com/JLErvin/berry/archive/0.1.7.tar.gz"
OPENBOX_URL="https://github.com/Mikachu/openbox/archive/release-3.6.1.tar.gz"
FVWM_URL="https://github.com/fvwmorg/fvwm/archive/2.6.9.tar.gz"
LIBBSON_URL="https://github.com/mongodb/libbson/releases/download/1.9.3/libbson-1.9.3.tar.gz"
FVWM3_URL="https://github.com/fvwmorg/fvwm3/archive/1.0.1.tar.gz"

##TODO Fix this
#if [[ "$DEBUG" =~ [Tt]rue ]] ; then 
#   DBG="|& tee -a"
#else
#   DBG="&>>"
#fi

# Test STAGE_DIR and use it
if [[ "${STAGE_DIR}x" != x ]] ; then
   mkdir -p ${STAGE_DIR}
fi

if [[ "${DOWNLOAD_DIR}x" == x ]] ; then
#fetch packages from the indicated directory
   METHOD="download"
else
   METHOD="copy"
fi

module purge &>/dev/null

for wm in "${WINDOWMANAGER[@]}"; do
   case "$wm" in
      icewm)
         # WMs to build: icewm, berry, openbox, fvwm
         ICEWM_VERSION="1.9.2"
         ICEWM_PRODUCT_NAME="icewm"
         if [[ "${STAGE_DIR}x" != x ]] ; then
            get_package ${STAGE_DIR} ${ICEWM_URL}
         else
            ICEWM_BUILD_DIR="${TEMP_INSTALL_LOCATION}/${ICEWM_PRODUCT_NAME}-${ICEWM_VERSION}"
            ICEWM_PREFIX="${INSTALL_PATH}/${ICEWM_PRODUCT_NAME}/${ICEWM_VERSION}"
            ICEWM_BUILD_LOG="${TEMP_INSTALL_LOCATION}/${ICEWM_PRODUCT_NAME}-${ICEWM_VERSION}/build.log"
            build ${ICEWM_URL} ${ICEWM_VERSION} ${ICEWM_PRODUCT_NAME} ${ICEWM_BUILD_DIR} ${ICEWM_PREFIX} ${ICEWM_BUILD_LOG} ${METHOD}
            if [[ "${DEBUG}x" != x ]] ; then cat ${ICEWM_BUILD_LOG} ; fi
         fi
      ;;
      berry)
         BERRY_VERSION="0.1.7"
         BERRY_PRODUCT_NAME="berry"
         if [[ "${STAGE_DIR}x" != x ]] ; then
            get_package ${STAGE_DIR} ${BERRY_URL}
         else
            BERRY_BUILD_DIR="${TEMP_INSTALL_LOCATION}/${BERRY_PRODUCT_NAME}-${BERRY_VERSION}" && mkdir -p ${BERRY_BUILD_DIR}
            BERRY_PREFIX="${INSTALL_PATH}/${BERRY_PRODUCT_NAME}/${BERRY_VERSION}"
            BERRY_BUILD_LOG="${TEMP_INSTALL_LOCATION}/${BERRY_PRODUCT_NAME}-${BERRY_VERSION}/build.log"
            build ${BERRY_URL} ${BERRY_VERSION} ${BERRY_PRODUCT_NAME} ${BERRY_BUILD_DIR} ${BERRY_PREFIX} ${BERRY_BUILD_LOG} ${METHOD}
            if [[ "${DEBUG}x" != x ]] ; then cat ${BERRY_BUILD_LOG} ; fi
         fi
      ;;
      openbox)
         OPENBOX_VERSION="3.6.1"
         OPENBOX_PRODUCT_NAME="openbox"
         if [[ "${STAGE_DIR}x" != x ]] ; then
            get_package ${STAGE_DIR} ${OPENBOX_URL}
         else
            OPENBOX_BUILD_DIR="${TEMP_INSTALL_LOCATION}/${OPENBOX_PRODUCT_NAME}-${OPENBOX_VERSION}" && mkdir -p ${OPENBOX_BUILD_DIR}
            OPENBOX_PREFIX="${INSTALL_PATH}/${OPENBOX_PRODUCT_NAME}/${OPENBOX_VERSION}"
            OPENBOX_BUILD_LOG="${TEMP_INSTALL_LOCATION}/${OPENBOX_PRODUCT_NAME}-${OPENBOX_VERSION}/build.log"
            build ${OPENBOX_URL} ${OPENBOX_VERSION} ${OPENBOX_PRODUCT_NAME} ${OPENBOX_BUILD_DIR} ${OPENBOX_PREFIX} ${OPENBOX_BUILD_LOG} ${METHOD}
            if [[ "${DEBUG}x" != x ]] ; then cat ${OPENBOX_BUILD_LOG} ; fi
         fi 
      ;;
      fvwm)
         FVWM_VERSION="2.6.9"
         FVWM_PRODUCT_NAME="fvwm"
         if [[ "${STAGE_DIR}x" != x ]] ; then
            get_package ${STAGE_DIR} ${FVWM_URL}
         else
            FVWM_BUILD_DIR="${TEMP_INSTALL_LOCATION}/${FVWM_PRODUCT_NAME}-${FVWM_VERSION}" && mkdir -p ${FVWM_BUILD_DIR}
            FVWM_PREFIX="${INSTALL_PATH}/${FVWM_PRODUCT_NAME}/${FVWM_VERSION}"
            FVWM_BUILD_LOG="${TEMP_INSTALL_LOCATION}/${FVWM_PRODUCT_NAME}-${FVWM_VERSION}/build.log"
            build ${FVWM_URL} ${FVWM_VERSION} ${FVWM_PRODUCT_NAME} ${FVWM_BUILD_DIR} ${FVWM_PREFIX} ${FVWM_BUILD_LOG} ${METHOD}
            if [[ "${DEBUG}x" != x ]] ; then cat ${FVWM_BUILD_LOG} ; fi
         fi
      ;;
      ##TODO <jgreen> needs newer libbson - this doesn't work
      fvwm3)
         set -x 
         #module load gcc
         LIBBSON_VERSION="1.9.3"
         LIBBSON_PRODUCT_NAME="libbson"
         LIBBSON_BUILD_DIR="${TEMP_INSTALL_LOCATION}/${LIBBSON_PRODUCT_NAME}-${LIBBSON_VERSION}" && mkdir -p ${LIBBSON_BUILD_DIR}
         LIBBSON_PREFIX="${INSTALL_PATH}/${LIBBSON_PRODUCT_NAME}/${LIBBSON_VERSION}"
         LIBBSON_BUILD_LOG="${TEMP_INSTALL_LOCATION}/${LIBBSON_PRODUCT_NAME}-${LIBBSON_VERSION}/build.log"
         build ${LIBBSON_URL} ${LIBBSON_VERSION} ${LIBBSON_PRODUCT_NAME} ${LIBBSON_BUILD_DIR} ${LIBBSON_PREFIX} ${LIBBSON_BUILD_LOG} ${METHOD}
         FVWM3_VERSION="1.0.1"
         FVWM3_PRODUCT_NAME="fvwm3"
         FVWM3_BUILD_DIR="${TEMP_INSTALL_LOCATION}/${FVWM3_PRODUCT_NAME}-${FVWM3_VERSION}" && mkdir -p ${FVWM3_BUILD_DIR}
         FVWM3_PREFIX="${INSTALL_PATH}/${FVWM3_PRODUCT_NAME}/${FVWM3_VERSION}"
         FVWM3_BUILD_LOG="${TEMP_INSTALL_LOCATION}/${FVWM3_PRODUCT_NAME}-${FVWM3_VERSION}/build.log"
         build ${FVWM3_URL} ${FVWM3_VERSION} ${FVWM3_PRODUCT_NAME} ${FVWM3_BUILD_DIR} ${FVWM3_PREFIX} ${FVWM3_BUILD_LOG} ${METHOD}
         if [[ "${DEBUG}x" != x ]] ; then cat ${FVWM3_BUILD_LOG} ; fi
         #[ -x ./configure ] && libbson_CFLAGS="-I${LIBBSON_PREFIX}/include/${LIBBSON_PRODUCT_NAME}-1.0" libbson_LDFLAGS="-L${LIBBSON_PREFIX}/lib/ -lbson" LDFLAGS="-L${LIBBSON_PREFIX}/lib -lbson-1.0" ./configure --prefix=${FVWM3_PREFIX} |& tee -a ${FVWM3_BUILD_LOG} || echo "FAILURE AT: ${LINENO}"
      ;;
   esac
done

exit
