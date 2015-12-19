#!/bin/tcsh

set TEST_NAME = "test-map32bit-allow2"
set TEST_DIR = "/tmp/pax-tests/${USER}/map32bit/"

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

sysctl hardening.pax.disallow_map32bit.status=1
secadm flush
repeat 6 ./${TEST_NAME}

# restore system policy
secadm set
