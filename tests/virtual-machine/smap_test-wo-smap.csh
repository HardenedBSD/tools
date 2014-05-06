#!/bin/csh

set FREEBSD_PREFIX="/usr/home/op/git/"
#set QEMU_PREFIX="/usr/home/op/qemu/"
set QEMU_PREFIX="/usr/local/"

set QEMU="${QEMU_PREFIX}/bin/qemu"
set QEMU_X86_64="${QEMU_PREFIX}/bin/qemu-system-x86_64"
#set QEMU_OPTIONS="-cpu qemu64,enforce,+smap,-hypervisor -m 1024M"
set QEMU_OPTIONS="-cpu qemu64,enforce,-hypervisor -m 1024M"

set HDD_IMAGE="${FREEBSD_PREFIX}/freebsd-test.raw"

$QEMU_X86_64 $QEMU_OPTIONS -hda $HDD_IMAGE
