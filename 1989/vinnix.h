#ifndef	_vinnix
#define _vinnix
#define	STACKLEN	48

#define WDT		0x8402
#define WDTMSK		8

#define	EXTERN	extern
#define PRIVATE	static
#define PUBLIC
#define	FORWARD

typedef	int	(*TASK) ();
typedef int	(*HANDLER) ();
typedef	char	STACK;
#endif
