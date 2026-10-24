#include	<c:\include\stdio.h>

#define		_WINTEK
#include	<c:\include\map.h>

#include	<vinnix.h>


char	ACK;

main()
{
  EXTERN HANDLER	acia1;
  EXTERN HANDLER	ack;
  EXTERN TASK		tick;
  EXTERN TASK		test;

  char		c;
  unsigned int	address;

  poke(PIA1A+2, 0x00);
  poke(PIA1A,   0xFF);
  poke(PIA1A+2, 0x5 );
  poke(PIA2A+2, 0x5 );
  clrio(ACIA1);

  setrt(PIA2A+2, WDT, WDTMSK);
  attch(&acia1, ACIA1, 0x80);
  attch(&ack, PIA1A+2, 0x80);
  start(&tick, 0, 0);
  start(&test, 0, 0);

  next(); 
} 