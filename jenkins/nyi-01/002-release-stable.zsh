#!/bin/sh

target="SHOULD_FAIL"
targetdir=""
kernel="HARDENEDBSD"
export __MAKE_CONF="/dev/null"
export __SRC_CONF="/dev/null"
export MAKE_CONF="/dev/null"
export SRC_CONF="/dev/null"

while getopts 't:' o; do
    case "${o}" in
        t)
            if [ ! "${OPTARG}" = "${target}" ]; then
                case "${OPTARG}" in
		    amd64)
			target="TARGET=amd64 TARGET_ARCH=amd64"
			targetdir="amd64"
			;;
                    i386)
                        target="TARGET=i386 TARGET_ARCH=i386"
                        targetdir="i386"
                        ;;
                    beaglebone)
                        target="TARGET=arm TARGET_ARCH=armv6"
                        targetdir="beaglebone"
                        kernel="BEAGLEBONE-HARDENEDBSD"
                        ;;
		    upstream-amd64)
			target="TARGET=amd64 TARGET_ARCH=amd64"
			targetdir="amd64"
			kernel="GENERIC"
			_INSTALLER_PREFIX="FreeBSD-11-CURRENT_${_L_JOB_NAME}-"
			;;
		    opbsd-fortify-amd64)
			target="TARGET=amd64 TARGET_ARCH=amd64"
			targetdir="amd64"
			kernel="GENERIC"
			_INSTALLER_PREFIX="opBSD-11-CURRENT_${_L_JOB_NAME}-"
			;;
		    upstream-aslr-amd64)
			target="TARGET=amd64 TARGET_ARCH=amd64"
			targetdir="amd64"
			kernel="GENERIC"
			_INSTALLER_PREFIX="FreeBSD-11-CURRENT_${_L_JOB_NAME}-"
			;;
                    defaut)
                        echo "Invalid target!"
                        exit 1
                        ;;
                esac
            fi
            ;;
    esac
done

cd release
sudo make -s clean ${target}
sudo make -s real-release KERNCONF=${kernel} NOPORTS=1 ${target}

_TAR_DIR="/jenkins/releases/${JOB_NAME}/build-${BUILD_NUMBER}/"
_ISO_DIR="${_TAR_DIR}/ISO-IMAGES"

if [ ! -d ${_TAR_DIR} ]; then
    mkdir -p ${_TAR_DIR}
fi

if [ ! -d ${_ISO_DIR} ]; then
    mkdir -p ${_ISO_DIR}
fi

_L_JOB_NAME=`echo ${JOB_NAME} | tr '[:upper:]' '[:lower:]'`
if [ -z ${_INSTALLER_PREFIX} ]; then
	_INSTALLER_PREFIX="HardenedBSD-11-CURRENT_${_L_JOB_NAME}-"
fi

# iso and img file - aka installers
for file in $(find /usr/obj/jenkins/workspace/${JOB_NAME}/release -maxdepth 1 -name '*.iso' -o -name '*.img'); do
    _dst_file="${_ISO_DIR}/${_INSTALLER_PREFIX}${file##*/}"
    cp ${file} ${_dst_file}
    sha256 ${_dst_file} >> ${_ISO_DIR}/CHECKSUMS.SHA256
    md5 ${_dst_file} >> ${_ISO_DIR}/CHECKSUMS.MD5
    gpg --sign -a --detach -u 819B11A26FFD188D -o ${_ISO_DIR}/$(basename ${_dst_file}).asc ${_dst_file}
done

# archives - aka part of installers
for file in $(find /usr/obj/jenkins/workspace/${JOB_NAME}/release -maxdepth 1 -name '*.txz'); do
    cp ${file} ${_TAR_DIR}
    sha256 ${file} >> ${_TAR_DIR}/CHECKSUMS.SHA256
    md5 ${file} >> ${_TAR_DIR}/CHECKSUMS.MD5
    gpg --sign -a --detach -u 819B11A26FFD188D -o ${_TAR_DIR}/$(basename ${file}).asc ${file}
done

ln -fhs ${_TAR_DIR} "/jenkins/releases/${JOB_NAME}-LATEST"
