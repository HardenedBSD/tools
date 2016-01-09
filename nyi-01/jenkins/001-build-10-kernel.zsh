#!/usr/local/bin/zsh

njobs=16
objdir="/jenkins/objdir/${JOB_NAME}"

target="SHOULD_FAIL"
targetdir=""
kernel="HARDENEDBSD"

export __MAKE_CONF="/dev/null"
export __SRC_CONF="/dev/null"
export MAKE_CONF="/dev/null"
export SRC_CONF="/dev/null"

while getopts 'j:t:' o; do
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
                        ;;
                    defaut)
                        echo "Invalid target!"
                        exit 1
                        ;;
                esac
            fi
            ;;
        j)
            jobs=${OPTARG}
            ;;
    esac
done


sudo -u root -g wheel make clean cleandir
sudo -u root -g wheel make -C release clean cleandir

sudo -u root -g wheel make -j${njobs} kernel-toolchain KERNCONF=${kernel} ${target}
sudo -u root -g wheel make -j${njobs} buildkernel KERNCONF=${kernel} ${target}
