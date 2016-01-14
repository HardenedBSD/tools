#!/bin/csh

set _push="$1"

foreach i ( `git tag -l '2*'` opnsense-hbsd-2015-05-10_01 opnsense-hbsd-2015-05-14_01 hardenedbsd-master-20140912-1 )
	if ( ${_push} == "push" ) then
		git push origin :$i
	endif
	git tag -d $i
end
