#!/bin/csh

set FREEBSD_PREFIX="/usr/home/op/git/"
set QEMU_PREFIX="/usr/home/op/qemu/"

set MDCONFIG="/sbin/mdconfig"
set QEMU="${QEMU_PREFIX}/bin/qemu"
set QEMU_IMG="${QEMU_PREFIX}bin/qemu-img"
set QEMU_X86_64="${QEMU_PREFIX}/bin/qemu-system-x86_64"
set QEMU_OPTIONS="-cpu Haswell -m 1024M"
#set QEMU_OPTIONS="-cpu Haswell -m 1024M"
set QEMU_OPTIONS="-cpu qemu64,+smep,+smap -m 1024M"
set HDD_SIZE="20G"

set HDD_IMAGE="${FREEBSD_PREFIX}/freebsd-test.raw"
set FREEBSD_CDROM="/usr/home/op/git/FreeBSD-10.0-CURRENT-amd64-20130323-r248655-bootonly.iso"

if (! -e $HDD_IMAGE) then
	$QEMU_IMG create -f raw $HDD_IMAGE $HDD_SIZE
	$QEMU_X86_64 $QEMU_OPTIONS -cdrom $FREEBSD_CDROM -hda $HDD_IMAGE -boot d
endif


$QEMU_X86_64 $QEMU_OPTIONS -hda $HDD_IMAGE
