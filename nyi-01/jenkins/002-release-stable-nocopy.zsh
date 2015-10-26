#!/bin/sh

target="SHOULD_FAIL"
targetdir=""
kernel="HARDENEDBSD"
export __MAKE_CONF="/dev/null"
export __SRC_CONF="/dev/null"
export MAKE_CONF="/dev/null"
export SRC_CONF="/dev/null"

_L_JOB_NAME=`echo ${JOB_NAME} | tr '[:upper:]' '[:lower:]'`

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
			kernel="GENERIC-ASLR"
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
sudo make clean ${target}
sudo make real-release KERNCONF=${kernel} NOPORTS=1 ${target}

echo "for installer images and distfiles see http://installer.hardenedbsd.org"
