#!/bin/csh

set __DATE=`date "+%Y-%m-%d"`
set __NAME="master-${__DATE}"
set __NEWBE="/tmp/newbe"
set __DESTDIR="${__NEWBE}"
set __KERNCONF="JENKINS"
set __SRCDIR="/usr/src"
set _ret=0
set _label=""

cd ${__SRCDIR}

make -j8 buildworld buildkernel KERNCONF=${__KERNCONF}
set _ret=$?
if ( ${_ret} != 0 ) then
	set _label="build world"
	goto _err
endif

beadm create ${__NAME}
set _ret=$?
if ( ${_ret} != 0 ) then
	set _label="beadm create"
	goto _err
endif

if ( ! -d ${__DESTDIR} ) then
	mkdir -p ${__DESTDIR}
endif

beadm mount ${__NAME} ${__DESTDIR}
set _ret=$?
if ( ${_ret} != 0 ) then
	set _label="beadm mount"
	goto _err
endif

make installworld installkernel KERNCONF=${__KERNCONF} DESTDIR=${__DESTDIR}
set _ret=$?
if ( ${_ret} != 0 ) then
	set _label="install world"
	goto _err
endif

mergemaster -D ${__DESTDIR}
set _ret=$?
if ( ${_ret} != 0 ) then
	set _label="mergemaster"
	goto _err
endif

beadm umount ${__NAME}
set _ret=$?
if ( ${_ret} != 0 ) then
	set _label="beadm umount"
	goto _err
endif

beadm activate ${__NAME}
set _ret=$?
if ( ${_ret} != 0 ) then
	set _label="beadm activate"
	goto _err
endif

goto _done

_err:
echo "Error: ${_ret} @${_label}"

_done:
exit ${_ret}

