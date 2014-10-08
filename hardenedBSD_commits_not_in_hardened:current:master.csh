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
set ORIGING_BASED="${ORIGING_BASED} hardened/current/hardening"
set ORIGING_BASED="${ORIGING_BASED} hardened/current/intel-smap"
set ORIGING_BASED="${ORIGING_BASED} hardened/current/paxctl"
set ORIGING_BASED="${ORIGING_BASED} hardened/current/segvguard"
set ORIGING_BASED="${ORIGING_BASED} hardened/current/upstream"
set ORIGING_BASED="${ORIGING_BASED} hardened/current/chacha"
set ORIGING_BASED="${ORIGING_BASED} hardened/current/log"
set ORIGING_BASED="${ORIGING_BASED} hardened/current/ptrace"
set ORIGING_BASED="${ORIGING_BASED} hardenedbsd_commits_not_in_hardened"
set ORIGING_BASED="${ORIGING_BASED} hardened/current/unstable"
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

	echo "git cherry -v origin/hardened/current/master ${i}" | ${TEE_CMD} ${LOGS}/stat-${_branch}-${DATE}
	echo "===" | ${TEE_CMD} ${LOGS}/stat-${_branch}-${DATE}
	git cherry -v ${BASE_BRANCH} origin/${i} | ${TEE_CMD} ${LOGS}/stat-${_branch}-${DATE}
	echo

	if ( ${ENABLE_MAIL} == "YES" ) then
		cat ${LOGS}/${_branch}-${DATE}.log | \
		    mail -s "${_mail_subject_prefix} stat-${_branch}-${DATE}.log" ${DST_MAIL}
	endif
end

cd $OPWD

unlink ${LOCK}
