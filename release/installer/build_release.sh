#!/usr/bin/env sh

#
# TODO
# ----
# proper logging
# error recovery
#

PATH=${PATH}:/usr/local/bin
export PATH

DATE=`date "+%Y%m%d%H%M%S"`

BRANCH_10="hardened/10-stable/master"
BRANCH_11="hardened/11-stable/master"
BRANCH_12="hardened/12-stable/master"
BRANCH_current="hardened/current/master"

RELESE_BASE_DIR="/usr/data/release"

LOG_DIR="${RELESE_BASE_DIR}/logs"
LOG_DIR_INFO="${LOG_DIR}/info"
LOG_DIR_DONE="${LOG_DIR}/done"
LOG_DIR_FAILED="${LOG_DIR}/failed"
LOG_FILE_PREFIX="${LOG_DIR}/${DATE}"
LOG_FILE="${LOG_FILE_PREFIX}.log"
LOG_FILE_SHORT="${LOG_DIR}/${DATE}.slog"

SOURCES_DIR="${RELESE_BASE_DIR}/git"
LOCK_DIR="${SOURCES_DIR}"
LOCK_FILE="${LOCK_DIR}/hardenedbsd-stable-repo-lock"
SOURCES_REPO="https://github.com/HardenedBSD"
HARDENEDBSD_STABLE_DIR="${SOURCES_DIR}/hardenedBSD-stable.git"
HARDENEDBSD_STABLE_REPO="${SOURCES_REPO}/hardenedBSD-stable.git"
HARDENEDBSD_TOOLS_DIR="${SOURCES_DIR}/tools.git"
HARDENEDBSD_TOOLS_REPO="${SOURCES_REPO}/tools.git"
RELEASE_CONF="${SOURCES_DIR}/tools.git/release/release-confs/HardenedBSD-stable-autodetect-git-release.conf"
SIGN_COMMAND="/root/bin/hbsd_sign.csh"

INSTALLER_SETS_BASE="${RELESE_BASE_DIR}/releases"
INSTALLER_SETS_RELEASE_DIR="./pub/HardenedBSD/releases/amd64/amd64"
INSTALLER_SETS_ISO_DIR="./pub/HardenedBSD/releases/amd64/amd64/ISO-IMAGES"
WWW_HOOKS_DIR="${RELESE_BASE_DIR}/www/"

# set reply-to to robot in mail command
REPLYTO="robot@hardenedbsd.org"
export REPLYTO

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

	info "build(${_branch}) received metainfo: "
	info "	`get_branch_specific ${_branch} CHROOT`"
	info "	`get_branch_specific ${_branch} HBSD_BRANCH`"
	info "	`get_branch_specific ${_branch} HBSD_NAME_TAG`"
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

fixups()
{
	local _branch="$1"
	local _chroot_dir="`get_branch_specific ${_branch} CHROOT`"
	local _hbsd_name_tag="`get_branch_specific ${_branch} HBSD_NAME_TAG`"
	local _R_dir="${_chroot_dir}/R"

	if [ -d ${_R_dir} ]
	then
		set_branch_specific ${_branch} RELEASE_DIR "${_R_dir}"

		for i in $(find ${_R_dir} -name "*.iso" -or -name "*.img")
		do
			local _new_name=`echo ${i} | sed "s/\(.*\)FreeBSD.*HBSD\(.*\)/\1${_hbsd_name_tag}\2/g"`
			mv -v ${i} ${_new_name}
		done

		for i in $(find ${_R_dir} -depth 1 -name "CHECKSUM*")
		do
			sed -i '' -e "s/\(.*\)FreeBSD.*HBSD\(.*\)/\1${_hbsd_name_tag}\2/g" ${i}
		done
	fi
}

