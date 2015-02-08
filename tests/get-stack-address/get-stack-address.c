#include <sys/types.h>
#include <sys/sysctl.h>
#include <stdio.h>

u_long
get_usrstack_address(void)
{
	u_long usrstack;
	size_t len;

	len = sizeof(usrstack);
	if (sysctlbyname("kern.usrstack", &usrstack, &len, NULL, 0) == -1) {
		printf("fuck\n");
		return (0);
	}

	return (usrstack);
}

int
main(int argc, char **atgv)
{
	u_long usrstack;

	usrstack = get_usrstack_address();

	printf("%p\n", (void *)usrstack);

	return (0);
}

