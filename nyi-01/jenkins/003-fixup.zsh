#!/usr/bin/env zsh

_TAR_DIR="/jenkins/releases/${JOB_NAME}/build-${BUILD_NUMBER}/"

# fixup for CHECKSUMs, to not contain full path of files
for _file in $(find ${_TAR_DIR} -maxdepth 2 -name 'CHECKSUMS.SHA256' -o -name 'CHECKSUMS.SHA512' -o -name 'CHECKSUMS.MD5'); do
	sed -i '' -e '/SHA256/s|^\(.*(\).*/\(.*\)|\1\2|g' -e '/SHA512/s|^\(.*(\).*/\(.*\)|\1\2|g' -e '/MD5/s|^\(.*(\).*/\(.*\)|\1\2|g' ${_file}
done

