#!/usr/bin/env tcsh

set TEST_NAME = "test-map32bit-allow1"
set TEST_DIR = "/tmp/pax-tests/${USER}/map32bit/"
set ORIG_STATUS = `sysctl -n hardening.pax.disallow_map32bit.status`
set ORIG_RAND = `sysctl -n hardening.pax.aslr.map32bit_len`

echo "${TEST_NAME}"

test -d ${TEST_DIR} || mkdir -p ${TEST_DIR}
cd ${TEST_DIR}

cat > ${TEST_NAME}.c<<__EOF
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <sys/types.h>
#include <sys/mman.h>

#define MAP_FLAG MAP_32BIT

int main(int argc, char *argv[])
{
        void *p;

        p = mmap(NULL, 4096, PROT_READ, MAP_SHARED | MAP_ANONYMOUS | MAP_FLAG, -1, 0);
        if (p == MAP_FAILED)
                perror("mmap");

        printf("%d: p: %p\n", getpid(), p);

        if (p)
                munmap(p, 4096);

        return 0;
}
__EOF

make ${TEST_NAME}

cat > ${TEST_DIR}/secadm.rules<<__EOF
{
        "applications": [
                {
                        path: "${TEST_DIR}/${TEST_NAME}",
                        features: {
				"disallow_map32bit" : false,
                        }
                }
	]
}
__EOF

# set opt-out
sysctl hardening.pax.disallow_map32bit.status=2
secadm flush
secadm -c ${TEST_DIR}/secadm.rules set

sysctl hardening.pax.aslr.map32bit_len=18
repeat 6 ./${TEST_NAME}

sysctl hardening.pax.aslr.map32bit_len=24
repeat 6 ./${TEST_NAME}

# restore system policy
secadm flush
secadm set
sysctl hardening.pax.disallow_map32bit.status=${ORIG_STATUS}
sysctl hardening.pax.aslr.map32bit_len=${ORIG_RAND}
