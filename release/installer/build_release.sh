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

PATH=${PATH}:/usr/local/bin
export PATH

DATE=`date "+%Y%m%d%H%M%S"`

BRANCH_10="hardened/10-stable/master"
BRANCH_current="hardened/current/master"

LOG_DIR="/usr/data/release/logs"
LOG_DIR_INFO="${LOG_DIR}/info"
LOG_DIR_DONE="${LOG_DIR}/done"
LOG_DIR_FAILED="${LOG_DIR}/failed"
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
	echo "`date` $*" | tee -a ${LOG_FILE_SHORT}
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
	exit 255
}

transform_branch_to_filename()
{
	local _path="$1"

	echo ${_path} | tr '\\/-+;|&$()*?!#[]{}' '_'
}

set_branch_specific()
{
	local _branch="`transform_branch_to_filename $1`"
	local _var="$2"
	shift
	shift
	local _param="$*"

	eval ${_branch}_${_var}="\${_param}"
}

get_branch_specific()
{
	local _branch="`transform_branch_to_filename $1`"
	local _var="$2"

	eval echo \"\${${_branch}_${_var}}\"
}

###############################################################################
###############################################################################

check_or_create_repo()
{
	local _dir="$1"
	local _repo="$2"

	local _parent_dir="`dirname ${_dir}`"
	local _name="`basename ${_dir}`"

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
	local _branch="$1"

	git rev-list ${_branch} -1
}

prepare_branch()
{
	local _branch="$1"

	cd ${HARDENEDBSD_STABLE_DIR}

	info "prepare ${_branch} branch"

	git reset --hard
	git clean -fd

	git checkout -f ${_branch}
	git reset --hard origin/${_branch}
}

parse_release_metainfo()
{
	local _branch=$1

	for i in $(get_branch_specific ${_branch} BUILD_INFO)
	do
		case ${i} in
		c:*)
			set_branch_specific ${_branch} CHROOT `echo ${i} | cut -d ':' -f 2`
		;;
		b:*)
			set_branch_specific ${_branch} HBSD_BRANCH `echo ${i} | cut -d ':' -f 2`
		;;
		n:*)
			set_branch_specific ${_branch} HBSD_NAME_TAG `echo ${i} | cut -d ':' -f 2`
		;;
		t:*)
			set_branch_specific ${_branch} HBSD_DATE_TAG `echo ${i} | cut -d ':' -f 2`
		;;
		*)
			echo "unknown metainfo: ${i}"
		;;
		esac
	done

	info "received metainfo: "
	info "	`get_branch_specific ${_branch} CHROOT`"
	info "	`get_branch_specific ${_branch} HBSD_BRANCH`"
	info "	`get_branch_specific ${_branch} HBSD_TAG_NAME`"
	info "	`get_branch_specific ${_branch} HBSD_DATE_TAG`"
}

build_release()
{
	local _branch=$1
	local _log_name="${LOG_FILE_PREFIX}-`transform_branch_to_filename ${_branch}`"
	local _branch_info_file=`mktemp`

	cd ${HARDENEDBSD_STABLE_DIR}

	info "build(${_branch}) start"

	if [ ! -d release ]
	then
		err "missing release dir"
	fi

	cd release

	if [ ! -f release.sh ]
	then
		err "missing release.sh"
	fi

	# XXX the fd 123 based stuff is s dirt hack, to get the basic informations
	# from release.sh without parsing their output
	sh -x ./release.sh -c ${RELEASE_CONF} 9>${_branch_info_file} 1>${_log_name} 2>&1
	ret=$?

	set_branch_specific ${_branch} BUILD_INFO `cat ${_branch_info_file}`
	unlink ${_branch_info_file}

	parse_release_metainfo ${_branch}

	if [ $ret = 0 ]
	then
		info "build(${_branch}) done"
	else
		info "build(${_branch}) failed"
	fi

	return ${ret}
}

publish_release()
{
	local _branch=$1
	local _status=$2

	echo "TODO"

	if [ ${_status} = 0 ]
	then
		cat ${LOG_FILE_SHORT} | mail -c op@hardenedbsd.org -s "[DONE] HardenedBSD-stable ${_branch} RELEASE builds @${DATE}" robot@hardenedbsd.org
	else
		cat ${LOG_FILE_SHORT} | mail -c op@hardenedbsd.org -c core@hardenedbsd.org -s "[FAILED] HardenedBSD-stable ${_branch} RELEASE builds @${DATE}" robot@hardenedbsd.org
	fi
}

fixups()
{
	local _branch="$1"
	local _chroot_dir="`get_branch_specific ${_branch} CHROOT`"
	local _R_dir="${_chroot_dir}/R"

	if [ -d ${_R_dir} ]
	then
		for i in ${_R_dir}/*.{img,iso}
		do
			info "TODO: rename and sign $i"
		done
	fi
}

###############################################################################
###############################################################################

main()
{
	local _do_build=0
	local _failed_builds=0

	if [ -f ${LOCK_FILE} ]
	then
		err "lock file exists"
	fi

	trap "echo 'lockfile removed'; unlink ${LOCK_FILE}; exit 255" SIGINT

	touch ${LOCK_FILE}

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

	if [ "${old_revision_10}" != "${new_revision_10}" ] || [ "X${forced_build}" = "Xyes" ]
	then
		_do_build=$(($_do_build+1))
		prepare_branch ${BRANCH_10}
		build_release ${BRANCH_10}
		_build_status=$?
		if [ ${_build_status} != 0 ]
		then
			_failed_builds=$(($_failed_builds+1))
		fi
		publish_release ${BRANCH_10} ${_build_status}
		fixups ${BRANCH_10}
	fi

	if [ "${old_revision_current}" != "${new_revision_current}" ] || [ "X${forced_build}" = "Xyes" ]
	then
		_do_build=$(($_do_build+1))
		prepare_branch ${BRANCH_current}
		build_release ${BRANCH_current}
		_build_status=$?
		if [ ${_build_status} != 0 ]
		then
			_failed_builds=$(($_failed_builds+1))
		fi
		publish_release ${BRANCH_current} ${_build_status}
		fixups ${BRANCH_current}
	fi

	unlink ${LOCK_FILE}

	if [ ${_failed_builds} != 0 ]
	then
		return 255
	fi

	if [ ${_do_build} != 0 ]
	then
		return 0
	else
		info "no new build required, all version up to date"
		return 1
	fi
}

###############################################################################
###############################################################################

if [ "X${1}" != "XTRACKED" ]
then
	for i in ${LOG_DIR} ${LOG_DIR_INFO} ${LOG_DIR_DONE} ${LOG_DIR_FAILED}
	do
		if [ ! -d ${i} ]
		then
			mkdir -p ${i}
			if [ $? != 0 ]
			then
				err "missing log dir"
			fi
		fi
	done

	script ${LOG_FILE} ${0} TRACKED ${DATE} ${*}
	_ret=$?

	for j in ${LOG_FILE_PREFIX}*
	do
		case ${_ret} in
			0)
				mv ${j} ${LOG_DIR_DONE}
				;;
			1)
				mv ${j} ${LOG_DIR_INFO}
				;;
			*)
				mv ${j} ${LOG_DIR_FAILED}
				;;
		esac
	done

else
	DATE=${2}

	if [ "X${3}" = "Xforced_build" ]
	then
		forced_build="yes"
	fi

	main
fi

