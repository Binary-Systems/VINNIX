/* *  Master Memory Configuration Declaration File   * */
/*     By Vincente D'Ingianni Jr.  1/5/89              */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * */


#ifdef	_WINTEK
/* *  Wintek 6809 Control Module Memory Map  * */

#define	RAMstr	0x0000	/* Beginning of RAM */
#define	RAMend	0x0FFF	/* End of RAM */

/* 6821 Peripheral Interface Adapters */
#define	PIA1A	0x1280
#define	PIA1B	0x1281
#define	PIA2A	0x1300
#define	PIA2B	0x1301

/* 6850 Asynchronous Communication Interface Adapters */
#define	ACIA1	0x1140
#define	ACIA2	0x1180
#endif


#ifdef _MIKUL3
/* *  MIKUL 6809-3 Rev. 5 Monocard Microcomputer  * */

#define	RAMstr	0x0000	/* Beginning of RAM */
#define RAMend	0x0FFF	/* End of RAM */

/* 6821 Peripheral Interface Adapters */
#define PIA1A	0x8400
#define	PIA1B	0x8401
#define	PIA2A	0x8408
#define	PIA2B	0x8409

/* Programable Timer */
#define PTM	0x8410

/* 6850 Asynchronous Communication Interface Adapters */
#define	ACIA	0x8418
#endif


#ifdef	_EXOR
/* *  Motorolla 6809 EXORCISER  * */

#endif

#ifdef	_Z80SIO
/* *  MIKUL 6883 8 Channel Asynchronous Modem Interface  * */
#define	SIO0A	0x8600
#define SIO0B	0x8602
#define SIO1A	0x8604
#define	SIO1B	0x8606

#define SIO2A	0x8608
#define SIO2B	0x860A
#define	SIO3A	0x860C
#define	SIO3B	0x860E
#endif
