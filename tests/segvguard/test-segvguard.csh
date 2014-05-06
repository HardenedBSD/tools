#!/bin/csh

set TEST_NAME = "test-segvguard"

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

mv ${TEST_NAME}{,1}
cp ${TEST_NAME}{1,2}

set a = 0
set a_max = `sysctl -n security.pax.segvguard.max_crashes`
while ($a < $a_max)
	echo ${TEST_NAME}1
	./${TEST_NAME}1
	echo ${TEST_NAME}2
	./${TEST_NAME}2
	@ a = $a + 1
end

