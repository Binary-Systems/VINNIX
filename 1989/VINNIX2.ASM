*  This version is designed to use the Z80 SIO board for i/o functions.
*  IT DOESN'T WORK YET!!!

	TTL	"VINNIX - Vinnie's Immitation UNIX"
	NAM	VINNIX

	GLOBAL	SSTACK$,RESTART$
* slice: VIOS.ASM ended at RESTART$ and VIOS.LST resumed at OBAL.
* The line break and the letters GL are not in either piece.
* Restored as a second GLOBAL, matching VINNIX.ASM.
	GLOBAL	getchar,putchar,getc,putc,out2h,out4h

	EXTERN	main,.LINK

_WINTEK		EQU	0
_MIKUL3		EQU	0
_EXOR		EQU	1
_Z80SIO		EQU	1

	INCLUDE	"c:\include\map.asm"
	INCLUDE	"c:\include\stdio.asm"
	INCLUDE "c:\include\osdef.asm"


	DSCT
	RMB	STACKLEN
SSTACK$ EQU	*

TXQUE	RMB	TXLEN
TXHEAD	RMB	1
TXTAIL	RMB	1
TXCOUNT	RMB	1

RXQUE	RMB	RXLEN
RXHEAD	RMB	1
RXTAIL	RMB	1
RXCOUNT	RMB	1

ACIAst	RMB	1


SIOTXQUE	RMB	8*TXLEN
SIOTXHEAD	RMB	8
SIOTXTAIL	RMB	8
SIOTXCNT	RMB	8
SIORXQUE	RMB	8*RXLEN
SIORXHEAD	RMB	8
SIORXTAIL	RMB	8
SIORXCNT	RMB	8

SIOWR1		RMB	8


	PSCT
RESTART$ SEI
	LDS	#SSTACK$
	LDX	#RESTART$
	STX	$FFFC
	STX	$FFFE
	LDX	#IRQ$
	STX	$FFF8
	LDA	#RAMPAG
	TFR	A,DP
	SETDP	RAMPAG

ClrRAM	LDX	#RAMstr
	CLRA
ClrRAM0	STA	0,X+
	CMPX	#RAMend+1
	BLE	ClrRAM0

	JSR	clrio

	CLI
	CLRA
	JSR	main
	JMP	RESTART$


clrio	SUBA	#0
	BEQ	clrio1
	JSR	.LINK

clrio1	LDA	#$03
	STA	ACIA
	LDA	#$95
	STA	ACIAst
	STA	ACIA

	CLRD
	RTS


* *  STASIO - This macro stores the A register to all control registers of the
* *  Z80 SIO board.

	MACR	STASIO
	STA	SIO0A+1
	STA	SIO0B+1
	STA	SIO1A+1
	STA	SIO1B+1
	STA	SIO2A+1
	STA	SIO2B+1
	STA	SIO3A+1
	STA	SIO3B+1
	ENDM


SIO_PRIORITY	EQU	0

* *  Setup Z80SIO board for S72.  * *

	PSCT
clr_sio	SUBA	#0
	BEQ	clrsio1
	JSR	.LINK

clrsio1	LDA	#0
	STASIO
	LDA	#%00011000	Reset all channels of SIO board.
	STASIO

	LDA	#2		Select register 2.
	STASIO
	LDA	#%00000000	  Set interrupt vector.
	STASIO

	LDA	#4		Select register 4.
	STASIO
	LDA	#%01001111	  Div 16, 2 stop.
	STASIO

	LDA	#1		Select register 1.
	STASIO
	LDA	#$1C		  Rec IRQ.
	STASIO

	LDA	#5		Select register 5.
	STASIO
	LDA	#%10101010	  DTR, 7 bits, no break.
	STASIO

	LDA	#3		Select register 3.
	STASIO
	LDA	#01000001	  7 bits Rx, Rx Enable.
	STASIO

	CLRD
	RTS

	
	PSCT
IRQ$	EQU	*

	IFNE	_EXOR
	JSR	PIA$
	JSR	ACIA$
	ENDC

	IFEQ	_Z80SIO		Use this if compiled with Z80 SIO board.
	JSR	SIO$		(Used in RV development software.)
	ENDC
	RTI


PIA$	TST	PIA1B+2
	BPL	PIA$1
	CLRA
*	JSR	Ack
	LDA	PIA1B

PIA$1	TST	PIA2B+2
	BPL	PIA$2
	CLRA
*	JSR	LampTest
	LDA	PIA2B
	RTS


	PSCT
ACIA$	LDA	ACIA
	BPL	ACIA$2
	BITA	#1		Is the recieve register full?
	BNE	ACIA$1		  Yes, it must be an RX interrupt.
	BITA	#2		  No, but is  the transmit data register empty?
	BNE	ACIATX		    Yes, it is empty.  So TX that data!
	RTS			  False alarm.

ACIA$1	BITA	#$70		Errors?
	BEQ	ACIARX		  None, so RX that data!
	LDA	ACIA+1		  Yes, disregard and return.
ACIA$2	RTS

