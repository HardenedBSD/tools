#!/usr/bin/env tcsh

set URL_TEMPLATE="https://installer.hardenedbsd.org/pub/HardenedBSD/releases/amd64/amd64/ISO-IMAGES/"
set VERSION=`basename $PWD`

if ${VERSION} !~ "HardenedBSD-*" then
	echo "Wrong directory, failed to detect release version"
	exit 1
endif

foreach file ( CHECKSUM.SHA512 CHECKSUM.SHA512.asc )
	fetch -o ${file} "${URL_TEMPLATE}/${VERSION}/${file}"
	ln -v ${file}{,.txt}
end
