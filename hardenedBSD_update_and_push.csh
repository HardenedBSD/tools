#!/bin/csh

set OPWD=`pwd`
set SOURCE_DIR="/usr/data/source/git/opBSD"
set BRANCHES=`cat $SOURCE_DIR/hardenedBSD_branches.txt`
set SOURCE="$SOURCE_DIR/hardenedBSD.git"
set LOGS="$HOME/log/hardenedBSD"
set DATE=`date "+%Y%m%d%H%M%S"`
set TEE_CMD="tee -a"
set LOCK="${SOURCE_DIR}/hardenedbsd-repo-lock"
set DST_MAIL="robot@hardenedbsd.org"
set ENABLE_MAIL="YES"

test -d $LOGS || mkdir -p $LOGS

if ( -e ${LOCK} ) then
	echo "update error at ${DATE} - lock exists"
	if ( ${ENABLE_MAIL} == "YES" ) then
		echo "update error at ${DATE} - lock exists" | mail -s "hbsd - lock error" ${DST_MAIL}
	endif
	exit 1
endif

touch ${LOCK}

cd ${SOURCE}

set OHEAD=`git branch | awk '/\*/{print $2}'`

git stash

(git fetch origin) | ${TEE_CMD} ${LOGS}/freebsd-fetch-${DATE}.log
(git fetch freebsd) | ${TEE_CMD} ${LOGS}/freebsd-fetch-${DATE}.log

foreach branch ( ${BRANCHES} )
	set err=0
	set _mail_subject_prefix=""

	# drop any stale change
	git reset --hard

	set remote_branches=`echo ${branch} | cut -d ':' -f 2 | tr '+' ' '`
	set branch=`echo ${branch} | cut -d ':' -f 1`
	set _branch=`echo ${branch} | tr '/' ':'`

	# merge specific branches to current branch
	(git checkout ${branch}) |& ${TEE_CMD} ${LOGS}/${_branch}-${DATE}.log
	(git merge ${branch} ${remote_branches}) |& ${TEE_CMD} ${LOGS}/${_branch}-${DATE}.log
	if ( $? != 0 ) then
		set err=1
		set _mail_subject_prefix="[MERGE]"
		goto handle_err
	endif

	# update remote
	(git push origin ${branch}) |& ${TEE_CMD} ${LOGS}/${_branch}-${DATE}.log
	if ( $? != 0 ) then
		set _mail_subject_prefix="[PUSH]"
		set err=1
		goto handle_err
	endif

handle_err:
	if ( ${err} != 0 ) then
		set _mail_subject_prefix="[FAILED]${_mail_subject_prefix}"
	else
		set _mail_subject_prefix="[OK]"
	endif

	if ( ${ENABLE_MAIL} == "YES" ) then
		cat ${LOGS}/${_branch}-${DATE}.log | \
		    mail -s "${_mail_subject_prefix} ${_branch}-${DATE}.log" ${DST_MAIL}
	endif
	echo
end

git checkout ${OHEAD}
git stash pop

cd $OPWD

unlink ${LOCK}
