#!/bin/csh

set OPWD=`pwd`
set SOURCE_DIR="/usr/data/source/git/opBSD"
set GIT_REPO=${SOURCE_DIR}"/hardenedBSD.git"
set LOGS="$HOME/log/hardenedBSD"
set DATE=`date "+%Y%m%d%H%M%S"`
set TEE_CMD="tee -a"
set LOCK="${SOURCE_DIR}/hardenedbsd-repo-lock"
set DST_MAIL="robot@hardenedbsd.org"
set ENABLE_MAIL="YES"

set BASE_BRANCH="origin/hardened/current/master"
set ORIGIN_BASED="hardened/current/aslr"
set ORIGIN_BASED="${ORIGIN_BASED} hardened/current/hardening"
set ORIGIN_BASED="${ORIGIN_BASED} hardened/current/segvguard"
set ORIGIN_BASED="${ORIGIN_BASED} hardened/current/log"
set ORIGIN_BASED="${ORIGIN_BASED} hardened/current/unstable"
set ORIGIN_BASED="${ORIGIN_BASED} hardened/current/noexec"
set FREEBSD_BASED=""


test -d $LOGS || mkdir -p $LOGS

if ( -e ${LOCK} ) then
	echo "update error at ${DATE} - lock exists"
	if ( ${ENABLE_MAIL} == "YES" ) then
		echo "update error at ${DATE} - lock exists" | mail -s "hbsd - lock error" ${DST_MAIL}
	endif
	exit 1
endif

touch ${LOCK}

cd ${GIT_REPO}

#git fetch origin

echo "HardenedBSD based"
echo "branches: ${ORIGIN_BASED}"
foreach i ( ${ORIGIN_BASED} )
	set _mail_subject_prefix="[STAT]"
	set _branch=`echo $i | tr '/' ':'`

	echo "git cherry -v origin/hardened/current/master ${i}" | ${TEE_CMD} ${LOGS}/stat-${_branch}-${DATE}.log
	echo "===" | ${TEE_CMD} ${LOGS}/stat-${_branch}-${DATE}.log
	git cherry -v ${BASE_BRANCH} origin/${i} | ${TEE_CMD} ${LOGS}/stat-${_branch}-${DATE}.log
	echo

	if ( ${ENABLE_MAIL} == "YES" ) then
		cat ${LOGS}/stat-${_branch}-${DATE}.log | \
		    mail -s "${_mail_subject_prefix} stat-${_branch}-${DATE}.log" ${DST_MAIL}
	endif
end

cd $OPWD

unlink ${LOCK}
