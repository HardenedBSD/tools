#!/bin/sh

target="SHOULD_FAIL"
targetdir=""
kernel="HARDENEDBSD"
date="`date "+%Y%m%d%H%M"`"
export __MAKE_CONF="/dev/null"
export __SRC_CONF="/dev/null"
export MAKE_CONF="/dev/null"
export SRC_CONF="/dev/null"

#_L_JOB_NAME=`echo ${JOB_NAME} | tr '[:upper:]' '[:lower:]'`
_INSTALLER_PREFIX="${JOB_NAME}-s${date}-"

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
sudo -u root -g wheel make -s clean ${target}
sudo -u root -g wheel make -s real-release KERNCONF=${kernel} NOPORTS=1 ${target}

_TAR_DIR="/jenkins/releases/${JOB_NAME}/build-${BUILD_NUMBER}/"
_ISO_DIR="${_TAR_DIR}/ISO-IMAGES"

if [ ! -d ${_TAR_DIR} ]; then
    mkdir -p ${_TAR_DIR}
fi

if [ ! -d ${_ISO_DIR} ]; then
    mkdir -p ${_ISO_DIR}
fi

# iso and img file - aka installers
for file in $(find /usr/obj/jenkins/workspace/${JOB_NAME}/release -maxdepth 1 -name '*.iso' -o -name '*.img'); do
    _dst_file="${_ISO_DIR}/${_INSTALLER_PREFIX}${file##*/}"
    cp ${file} ${_dst_file}
    sha256 ${_dst_file} >> ${_ISO_DIR}/CHECKSUMS.SHA256
    sha512 ${_dst_file} >> ${_ISO_DIR}/CHECKSUMS.SHA512
    gpg --sign -a --detach -u 819B11A26FFD188D -o ${_ISO_DIR}/$(basename ${_dst_file}).asc ${_dst_file}
done

# archives - aka part of installers
for file in $(find /usr/obj/jenkins/workspace/${JOB_NAME}/release -maxdepth 1 -name '*.txz'); do
    cp ${file} ${_TAR_DIR}
    sha256 ${file} >> ${_TAR_DIR}/CHECKSUMS.SHA256
    sha512 ${file} >> ${_TAR_DIR}/CHECKSUMS.SHA512
    gpg --sign -a --detach -u 819B11A26FFD188D -o ${_TAR_DIR}/$(basename ${file}).asc ${file}
done

ln -fhs ${_TAR_DIR} "/jenkins/releases/${JOB_NAME}-LATEST"
