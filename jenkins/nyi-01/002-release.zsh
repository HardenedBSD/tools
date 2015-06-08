#!/usr/local/bin/zsh

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
sudo make -s real-release KERNCONF=${kernel} NOPORTS=1 ${target}

if [ ! -d /jenkins/releases/${JOB_NAME}/${BUILD_NUMBER}/${targetdir} ]; then
    mkdir -p /jenkins/releases/${JOB_NAME}/${BUILD_NUMBER}/${targetdir}
fi

for file in $(find /usr/obj/jenkins/workspace/${JOB_NAME}/release -maxdepth 1 -name '*.iso' -o -name '*.txz' -o -name '*.img'); do
    cp ${file} /jenkins/releases/${JOB_NAME}/${BUILD_NUMBER}/${targetdir}
    if [ "${file##*\.}" = "iso" ]; then
        sha256 ${file} >> /jenkins/releases/${JOB_NAME}/${BUILD_NUMBER}/${targetdir}/HASHES
    fi

    gpg --sign -a --detach -u 819B11A26FFD188D -o /jenkins/releases/${JOB_NAME}/${BUILD_NUMBER}/${targetdir}/$(basename ${file}).asc ${file}
done

rm -f /jenkins/releases/${JOB_NAME}/latest-${targetdir} || true
ln -s "/jenkins/releases/${JOB_NAME}/${BUILD_NUMBER}/${targetdir}" "/jenkins/releases/${JOB_NAME}/latest-${targetdir}"
