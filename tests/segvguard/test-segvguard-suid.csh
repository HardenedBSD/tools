#!/bin/csh

#
# if the user has fork restriction,
# then we must deny any suid binary from execution
#

set TEST_NAME = "test-segvguard-suid"

cd /tmp

cat > ${TEST_NAME}.c<<__EOF
#include <stdio.h>

int
main(int argc, char **argv)
{
	volatile long *p=NULL;

	printf(":P\n");

	return (*p);
}
__EOF

make ${TEST_NAME}

set a = 0
set a_max = `sysctl -n security.pax.segvguard.max_crashes`
while ($a < $a_max)
	./${TEST_NAME}
	@ a = $a + 1
end

ping -c 1 127.0.0.1
