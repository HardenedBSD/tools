#!/bin/csh

if ( ! ${?JOB_NAME} ) then
	echo "running in not supported directory"
	exit 1
endif

set _dir="/jenkins/releases/${JOB_NAME}"

cd ${_dir}
pwd | grep "${_dir}"
set ret=$?
if ( $ret != 0 ) then
	echo "running in not supported directory"
	exit 1
endif

ls -tp | tail -n +10 | tr '\n' '\0' | xargs -0 -I {} rm -rv {}
