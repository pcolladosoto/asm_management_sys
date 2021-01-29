#include <stdio.h>
#include <unistd.h>

int main(void){
	// char* my_argv[] = {"cat", "foo.c",  NULL};
	char* my_argv[] = {"tput", "-T", "xterm", "clear", NULL};
	char* clear_argv[] = {"clear", NULL};

	// char* my_env[] = {"TERM='xterm-256color'", NULL};
	char* my_env[] = {NULL};
        /* if (fork()) {
            sleep(5);
            return 0;
        }*/
	execve("/usr/bin/tput", my_argv, my_env);
	// execl("/usr/bin/clear", "clear");
	// execve("/bin/cat", my_argv, my_env)
	// execve("/usr/bin/clear", clear_argv, NULL);

}
