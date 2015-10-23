#!/usr/bin/env sh

#
# TODO
# ----
# proper logging
# email about the build
# force mode
# initial mode
# error recovery
# publisher module
# signing
#

DATE=`date "+%Y%m%d%H%M%S"`

BRANCH_10="hardened/10-stable/master"
BRANCH_current="hardened/current/master"

LOG_DIR="/usr/data/source/logs"
SOURCES_DIR="/usr/data/source/git/opBSD"
LOCK_DIR="${SOURCES_DIR}"
LOCK_FILE="${LOCK_DIR}/hardenedbsd-stable-repo-lock"
SOURCES_REPO="https://github.com/HardenedBSD"
HARDENEDBSD_STABLE_DIR="${SOURCES_DIR}/hardenedBSD-stable.git"
HARDENEDBSD_STABLE_REPO="${SOURCES_REPO}/hardenedBSD-stable.git"
HARDENEDBSD_TOOLS_DIR="${SOURCES_DIR}/tools.git"
HARDENEDBSD_TOOLS_REPO="${SOURCES_REPO}/tools.git"
RELEASE_CONF="${SOURCES_DIR}/tools.git/release/release-confs/HardenedBSD-stable-autodetect-git-release.conf"

if [ "X${1}" != "XTRACKED" ]
then
	if [ ! -d ${LOG_DIR} ]
	then
		mkdir -p ${LOG_DIR}
		if [ $? != 0 ]
		then
			echo "wtf?!?"
			exit 1
		fi
	fi

	if [ -f ${LOCK_FILE} ]
	then
		echo "${DATE}: lock exists ..."
		exit 1
	fi

	touch ${LOCK_FILE}
	script ${LOG_DIR}/${DATE}.log ${0} TRACKED ${DATE} ${*}
	unlink ${LOCK_FILE}
else
	DATE=${2}

	if [ "X${3}" = "Xforced_mode" ]
	then
		forced_mode="yes"
	fi

fi

###############################################################################
###############################################################################

check_or_create_repo()
{
	_dir=$1
	_repo=$2

	_parent_dir=`dirname ${_dir}`
	_name=`basename ${_dir}`

	if [ ! -d ${_dir} ]
	then
		echo "create missing ${_dir}"

		mkdir -p ${_parent_dir}
		cd ${_parent_dir}
		git clone ${_repo} ${_name}

		if [ ! -d ${_dir} ]
		then
			echo "failed to create or missing ${_dir} directory"
			exit 1
		fi
	fi
}

get_revision()
{
	_branch=$1

	git rev-list ${_branch} -1
}

prepare_branch()
{
	_branch=$1

	cd ${HARDENEDBSD_STABLE_DIR}

	git reset --hard
	git clean -fd

	git checkout ${_branch}
	git checkout -f origin/${_branch}
}

build_release()
{
	cd ${HARDENEDBSD_STABLE_DIR}

	if [ ! -d release ]
	then
		echo "wtf?!"
		exit 2
	fi

	cd release

	if [ ! -f release.sh ]
	then
		echo "wtf!?"
		exit 3
	fi

	sh -x ./release.sh -c ${RELEASE_CONF}
}

publish_release()
{
	echo "TODO"
}

###############################################################################
###############################################################################

check_or_create_repo ${HARDENEDBSD_TOOLS_DIR} ${HARDENEDBSD_TOOLS_REPO}
check_or_create_repo ${HARDENEDBSD_STABLE_DIR} ${HARDENEDBSD_STABLE_REPO}

cd ${HARDENEDBSD_STABLE_DIR}

old_revision_10=`get_revision origin/${BRANCH_10}`
old_revision_current=`get_revision origin/${BRANCH_current}`

git fetch origin

new_revision_10=`get_revision origin/${BRANCH_10}`
new_revision_current=`get_revision origin/${BRANCH_current}`

if [ "${old_revision_10}" != "${new_revision_10}" ] || [ "X${forced_mode}" = "Xyes" ]
then
	prepare_branch ${BRANCH_10}
	build_release
	publish_release
fi

if [ "${old_revision_current}" != "${new_revision_current}" ] || [ "X${forced_mode}" = "Xyes" ]
then
	prepare_branch ${BRANCH_current}
	build_release
	publish_release
fi
