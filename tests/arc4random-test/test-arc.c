/*
 * http://insanecoding.blogspot.ie/2014/05/libressl-porting-update.html
 *
 * link by David (devnexen)
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <sys/wait.h>

int main()
{
	int children = 3;
	pid_t pid = getpid();

	printf("parent process %08x: %08x %08x\n",
	    (uint32_t)pid, arc4random(), arc4random());
	fflush(stdout);

	while (children--) {
		pid_t pid = fork();
		if (pid > 0) {
			// Parent
			waitpid(pid, 0, 0);
		} else if (pid == 0) {
			// Child
			pid = getpid();
			printf(" child process %08x: %08x %08x\n",
			    (uint32_t)pid, arc4random(), arc4random());
			fflush(stdout);
			_exit(0);
		} else {
			// Error
			perror(0);
			break;
		}
	}
	printf("parent process %08x: %08x %08x\n", (uint32_t)pid, arc4random(), arc4random());
	fflush(stdout);

	return(0);
}
