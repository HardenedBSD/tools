#!/bin/csh

#
# if the user has fork restriction,
# then we must deny any suid binary from execution
#

set TEST_NAME = "test-segvguard-suid"
set TEST_DIR = "/tmp/pax-tests/${USER}/segvguard/"

test -d ${TEST_DIR} || mkdir -p ${TEST_DIR}
cd ${TEST_DIR}

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
set a_max = `sysctl -n hardening.pax.segvguard.max_crashes`
# the last must failed
@ a_max = $a_max + 1
while ($a < $a_max)
	./${TEST_NAME}
	@ a = $a + 1
end

ping -c 1 127.0.0.1
