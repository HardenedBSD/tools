#!/bin/csh

#
# seems like the microtime resolution
# is not enught in many cases...
#

set TEST_NAME = "test-segvguard-sigkill"
set TEST_DIR = "/tmp/pax-tests/${USER}/segvguard/"

test -d ${TEST_DIR} || mkdir -p ${TEST_DIR}
cd ${TEST_DIR}

cat > ${TEST_NAME}.c<<__EOF
#include <stdio.h>
#include <unistd.h>

int
main(int argc, char **argv)
{
	printf("sleep 5\n");
	sleep(5);

	return (0);
}
__EOF

make ${TEST_NAME}

set a = 0
set a_max = `sysctl -n hardening.pax.segvguard.max_crashes`
# the last must failed
@ a_max = $a_max 
while ($a < $a_max)
	./${TEST_NAME}&
	kill -KILL $!
	@ a = $a + 1
end

./${TEST_NAME}
