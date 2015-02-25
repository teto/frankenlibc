#include <stdint.h>
#include <stdlib.h>
#include <sys/types.h>

#define RUMP_SIGMODEL_IGNORE 1

void rump_boot_setsigmodel(int rump_sigmodel);
int rump_init(void);

extern char **environ;

static char empty_string[] = "";
char *__progname = empty_string;

void _libc_init(void);

int __libc_start_main(int (*)(int,char **,char **), int, char **, char **);

void _init(void) __attribute__ ((weak));
void _init() {}

extern void (*const __init_array_start)() __attribute__((weak));
extern void (*const __init_array_end)() __attribute__((weak));

int
__libc_start_main(int(*main)(int,char **,char **), int argc, char **argv, char **envp)
{
	uintptr_t a;

	environ = envp;

	if (argv[0] != NULL) {
		char *c;
		__progname = argv[0];
		for (c = argv[0]; *c; ++c) {
			if (*c == '/')
				__progname = c + 1;
		}
	}

	rump_boot_setsigmodel(RUMP_SIGMODEL_IGNORE);
	rump_init();

	_libc_init();

	_init();
	a = (uintptr_t)&__init_array_start;
	for (; a < (uintptr_t)&__init_array_end; a += sizeof(void(*)()))
		(*(void (**)())a)();

	exit(main(argc, argv, envp));
	return 0;
}