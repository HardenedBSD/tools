#!/usr/local/bin/zsh

njobs=32
objdir="/jenkins/objdir/${JOB_NAME}"

target=""
targetdir="amd64"
kernel="HARDENEDBSD"

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
                        target="TARGET=arm TARGET_ARCH=i386"
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

make -j${njobs} buildworld ${target}
make -j${njobs} buildkernel KERNCONF=${kernel} ${target}
