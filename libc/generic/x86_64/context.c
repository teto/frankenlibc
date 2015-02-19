#include <stdlib.h>
#include <ucontext.h>

/* does not need to do anything */
int
getcontext(ucontext_t *ucp)
{

	return 0;
}

void
makecontext(ucontext_t *ucp, void (*fn)(void), int argc, void *arg)
{
	unsigned long stack = (unsigned long) ucp->uc_stack.ss_sp;
	unsigned long stack_size = ucp->uc_stack.ss_size;

	if (argc != 1) abort();

	/* need to push stack pointer, f as ip and data as first arg */
	ucp->uc_regs[6] = stack + stack_size; /* grows down */
	ucp->uc_regs[7] = (unsigned long) fn;
	ucp->uc_regs[8] = (unsigned long) arg;
}
