# VINNIX
Vincente's Imitation Unix (VINNIX) is a Real Time Executive (RTEX) for the 6809 that allows cooperative multitasking with "TASKS" writen in C.
This executive is based on the 6800 Real Time Executive originally supplied with Motorola Real Time FORTRAN, 
then was enhanced and adapted to the Wintek C cross-compiler interface by Vincente D'Ingianni, II in 1988-1989

# VIOS
Vincente's Input Output System (VIOS) is a set of 6809 Interrupt based IO routines for the 6850 ACIA.
VIOS includes implementations of getc(), putc(), getchar(), and putchar() for use with VINNIX and the Wintek 6809 C cross-compiler.

These files are assembled by the Wintek 6809 cross-assembler into *relocatable* S-Records, then linked via the Wintek linker.

These were the basis of Binary Systems's Annunciator / SCADA systems in the late 1980s.
