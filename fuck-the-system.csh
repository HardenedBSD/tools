#!/usr/bin/env csh

# fuck the system - aka 11-CURRENT cross installer for 10-STABLE HOST

set DESTDIR="/target"
set SRC_DIR="${DESTDIR}/usr/src"
set MAKEOBJDIRPREFIX="${DESTDIR}/usr/obj"
set KERNCONF="HARDENEDBSD"
set T_start=`date`
set _err=0

setenv __MAKE_CONF "/dev/null"
setenv __SRC_CONF "/target/src.conf"
setenv MAKE_CONF "/dev/null"
setenv SRC_CONF "/target/src.conf"

echo "WITHOUT_PROFILE=" > ${__SRC_CONF}

echo "src.conf:"
cat ${SRC_CONF}
echo

# broken MAKEOBJDIRPREFIX workaround
mount -t nullfs ${MAKEOBJDIRPREFIX} /usr/obj

set _nullfs=`mount | grep -c nullfs`
if ( ${_nullfs} != 1 ) then
	set _err=255
	goto err
endif

if ( ! -e ${SRC_DIR}/.git ) then
	git clone https://github.com/HardenedBSD/hardenedbsd.git ${SRC_DIR}
endif

cd ${SRC_DIR}

set _GIT_HEAD=`git branch | awk '/\*/{print $2}'`
if ( ${_GIT_HEAD} == "master" ) then
	set KERNCONF="GENERIC"
endif

make -j5 buildworld DESTDIR=${DESTDIR} || set _err=1 1 && goto err
make -j5 buildkernel DESTDIR=${DESTDIR} KERNCONF=${KERNCONF} || set _err=2 && goto err
make installkernel DESTDIR=${DESTDIR} KERNCONF=${KERNCONF} || set _err=3 && goto err
make installworld DESTDIR=${DESTDIR} || set _err=4 && goto err
make distribution DESTDIR=${DESTDIR} || set _err=5 && goto err

cp /etc/make.conf /target/etc/
cp /etc/src.conf /target/etc/
cp /etc/rc.conf /target/etc/

set T_stop=`date`

echo "start: ${T_start}"
echo "stop: ${T_stop}"

err:
	umount /usr/obj
	exit ${_err}
