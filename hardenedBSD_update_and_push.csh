#!/bin/csh

set OPWD=`pwd`
set SOURCE_DIR="/usr/data/source/git/opBSD"
set BRANCHES=`cat $SOURCE_DIR/hardenedBSD_branches.txt`
set SOURCE="$SOURCE_DIR/hardenedBSD.git"
set LOGS="$HOME/log/hardenedBSD"
set DATE=`date "+%Y%m%d%H%M%S"`
set TEE_CMD="tee -a"
set LOCK="${SOURCE_DIR}/hardenedbsd-repo-lock"
set DST_MAIL="op@hardenedbsd.org"

test -d $LOGS || mkdir -p $LOGS

if ( -e ${LOCK} ) then
	echo "update error at ${DATE} - lock exists" | mail -s "hbsd - lock error" ${DST_MAIL}
	exit 1
endif

touch ${LOCK}

cd ${SOURCE}

set OHEAD=`git branch | awk '/\*/{print $2}'`

git stash

(git fetch origin) | ${TEE_CMD} ${LOGS}/freebsd-fetch-${DATE}.log
(git fetch freebsd) | ${TEE_CMD} ${LOGS}/freebsd-fetch-${DATE}.log

foreach branch ( ${BRANCHES} )
	set remote_branch=`echo ${branch} | cut -d ':' -f 2`
	set branch=`echo ${branch} | cut -d ':' -f 1`
	set _branch=`echo ${branch} | tr '/' ':'`
	(git checkout ${branch}) |& ${TEE_CMD} ${LOGS}/${_branch}-${DATE}.log
	(git merge ${branch} ${remote_branch}) |& ${TEE_CMD} ${LOGS}/${_branch}-${DATE}.log
end

git checkout ${OHEAD}
git stash pop

#git push --all

foreach branch ( ${BRANCHES} )
	set branch=`echo ${branch} | cut -d ':' -f 1`
	set _branch=`echo ${branch} | tr '/' ':'`
	(git push origin ${branch}) |& ${TEE_CMD} ${LOGS}/${_branch}-${DATE}.log
end

cd $OPWD

unlink ${LOCK}