ACIARX	LDB	RXCOUNT		If queue is full,
	CMPB	#RXLEN
	BLT	ACIAR1
	LDB	ACIAst		  then disable RX interrupt
	ANDB	#%01111111
	STB	ACIAst
	STB	ACIA
	LDA	ACIA+1
	RTS			    and return.

ACIAR1	LDA	ACIA+1		  Else get new char from ACIA status reg.
	ANDA	#%01111111	    Strip the parity bit just incase!
	LDB	RXTAIL		    Get tail of RX queue.
	LDX	#RXQUE		    Store the char at the end of the queue.
	STA	B,X
	INCB			    Increment the tail.
	STB	RXTAIL
	INC	RXCOUNT		    Increment the queue count.
	CMPB	#RXLEN		    If tail>length,
	BLT	ACIAR2
	CLR	RXTAIL		      then tail=0.
ACIAR2	RTS			    Return

ACIATX	TST	TXCOUNT		If TX queue is empty,
	BNE	ACIAT1
	LDB	ACIAst		  then disable the TX interrupt
	ANDB	#$9F
	STB	ACIAst
	STB	ACIA
	RTS			  and return.

ACIAT1	LDB	TXHEAD		  Else get char from head of queue.
	LDX	#TXQUE
	LDA	B,X
	STA	ACIA+1		    Send it out of the ACIA.
	DEC	TXCOUNT		    Decrement the queue count.
	INCB			    Increment the head.
	STB	TXHEAD
	CMPB	#TXLEN		    If head>length,
	BLT	ACIAT2
	CLR	TXHEAD		      then head=0
ACIAT2	RTS			    Return.


SIO$	LDX	SIO0A+1
	CLRB
SIO$0	LDA	0,X++

	BITA	#%00000001	Receive character available?
	BNE	SIO$1
	BSR	SIORX

SIO$1	BITA	#%00000100	Transmit buffer empty?
	BNE	SIO$2
	BSR	SIOTX

SIO$2	INCB			ACCB contains the queue index.
	CMPX	SIO3B+1		All chips checked?
	BLE	SIO$0		  No, check another.
	RTS

SIORX	LDY	#SIORXCNT	If queue is full,
	LDA	B,Y
	CMPA	RXLEN
	BLT	SIORX1
	LDA	#1		  disable interrupts for this channel.
	STA	0,X
	LDY	#SIOWR1
	LDA	B,Y
	ANDA	#%11100111
	STA	B,Y
	STA	0,X
	RTS

SIORX1	DEX			Get the character.
	LDA	0,X
	PSHS	D		Save the character and the index.

	LDX	#SIORXTAIL	Put the tail pointer in ACCA.
	LDA	B,X
	PSHS	A

	LDA	#RXLEN		SIORXQUE[INDEX]=RXLEN*INDEX+SIORXQUE
	MUL
	LDY	#SIORXQUE
	LEAY	D,Y
	TFR	Y,X

	PULS	A		A=SIORXTAIL, Y=SIORXQUE[INDEX]
	LEAY	A,Y		Y=SIORXQUE[INDEX][SIORXTAIL]
	PULS	D
	STA	0,Y		Put the character at the tail of the queue.

	LDY	#SIORXCNT	Increment the queue count.
	INC	B,Y

	LDY	#SIORXTAIL	Increment tail.
	LDA	B,Y
	INCA
	CMPA	#RXLEN		If tail>length
	BLT	SIORX2
	CLR	B,Y		  tail=0.
SIORX2	RTS


SIOTX	LDY	#SIORXCNT
	TST	B,Y
	BNE	SIOTX1

	LDA	#1
	STA	0,X
	LDY	#SIOWR1
	LDA	B,Y
	ANDA	#%11111101
	STA	B,Y
	STA	0,X
	RTS
	
SIOTX1	LDY	#SIORXHEAD
	LDA	B,Y
	PSHS	D		A=HEAD, B=INDEX

	LDA	#TXLEN
	MUL
	LDY	#SIOTXQUE
	LEAY	D,Y		Y=SIOTXQUE+TXLEN*INDEX
	PULS	D
	LEAY	A,Y		Y=Y+HEAD
	
	LDA	0,Y		Get char from head of queue.
	DEX
	STA	0,X		Put char in SIO data buffer.

	LDY	#SIOTXCNT	Decrement count.
	DEC	B,Y
	STA	B,Y

	LDY	#SIOTXHEAD	Increment the head.
	LDA	B,Y
	INCA
	STA	B,Y
	CMPA	#TXLEN		If head>length,
	BLT	SIOTX2
	CLR	B,Y		  head=0.
SIOTX2	RTS
	
	

	PSCT
getc	SUBA	#2
	BEQ	getc0
	JSR	.LINK

getc0	LDD	2,S
	CMPB	#iodev0
	BNE	getc1
	BSR	getACIA
	BRA	getc2

getc1	CMPB	#iodev1
	BLT	getc2
	CMPB	#iodev2
	BGT	getc2
	PSHS	D
	LDA	#2
	BSR	getSIO

getc2	PULS	X
	LEAS	2,S
	JMP	0,X
	

	PSCT
