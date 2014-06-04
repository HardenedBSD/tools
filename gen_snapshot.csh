#!/bin/csh

set OPWD=`pwd`
set SOURCE_DIR="/usr/data/source/git/opBSD"
set SOURCE="$SOURCE_DIR/hardenedBSD.git"
set DATE=`date "+%Y%m%d%H%M%S"`

cd ${SOURCE}

set OHEAD=`git branch | awk '/\*/{print $2}'`

git stash

${SOURCE_DIR}/tools.git/hardenedBSD_update_and_push.csh
git fetch freebsd
git checkout hardened/current/aslr

setenv GIT_MERGE_AUTOEDIT no

git merge origin/hardened/current/aslr
git merge freebsd/master

unsetenv GIT_MERGE_AUTOEDIT

git diff freebsd/stable/10 hardened/10/aslr > /tmp/${DATE}-freebsd-stable-10-aslr-segvguard-SNAPSHOT.diff
git diff freebsd/master hardened/current/aslr > /tmp/${DATE}-freebsd-current-aslr-segvguard-SNAPSHOT.diff
git tag ${DATE}-freebsd-stable-10-aslr-segvguard-SNAPSHOT `git rev-list hardened/10/aslr -1`
git tag ${DATE}-freebsd-current-aslr-segvguard-SNAPSHOT `git rev-list hardened/current/aslr -1`

git push origin hardened/current/aslr
git push --tags

git checkout ${OHEAD}
git stash pop

scp /tmp/${DATE}-freebsd-stable-10-aslr-segvguard-SNAPSHOT.diff /tmp/${DATE}-freebsd-current-aslr-segvguard-SNAPSHOT.diff shamir.crysys.hu:~/public_html/freebsd/patches/

cd ${OPWD}
