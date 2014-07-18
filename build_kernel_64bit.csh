#!/bin/csh

setenv TARGET amd64
setenv MAKEOBJDIRPREFIX /tmp/${TARGET}-objdir
setenv __MAKE_CONF /dev/null
setenv DESTDIR /tmp/${TARGET}-kernel
@ __freebsd_mk_jobs = `sysctl -n kern.smp.cpus` + 1
set current_dir = `pwd`
set _current_dir = `echo ${current_dir} | sed -e 's|\(.*/\)\(.*\.git\)\(/.*\)*|\2|g'`
set _current_realdir = `echo ${current_dir} | sed -e 's|\(.*/\)\(.*\.git\)\(/.*\)*|\1/\2|g'`
set _check_toolchain = "${MAKEOBJDIRPREFIX}/___kernel-toolchain_DONE"
set _date=`date "+%Y%m%d%H%M%S"`
set _log="/tmp/${TARGET}-cc-log-${_current_dir}-${_date}"

if ( "`sysctl -n security.bsd.hardlink_check_uid`" == "1" ) then
	echo "build will fail, due to hard security checks"
	echo "sysctl security.bsd.hardlink_check_uid=0"
	exit
endif

if ( "`sysctl -n security.bsd.hardlink_check_gid`" == "1" ) then
	echo "build will fail, due to hard security checks"
	echo "sysctl security.bsd.hardlink_check_gid=0"
	exit
endif

if ( (${_current_dir} != "hardenedBSD.git")) then
	if ((${_current_dir} != "opBSD.git")) then
		set _current_dir = "hardenedBSD.git"
	endif
endif

echo "build source dir: ${_current_dir}"
sleep 1

if ( ! -d $MAKEOBJDIRPREFIX ) then
	mkdir $MAKEOBJDIRPREFIX
endif

if ( ! -f ${_check_toolchain} ) then
	(cd /usr/data/source/git/opBSD/${_current_dir}; make -j$__freebsd_mk_jobs -DNO_ROOT KERNCONF=GENERIC kernel-toolchain) |& tee ${_log} || exit
	touch ${_check_toolchain}
else
	echo "skip make kernel-toolchain"
	sleep 1
endif
(cd /usr/data/source/git/opBSD/${_current_dir}; make -j$__freebsd_mk_jobs -DNO_ROOT KERNCONF=GENERIC kernel) |& tee -a ${_log}
