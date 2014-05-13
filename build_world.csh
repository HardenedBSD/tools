#!/bin/csh

setenv MAKEOBJDIRPREFIX /tmp/objdir
@ __freebsd_mk_jobs = `sysctl -n kern.smp.cpus` + 1
set current_dir = `pwd`
set _current_dir = `basename $current_dir`

if ( (${_current_dir} != "hardenedBSD.git")) then
	if ((${_current_dir} != "opBSD.git")) then
		set _current_dir = "hardenedBSD.git"
	endif
endif

echo "build source dir: ${_current_dir}"
sleep 1

test -d $MAKEOBJDIRPREFIX || mkdir $MAKEOBJDIRPREFIX

(cd /usr/data/source/git/opBSD/${_current_dir}; make -j$__freebsd_mk_jobs buildworld buildkernel) |& tee /tmp/cc-log-${_current_dir}-`date "+%Y%m%d%H%M%S"`
