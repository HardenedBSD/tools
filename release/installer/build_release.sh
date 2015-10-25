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
LOG_FILE_PREFIX="${LOG_DIR}/${DATE}"
LOG_FILE="${LOG_FILE_PREFIX}.log"
LOG_FILE_SHORT="${LOG_DIR}/${DATE}.slog"
SOURCES_DIR="/usr/data/source/git/opBSD"
LOCK_DIR="${SOURCES_DIR}"
LOCK_FILE="${LOCK_DIR}/hardenedbsd-stable-repo-lock"
SOURCES_REPO="https://github.com/HardenedBSD"
HARDENEDBSD_STABLE_DIR="${SOURCES_DIR}/hardenedBSD-stable.git"
HARDENEDBSD_STABLE_REPO="${SOURCES_REPO}/hardenedBSD-stable.git"
HARDENEDBSD_TOOLS_DIR="${SOURCES_DIR}/tools.git"
HARDENEDBSD_TOOLS_REPO="${SOURCES_REPO}/tools.git"
RELEASE_CONF="${SOURCES_DIR}/tools.git/release/release-confs/HardenedBSD-stable-autodetect-git-release.conf"

log()
{
	echo "$*" | tee -a ${LOG_FILE_SHORT}
}

info()
{
	log "INFO: $*"
}

warn()
{

	log "WARNING: $*"
}

err()
{
	log "ERROR: $*"
	exit 1
}

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
		info "create missing ${_dir}"

		mkdir -p ${_parent_dir}
		cd ${_parent_dir}
		git clone ${_repo} ${_name}

		if [ ! -d ${_dir} ]
		then
			err "failed to create or missing ${_dir} directory"
		fi
	fi
}

get_revision()
{
	_branch=$1

	git rev-list ${_branch} -1
}

transform_branch_to_filename()
{
	_path=$1

	echo ${_path} | tr '/' '_'
}

prepare_branch()
{
	_branch=$1

	cd ${HARDENEDBSD_STABLE_DIR}

	info "prepare ${_branch} branch"

	git reset --hard
	git clean -fd

	git checkout -f ${_branch}
	git reset --hard origin/${_branch}
}

build_release()
{
	_branch=$1
	_log_name="${LOG_FILE_PREFIX}-`transform_branch_to_filename ${_branch}`"

	cd ${HARDENEDBSD_STABLE_DIR}

	if [ ! -d release ]
	then
		err "missing release dir"
	fi

	cd release

	if [ ! -f release.sh ]
	then
		err "missing release.sh"
	fi

	sh -x ./release.sh -c ${RELEASE_CONF} > ${_log_name}
	ret=$?

	if [ $ret = 0 ]
	then
		info "build done"
	else
		info "build failed"
	fi

	return ${ret}
}

publish_release()
{
	echo "TODO"
}

###############################################################################
###############################################################################

main()
{
	check_or_create_repo ${HARDENEDBSD_TOOLS_DIR} ${HARDENEDBSD_TOOLS_REPO}
	check_or_create_repo ${HARDENEDBSD_STABLE_DIR} ${HARDENEDBSD_STABLE_REPO}

	cd ${HARDENEDBSD_STABLE_DIR}

	old_revision_10=`get_revision origin/${BRANCH_10}`
	old_revision_current=`get_revision origin/${BRANCH_current}`

	git fetch origin

	new_revision_10=`get_revision origin/${BRANCH_10}`
	new_revision_current=`get_revision origin/${BRANCH_current}`

	info "10-STABLE revisions: old ${old_revision_10} new ${new_revision_10}"
	info "11-CURRENT revisions: old ${old_revision_current} new ${new_revision_current}"

	if [ "${old_revision_10}" != "${new_revision_10}" ] || [ "X${forced_mode}" = "Xyes" ]
	then
		prepare_branch ${BRANCH_10}
		build_release ${BRANCH_10}
		publish_release
	fi

	if [ "${old_revision_current}" != "${new_revision_current}" ] || [ "X${forced_mode}" = "Xyes" ]
	then
		prepare_branch ${BRANCH_current}
		build_release ${BRANCH_current}
		publish_release
	fi
}

###############################################################################
###############################################################################

if [ "X${1}" != "XTRACKED" ]
then
	if [ ! -d ${LOG_DIR} ]
	then
		mkdir -p ${LOG_DIR}
		if [ $? != 0 ]
		then
			err "missing log dir"
		fi
	fi

	if [ -f ${LOCK_FILE} ]
	then
		err "lock file exists"
	fi

	script ${LOG_FILE} ${0} TRACKED ${DATE} ${*}
else
	DATE=${2}

	if [ "X${3}" = "Xforced_mode" ]
	then
		forced_mode="yes"
	fi

	touch ${LOCK_FILE}
	main
	unlink ${LOCK_FILE}
fi