publish_release()
{
	local _branch=$1
	local _status=$2
	local _last_build_from_branch="`transform_branch_to_filename ${_branch}`-LAST"
	local _hbsd_name_tag="`get_branch_specific ${_branch} HBSD_NAME_TAG`"
	local _hbsd_date_tag="`get_branch_specific ${_branch} HBSD_DATE_TAG`"
	local _installer_sets_iso_dir="${INSTALLER_SETS_ISO_DIR}/${_hbsd_name_tag}"
	local _installer_sets_iso_dir_symlink="${INSTALLER_SETS_ISO_DIR}/${_hbsd_date_tag}"
	local _installer_sets_dist_dir="${INSTALLER_SETS_RELEASE_DIR}/${_hbsd_name_tag}"
	local _installer_sets_dist_dir_symlink="${INSTALLER_SETS_RELEASE_DIR}/${_hbsd_date_tag}"
	local _installer_sets_dist_dir_last_symlink="${INSTALLER_SETS_RELEASE_DIR}/${_hbsd_date_tag%-*-*}-LAST"
	local _R_dir="`get_branch_specific ${_branch} RELEASE_DIR`"

	if [ ${_status} = 0 ]
	then
		set old_pwd=${PWD}

		if [ ! -d ${INSTALLER_SETS_BASE} ]
		then
			mkdir -p ${INSTALLER_SETS_BASE}
		fi

		cd ${INSTALLER_SETS_BASE}

		for i in ${INSTALLER_SETS_ISO_DIR} ${INSTALLER_SETS_RELEASE_DIR}
		do
			if [ ! -d ${i} ]
			then
				mkdir -p ${i}
			fi
		done

		# XXX: first we should move the ftp directory
		# because after the move only the iso files are left.
		#
		# The symlink points to the _hbsd_name_tag named directory in _installer_sets_dist_dir.
		mv -v ${_R_dir}/ftp ${_installer_sets_dist_dir}
		ln -vsf ./${_hbsd_name_tag} ${_installer_sets_dist_dir_symlink}

		# XXX: in theory only the iso, img, and checksum file are in the R directory.
		#
		# The symlink points to the _hbsd_name_tag named directory in _installer_sets_iso_dir.
		mv -v ${_R_dir} ${_installer_sets_iso_dir}
		ln -vsf ./${_hbsd_name_tag} ${_installer_sets_iso_dir_symlink}

		# This is required by bootonly medium.
		#
		# The symlink points to the _hbsd_name_tag named directory in _installer_sets_dist_dir.
		unlink ${_installer_sets_dist_dir_last_symlink}
		ln -vsf ./${_hbsd_name_tag} ${_installer_sets_dist_dir_last_symlink}

		# Sign the MANIFEST file and the CHECKSUM.*
		if [ -e ${SIGN_COMMAND} ]
		then
			find ${_installer_sets_iso_dir} -name "CHECKSUM.*" -type f -exec ${SIGN_COMMAND} {} \;
			find ${_installer_sets_dist_dir} -name "MANIFEST" -type f -exec ${SIGN_COMMAND} {} \;
		fi

		# Log out the newly generated ISOs checksums.
		for i in `find ${_installer_sets_iso_dir} -name "CHECKSUM.*" -type f`
		do
			info "build(${_branch}) `basename ${i}`:"
			cat $i | while read line
			do
				info "  ${line}"
			done
		done

		cd ${old_pwd}

		if [ -d ${WWW_HOOKS_DIR} ]
		then
			# This is for installer.hardenedbsd.org's main page's last links.
			#
			# The symlink points to the last _installer_sets_iso_dir directory in WWW_HOOKS_DIR.
			unlink ${WWW_HOOKS_DIR}/${_last_build_from_branch}
			ln -vsf ${INSTALLER_SETS_BASE}/${_installer_sets_iso_dir} ${WWW_HOOKS_DIR}/${_last_build_from_branch}
		fi

		cat ${LOG_FILE_SHORT} | mail -c op@hardenedbsd.org -c core@hardenedbsd.org -s "[DONE] HardenedBSD-stable ${_branch} ${_hbsd_date_tag} ${_hbsd_name_tag} RELEASE builds @${DATE}" robot@hardenedbsd.org
	else
		cat ${LOG_FILE_SHORT} | mail -c op@hardenedbsd.org -c core@hardenedbsd.org -s "[FAILED] HardenedBSD-stable ${_branch} ${_hbsd_date_tag} ${_hbsd_name_tag} RELEASE builds @${DATE}" robot@hardenedbsd.org
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
	old_revision_11=`get_revision origin/${BRANCH_11}`
	old_revision_12=`get_revision origin/${BRANCH_12}`
	old_revision_current=`get_revision origin/${BRANCH_current}`

	git fetch origin

	new_revision_10=`get_revision origin/${BRANCH_10}`
	new_revision_11=`get_revision origin/${BRANCH_11}`
	new_revision_12=`get_revision origin/${BRANCH_12}`
	new_revision_current=`get_revision origin/${BRANCH_current}`

	info "10-STABLE revisions: old ${old_revision_10} new ${new_revision_10}"
	info "11-STABLE revisions: old ${old_revision_11} new ${new_revision_11}"
	info "12-STABLE revisions: old ${old_revision_12} new ${new_revision_12}"
	info "13-CURRENT revisions: old ${old_revision_current} new ${new_revision_current}"

	if [ "${old_revision_10}" != "${new_revision_10}" ] || [ "X${forced_build}" = "Xyes" ] || [ "X${forced_build}" = "X10-stable" ]
	then
		_do_build=$(($_do_build+1))
		prepare_branch ${BRANCH_10}
		build_release ${BRANCH_10}
		_build_status=$?
		if [ ${_build_status} != 0 ]
		then
			_failed_builds=$(($_failed_builds+1))
		fi
		fixups ${BRANCH_10}
		publish_release ${BRANCH_10} ${_build_status}
	fi

	if [ "${old_revision_11}" != "${new_revision_11}" ] || [ "X${forced_build}" = "Xyes" ] || [ "X${forced_build}" = "X11-stable" ]
	then
		_do_build=$(($_do_build+1))
		prepare_branch ${BRANCH_11}
		build_release ${BRANCH_11}
		_build_status=$?
		if [ ${_build_status} != 0 ]
		then
			_failed_builds=$(($_failed_builds+1))
		fi
		fixups ${BRANCH_11}
		publish_release ${BRANCH_11} ${_build_status}
	fi

	if [ "${old_revision_12}" != "${new_revision_12}" ] || [ "X${forced_build}" = "Xyes" ] || [ "X${forced_build}" = "X12-stable" ]
	then
		_do_build=$(($_do_build+1))
		prepare_branch ${BRANCH_12}
		build_release ${BRANCH_12}
		_build_status=$?
		if [ ${_build_status} != 0 ]
		then
			_failed_builds=$(($_failed_builds+1))
		fi
		fixups ${BRANCH_12}
		publish_release ${BRANCH_12} ${_build_status}
	fi

	if [ "${old_revision_current}" != "${new_revision_current}" ] || [ "X${forced_build}" = "Xyes" ] || [ "X${forced_build}" = "Xcurrent" ]
	then
		_do_build=$(($_do_build+1))
		prepare_branch ${BRANCH_current}
		build_release ${BRANCH_current}
		_build_status=$?
		if [ ${_build_status} != 0 ]
		then
			_failed_builds=$(($_failed_builds+1))
		fi
		fixups ${BRANCH_current}
		publish_release ${BRANCH_current} ${_build_status}
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

	script -qa ${LOG_FILE} ${0} TRACKED ${DATE} ${*}
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

	if [ "X${3}" != "X" ]
	then
		case ${3} in
		forced_build)
			forced_build="yes"
			;;
		forced_build:*)
				_branch="`echo ${3} | cut -d ':' -f 2`"
				case ${_branch} in
				10-stable)
					forced_build="10-stable"
					;;
				11-stable)
					forced_build="11-stable"
					;;
				12-stable)
					forced_build="12-stable"
					;;
				current)
					forced_build="current"
					;;
				*)
					warn "valid targets: 10-stable, 11-stable, 12-stable, current"
					err "unknown forced build target: ${_branch}"
				esac
				info "forced build: ${forced_build}"
			;;
		*)
				warn "usage: ${0} [forced_build|forced_build:10-stable|forced_build:11-stable|forced_build:12-stable|forced_build:current]"
				err "unknown parameter: ${3}"
			;;
		esac

	fi

	main
fi

