#!/bin/csh

set OPWD=`pwd`
set SOURCE_DIR="/usr/data/source/git/opBSD"
set BRANCHES="master:freebsd/master"
set SOURCE="$SOURCE_DIR/hardenedbsd-ports.git"
set LOGS="$HOME/log/hardenedbsd-ports"
set DATE=`date "+%Y%m%d%H%M%S"`
set TEE_CMD="tee -a"
set LOCK="${SOURCE_DIR}/ports-repo-lock"
set DST_MAIL="robot@hardenedbsd.org"
set ENABLE_MAIL="YES"

setenv PATH "${PATH}:/usr/local/bin"

test -d $LOGS || mkdir -p $LOGS

if ( -e ${LOCK} ) then
	echo "update error at ${DATE} - lock exists"
	if ( ${ENABLE_MAIL} == "YES" ) then
		echo "update error at ${DATE} - lock exists" | mail -s "hbsd - lock error" ${DST_MAIL}
	endif
	exit 1
endif

touch ${LOCK}

if ( ! -d ${SOURCE} ) then
	mkdir -p ${SOURCE_DIR}
	cd ${SOURCE_DIR}
	git clone 'git@github.com:HardenedBSD/hardenedbsd-ports.git' hardenedbsd-ports.git
	cd ${SOURCE}
	git remote add freebsd 'https://github.com/freebsd/freebsd-ports.git'
endif

if ( ! -d ${SOURCE} ) then
	echo "update error at ${DATE} - failed to check out ports repository"
	if ( ${ENABLE_MAIL} == "YES" ) then
		echo "update error at ${DATE} - failed to check out ports repository" | mail -s "hbsd - lock error" ${DST_MAIL}
	endif
	exit 1
endif

cd ${SOURCE}

set OHEAD=`git branch | awk '/\*/{print $2}'`

git stash

(git fetch origin) |& ${TEE_CMD} ${LOGS}/freebsd-fetch-${DATE}.log
(git fetch freebsd) |& ${TEE_CMD} ${LOGS}/freebsd-fetch-${DATE}.log

foreach branch ( ${BRANCHES} )
	set err=0
	set _mail_subject_prefix=""

	set remote_branches=`echo ${branch} | cut -d ':' -f 2 | tr '+' ' '`
	set branch=`echo ${branch} | cut -d ':' -f 1`
	set _branch=`echo ${branch} | tr '/' ':'`

	echo "==== BEGIN: ${branch} ====" |& ${TEE_CMD} ${LOGS}/${_branch}-${DATE}.log

	echo "current branch: ${branch}" |& ${TEE_CMD} ${LOGS}/${_branch}-${DATE}.log
	echo "mergeable branch: ${remote_branches}" |& ${TEE_CMD} ${LOGS}/${_branch}-${DATE}.log

	echo "==== change branch ====" |& ${TEE_CMD} ${LOGS}/${_branch}-${DATE}.log
	# change branch
	(git checkout ${branch}) |& ${TEE_CMD} ${LOGS}/${_branch}-${DATE}.log

	echo "==== show current branch ====" |& ${TEE_CMD} ${LOGS}/${_branch}-${DATE}.log
	# show, that branch correctly switched
	(git branch) |& ${TEE_CMD} ${LOGS}/${_branch}-${DATE}.log

	echo "==== drop stale changes ====" |& ${TEE_CMD} ${LOGS}/${_branch}-${DATE}.log
	# drop any stale change
	(git reset --hard HEAD) |& ${TEE_CMD} ${LOGS}/${_branch}-${DATE}.log

	echo "==== update to latest origin ====" |& ${TEE_CMD} ${LOGS}/${_branch}-${DATE}.log
	# pull in latest changes from main repo
	(git pull) |& ${TEE_CMD} ${LOGS}/${_branch}-${DATE}.log
	if ( $? != 0 ) then
		echo "ERROR: git pull failed, try to recover" |& ${TEE_CMD} ${LOGS}/${_branch}-${DATE}.log
		( git reset --hard ) |& ${TEE_CMD} ${LOGS}/${_branch}-${DATE}.log
	endif
	echo "==== merge branches ====" |& ${TEE_CMD} ${LOGS}/${_branch}-${DATE}.log
	foreach _remote_branch ( ${remote_branches} )
		# merge specific branches to current branch
		echo "==== merge ${_remote_branch} branch ====" |& ${TEE_CMD} ${LOGS}/${_branch}-${DATE}.log
		(git merge ${branch} ${_remote_branch}) |& ${TEE_CMD} ${LOGS}/${_branch}-${DATE}.log
		if ( $? != 0 ) then
			set err=1
			set _mail_subject_prefix="[MERGE]"
			# show what's wrong
			echo "==== merge failed at ${_remote_branch} branch ====" |& ${TEE_CMD} ${LOGS}/${_branch}-${DATE}.log
			(git diff) |& head -500 | ${TEE_CMD} ${LOGS}/${_branch}-${DATE}.log
			(git status) |& ${TEE_CMD} ${LOGS}/${_branch}-${DATE}.log
			(git reset --hard) |& ${TEE_CMD} ${LOGS}/${_branch}-${DATE}.log
			(git clean -fd) |& ${TEE_CMD} ${LOGS}/${_branch}-${DATE}.log
		endif
	end

	if ( ${err} != 0 ) then
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
		# create a clean state, if failed something
		echo "==== merge failed and clean up after ====" |& ${TEE_CMD} ${LOGS}/${_branch}-${DATE}.log
		(git status) |& ${TEE_CMD} ${LOGS}/${_branch}-${DATE}.log
		(git reset --hard) |& ${TEE_CMD} ${LOGS}/${_branch}-${DATE}.log
		(git clean -fd) |& ${TEE_CMD} ${LOGS}/${_branch}-${DATE}.log
	else
		set _mail_subject_prefix="[OK]"
	endif

	echo "==== END: ${branch} ====" |& ${TEE_CMD} ${LOGS}/${_branch}-${DATE}.log
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
