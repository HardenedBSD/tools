#!/bin/sh

__name="hardenedbsd-test"
__vm_dir="/usr/data/vm"
__installer="${__vm_dir}/HardenedBSD-11-CURRENT_hardenedbsd-master-amd64-disc1.iso"
__disk="${__vm_dir}/hardenedbsd-vm.img"
__bootdisk=""
__installed="${__vm_dir}/.installed"

if [ ! -d ${__vm_dir} ]
then
	mkdir -p ${__vm_dir}
fi

if [ ! -f ${__disk} ]
then
	echo "create HDD"
	truncate -s 20G ${__disk}
fi

if [ ! -f ${__installer} ]
then
	echo "fetch installer"
	fetch 'http://jenkins.hardenedbsd.org/builds/HardenedBSD-master-amd64-LATEST/HardenedBSD-11-CURRENT_hardenedbsd-master-amd64-disc1.iso' -o ${__installer}
fi

if [ ! -f ${__installed} ]
then
	__bootdisk=${__installer}
	touch ${__installed}
else
	__bootdisk=${__disk}
fi

reset
bhyveload -m 1G -d ${__bootdisk} ${__name}
bhyve -c 2 -s 0,hostbridge -s 1,lpc -s 2,virtio-blk,${__disk} -s 3,ahci-cd,${__installer} -l com1,stdio -A -H -P -m 1G ${__name}
bhyvectl --destroy --vm=${__name}
