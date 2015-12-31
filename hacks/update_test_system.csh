#!/bin/csh

#
# A very dirty test-env update script...
#


set DISK="/tmp/hbsd.raw"

umount /mnt
mdconfig -d -u 0

kldload -n vmm

mdconfig -a -t vnode -f ${DISK}

#fsck_ufs /dev/md0p2

mount /dev/md0p2 /mnt

mkdir -p /mnt/data

echo "nameserver 8.8.8.8" > /mnt/etc/resolv.conf

cat > /mnt/data/setup_test.sh<<__EOF
#!/bin/csh

setenv ASSUME_ALWAYS_YES yes
pkg bootstrap -f
unsetenv ASSUME_ALWAYS_YES
pkg install -y git
pkg install -y libucl

rehash

cd /data
git clone https://github.com/hardenedbsd/secadm.git
cd secadm
git checkout opbsd
make
make install

cd /data
git clone https://github.com/hardenedbsd/tools.git

git clone https://github.com/opntr/paxtest-freebsd.git

test -f /usr/src/UPDATING-HardenedBSD || fetch http://jenkins.hardenedbsd.org/builds/HardenedBSD-master-amd64-LATEST/src.txz
__EOF

chmod +x /mnt/data/setup_test.sh

chroot /mnt /data/setup_test.sh

umount /mnt

mdconfig -d -u 0
