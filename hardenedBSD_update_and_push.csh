#!/bin/csh

set OPWD=`pwd`
set BRANCHES=`cat /usr/data/source/git/opBSD/hardenedBSD_branches.txt`
set SOURCE="/usr/data/source/git/opBSD/hardenedBSD.git"
set LOGS="/usr/data/source/git/opBSD/hardenedBSD/logs"
set DATE=`date "+%Y%m%d%H%M%S"`
set TEE_CMD="tee -a"

cd ${SOURCE}

set OHEAD=`git branch | awk '/\*/{print $2}'`

git stash

(git fetch freebsd) | ${TEE_CMD} ${LOGS}/freebsd-fetch-${DATE}.log

foreach branch ( ${BRANCHES} )
	set _branch=`echo ${branch} | tr '/' ':'`
	(git checkout ${branch}) |& ${TEE_CMD} ${LOGS}/${_branch}-${DATE}.log
	(git merge ${branch} freebsd/${branch}) |& ${TEE_CMD} ${LOGS}/${_branch}-${DATE}.log
end

git checkout ${OHEAD}
git stash pop

#git push --all

foreach branch ( ${BRANCHES} )
	set _branch=`echo ${branch} | tr '/' ':'`
	(git push origin ${branch}) |& ${TEE_CMD} ${LOGS}/${_branch}-${DATE}.log
end

cd $OPWD
