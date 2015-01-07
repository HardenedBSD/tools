#!/usr/local/bin/zsh

target=""
targetdir="amd64"
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
                    i386)
                        target="TARGET=i386 TARGET_ARCH=i386"
                        targetdir="i386"
                        ;;
                    beaglebone)
                        target="TARGET=arm TARGET_ARCH=armv6"
                        targetdir="beaglebone"
                        kernel="BEAGLEBONE-HARDENEDBSD"
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
sudo make -s release KERNCONF=${kernel} NOPORTS=1 ${target}

_TAR_DIR="/jenkins/releases/${JOB_NAME}/build-${BUILD_NUMBER}/"
_ISO_DIR="${_TAR_DIR}/ISO-IMAGES"

if [ ! -d ${_TAR_DIR} ]; then
    mkdir -p ${_TAR_DIR}
fi

if [ ! -d ${_ISO_DIR} ]; then
    mkdir -p ${_ISO_DIR}
fi

_INSTALLER_PREFIX="HardenedBSD-11-CURRENT_hardenedbsd-stable_master-"

# iso and img file - aka installers
for file in $(find /usr/obj/jenkins/workspace/${JOB_NAME}/release -maxdepth 1 -name '*.iso' -o -name '*.img'); do
    _dst_file="${_ISO_DIR}/${_INSTALLER_PREFIX}${file##*/}"
    cp ${file} ${_dst_file}
    sha256 ${_dst_file} >> ${_ISO_DIR}/CHECKSUMS.SHA256
    md5 ${_dst_file} >> ${_ISO_DIR}/CHECKSUMS.MD5
done

# archives - aka part of installers
for file in $(find /usr/obj/jenkins/workspace/${JOB_NAME}/release -maxdepth 1 -name '*.txz'); do
    cp ${file} ${_TAR_DIR}
    sha256 ${file} >> ${_TAR_DIR}/CHECKSUMS.SHA256
    md5 ${file} >> ${_TAR_DIR}/CHECKSUMS.MD5
done

ln -fhs ${_TAR_DIR} "/jenkins/releases/${JOB_NAME}-LATEST"
