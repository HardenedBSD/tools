#!/bin/csh

#
# A very dirty test-env update script...
#

set DISK="/tmp/hbsd.raw"
set INSTALLER_URL="http://installer.hardenedbsd.org/releases/hardened_current_master-LAST/HardenedBSD-11-CURRENT-v34-amd64-disc1.iso"
set INSTALLER="/tmp/installer.iso"

umount /mnt
mdconfig -d -u 0

kldload -n vmm

if ( ! -f ${DISK} ) then

	if ( ! -f ${INSTALLER} ) then
		fetch ${INSTALLER_URL} -o ${INSTALLER}
	endif
	
	truncate -s 3G ${DISK}
	~/vmrun.sh -I ${INSTALLER} -d ${DISK} -m 1G install
endif

mdconfig -a -t vnode -f ${DISK}

#fsck_ufs /dev/md0p2

mount /dev/md0p2 /mnt

rm -r /mnt/boot/kernel /mnt/usr/lib/debug/boot/kernel

cp -rv /tmp/amd64-kernel/ /mnt

umount /mnt

mdconfig -d -u 0
