#!/bin/csh

if ( -f /tmp/build-pid) then
	set build_pid=`cat /tmp/build-pid`
	echo "waiting for build: PID ${build_pid}"
	pwait ${build_pid}
	unlink /tmp/build-pid
endif

set __vm_image="/usr/data/vm/hardenedbsd-test.img"
set __mount_point="`mktemp -d`"
set ret=$?
if ( ${ret} != 0 ) then
	echo "fail @mktemp"
	exit 1
endif
set __prefix=${__mount_point}

echo "mdconfig ..."

set __dev="`mdconfig -t vnode -f /usr/data/vm/hardenedbsd-vm.img`"
set ret=$?
if ( ${ret} != 0 ) then
	echo "fail @mdconfig"
	exit 1
endif

set __part="/dev/${__dev}s1a"

echo "fsck ..."

fsck_ufs -y ${__part}

echo "mount ..."

mount ${__part} ${__mount_point}
set ret=$?
if ( ${ret} != 0 ) then
	echo "fail @mount"
	exit 1
endif

rm -rvf ${__prefix}/boot/kernel.new
cp -rv /tmp/amd64-kernel/boot/kernel ${__prefix}/boot/kernel.new
chown -R root:wheel ${__prefix}/boot/kernel.new

echo "nextboot ..."

echo 'nextboot_enable="YES"' >> ${__prefix}/boot/nextboot.conf
echo 'kernel="kernel.new"' >> ${__prefix}/boot/nextboot.conf

echo "cleanup ..."

umount -f ${__mount_point}
mdconfig -d -u ${__dev}

echo "starting VM in 3 sec"
sleep 1
printf "."
sleep 1
printf "."
sleep 1
printf "."
echo "starting VM"

/usr/data/vm/start.sh
