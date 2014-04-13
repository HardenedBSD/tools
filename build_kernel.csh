#!/bin/csh

setenv MAKEOBJDIRPREFIX /tmp/objdir
@ __freebsd_mk_jobs = `sysctl -n kern.smp.cpus` + 1

test -d $MAKEOBJDIRPREFIX || mkdir $MAKEOBJDIRPREFIX

(cd /usr/data/source/git/opBSD/hardenedBSD.git; make -j$__freebsd_mk_jobs buildkernel) |& tee /tmp/cc-log-`date "+%Y%m%d%H%M%S"`
