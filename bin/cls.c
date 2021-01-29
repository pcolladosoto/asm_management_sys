#include <unistd.h>

int main(void){
	char* my_argv[] = {"tput", "-T", "xterm", "clear", NULL};
	char* my_env[] = {NULL};
	execve("/usr/bin/tput", my_argv, my_env);
}
