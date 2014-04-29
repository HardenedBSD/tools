#!/bin/csh

set FREEBSD_PREFIX="/usr/home/op/git/"
set QEMU_PREFIX="/usr/home/op/qemu/"

set MDCONFIG="/sbin/mdconfig"
set QEMU="${QEMU_PREFIX}/bin/qemu"
set QEMU_IMG="${QEMU_PREFIX}bin/qemu-img"
set QEMU_X86_64="${QEMU_PREFIX}/bin/qemu-system-x86_64"
set QEMU_OPTIONS="-cpu Haswell -m 1024M"
set FSCK="/sbin/fsck_ffs"

set HDD_IMAGE="${FREEBSD_PREFIX}/freebsd-test.raw"

if (! -e $HDD_IMAGE) then
	${FREEBSD_PREFIX}/mkenv_haswell_env.csh
endif

set MD_DEV=`$MDCONFIG -a -t vnode -f $HDD_IMAGE`

if (! -e /dev/$MD_DEV) then
	echo "mdconfig failed..."
	exit -1
endif

set MD_DEV_ROOT="/dev/${MD_DEV}p2"

$FSCK -y $MD_DEV_ROOT

setenv DESTDIR ${FREEBSD_PREFIX}/target

if (! -e $DESTDIR) then
	mkdir $DESTDIR
endif

mount /dev/${MD_DEV}p2 $DESTDIR

cd ${FREEBSD_PREFIX}/freebsd-base.git.http
#make -j4 buildworld installworld kernel  -DNO_CLEAN
make -j4 kernel -DNO_CLEAN || make -j4 kernel

umount ${FREEBSD_PREFIX}/target

$MDCONFIG -d -u $MD_DEV


#$QEMU_X86_64 $QEMU_OPTIONS -hda $HDD_IMAGE

