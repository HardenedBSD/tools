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

echo "for installer images and distfiles see http://installer.hardenedbsd.org"
