#!/bin/csh

setenv MAKEOBJDIRPREFIX /tmp/objdir
setenv DESTDIR /tmp/kernelbuild
@ __freebsd_mk_jobs = `sysctl -n kern.smp.cpus` + 1
set current_dir = `pwd`
set _current_dir = `echo ${current_dir} | sed -e 's|\(.*/\)\(.*\.git\)\(/.*\)*|\2|g'`
set _date=`date "+%Y%m%d%H%M%S"`

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

test -d $MAKEOBJDIRPREFIX || mkdir $MAKEOBJDIRPREFIX

(cd /usr/data/source/git/opBSD/${_current_dir}; make -j$__freebsd_mk_jobs -DNO_ROOT KERNCONF=GENERIC kernel-toolchain) |& tee /tmp/cc-log-${_current_dir}-${_date}
(cd /usr/data/source/git/opBSD/${_current_dir}; make -j$__freebsd_mk_jobs -DNO_ROOT KERNCONF=GENERIC buildkernel) |& tee -a /tmp/cc-log-${_current_dir}-${_date}