getACIA	SUBA	#0
	BEQ	getA0
	JSR	.LINK

getA00	TST	RXCOUNT
	BNE	getA1
	CLRD
	SEC
	BRA	getA5
getA1	LDA	RXHEAD
	LDX	#RXQUE
	LDB	A,X
	INCA
	STA	RXHEAD
	CMPA	#RXLEN
	BLT	getA2
	CLR	RXHEAD

getA2	DEC	RXCOUNT
	CLC
	LDA	ACIAst
	ORA	#$80
	STA	ACIAst
	STA	ACIA

getA3	CLRA
	CMPB	#CR
	BNE	getA4
	LDB	#LF
	BRA	getA5
getA4	CMPB	#CTRLD
	BNE	getA5
	LDD	#EOF
getA5	TSTB
	RTS


getSIO	SUBA	#0
	BEQ	getS0
	JSR	.LINK

getS0	LDB	2,S		Get index in ACCB.
	LDY	#SIORXCNT
	TST	B,Y
	BNE	getS1
	CLR	B,Y
	SEC
	BRA	getS5

getS1	LDY	#SIORXHEAD
	LDA	B,Y
	PSHS	D
	
	LDY	#SIORXQUE
	LDA	#RXLEN
	MUL
	LEAY	D,Y
	PULS	D
	LEAY	A,Y
	LDA	0,Y
	PSHS	A		Save character.

	LDY	#SIORXHEAD	Increment head.
	LDA	B,Y
	INCA
	STA	B,Y
	CMPA	#RXLEN
	BLT	getS
	
	PSCT
putc	SUBA	#4
	BEQ	putc0
	JSR	.LINK

putc0	LDD	4,S
putc1	PSHS	D
	LDA	#2
	BSR	putchar
	BCS	putc1
	CMPB	#LF
	BNE	putc3
	LDB	#CR
	LDA	#2
putc2	PSHS	D
	BSR	putchar
	BCS	putc2
putc3	PULS	X
	LEAS	4,S		Does not affect Z bit.
	JMP	0,X


	PSCT
putchar	SUBA	#2
	BEQ	putchr0
	JSR	.LINK

putchr0	LDB	3,S
putch00	LDA	TXCOUNT
	CMPA	#TXLEN
	BLT	putchr1
	SEC
	BRA	putchr3

putchr1	LDA	TXTAIL
	LDX	#TXQUE
	STB	A,X
	INCA
	STA	TXTAIL
	CMPA	#TXLEN
	BLT	putchr2
	CLR	TXTAIL
putchr2	INC	TXCOUNT
	CLC
	LDA	ACIAst
	ORA	#$20
	STA	ACIAst
	STA	ACIA
putchr3	PULS	X		Part of a goofy RTS.
	LDD	,S++		Recover D and set the condition codes.
	JMP	0,X		A goofy RTS.


read	SUBA	#6
	BEQ	read0
	JSR	.LINK

read0	LDA	2,S
	STA	iodev
	LDX	4,S
	STX	cbuff
	LDX	6,S
	STX	bufflen

	CMPA	#iodev0
	BNE	
	


* * *  These functions output 2 or 4 hex digits.  * * *
	PSCT
out2h	SUBA	#2
	BEQ	out2h1
	JSR	.LINK

out4h1	LDA	2,S
	JSR	OUT2H
out2h1	LDA	3,S
	JSR	OUT2H
	PULS	X
	LDD	,S++
	JMP	0,X

out4h	SUBA	#2
	BEQ	out4h1
	JSR	.LINK


*  This routine outputs a 2 digit hex number in ACC A *
OUT2H	PSHS	D
	LDB	#16
	MUL
	BSR	OUTHX
	PULS	D
	ANDA	#$0F
OUTHX	ADDA	#$90
	DAA
	ADCA	#$40
	DAA
	EXG	A,B
	PSHS	D
	CLRD
	PSHS	D
	LDA	#4
	JSR	putc
	RTS


	PSCT
INCH	LDB	ACIAst
	ANDB	#%01111111
	STB	ACIAst
	STB	ACIA
INCH1	LDB	ACIA
	LSRB
	BCC	INCH
	LDB	ACIA+1
	PSHS	B
	LDB	ACIAst
	ORB	#%10000000
	STB	ACIAst
	STB	ACIA
	PULS	B
	RTS


	PSCT
OUTCH	PSHS	D
	LDB	ACIAst
	PSHS	B
	ANDB	#%10011111
	STB	ACIAst
	STB	ACIA
	LDA	#2
OUTCH1	BITA	ACIA
	BEQ	OUTCH1
	STB	ACIA+1
	PULS	B
	STB	ACIAst
	STB	ACIA
	PULS	D
	RTS


	ASCT
	ORG	$FFF2
VECTOR$	EQU	*

	FDB	0		Software Interrupt #3
	FDB	0		Software Interrupt #2
	FDB	0		Fast Interrupt Request
	FDB	IRQ$		Interrupt Request
	FDB	0		Software Interrupt
	FDB	RESTART$	Non-Maskable Interrupt
	FDB	RESTART$	Restart

	end
