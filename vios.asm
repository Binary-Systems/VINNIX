*****************************************************************************
*
	TTL	"Vinnie's Input/Ouput System"
	NAM	VIOS
*
*   Copyright (c) 1988-2020 Binary Systems, Inc.
*   All Rights Reserved
*
*   6809 Interrupt based IO routines for the 6850 ACIA.
*
*   Implementations of getc(), putc(), getchar(), and putchar()
*   for use with VINNIX and the Wintek 6809 C cross-compiler.
*
*   This file is assembled by the Wintek 6809 cross-assembler into
*   *relocatable* S-Records, then linked via the Wintek linker.
*
*****************************************************************************

	GLOBAL	acia1,ACIA1$
	GLOBAL  acia2,ACIA2$
	GLOBAL	clrio,getc,putc,getchar,putchar,PUTCHAR2
	GLOBAL	stdin,stdout,stderr,auxin,auxout,EOF

	EXTERN	.LINK

_WINTEK	EQU	1
_MIKUL3	EQU	0
_RTEX	EQU	0
_GADFLY EQU	1	set to use gadflg insteads of interrupt.

	OPT	NOLIST
	INCLUDE	"c:\include\map.ah"
	OPT	LIST

	INCLUDE	"c:\include\stdio.ah"

	IFNE	_RTEX
	OPT	NOLIST
	INCLUDE	"c:\include\vinnix.ah"
	OPT	LIST
	ENDC

	INCLUDE "c:\include\vios.ah"


		DSCT
ACIA1st		RMB	1

TXQUE1		RMB	TXLEN
TXHEAD1		RMB	1
TXTAIL1		RMB	1
TXCOUNT1	RMB	1

RXQUE1		RMB	RXLEN
RXHEAD1		RMB	1
RXTAIL1		RMB	1
RXCOUNT1	RMB	1


ACIA2st		RMB	1

TXQUE2		RMB	TXLEN
TXHEAD2		RMB	1
TXTAIL2		RMB	1
TXCOUNT2	RMB	1

RXQUE2		RMB	RXLEN
RXHEAD2		RMB	1
RXTAIL2		RMB	1
RXCOUNT2	RMB	1



	PSCT
clrio	SUBA	#2
	BEQ	clrio1
	JSR	.LINK

clrio1	PULS	X
	PULS	D
	PSHS	X
	TFR	D,X
	LDA	#$03
	STA	0,X
	LDA	#$15	95
	STA	0,X
	STA	ACIA1st
	STA	ACIA2st
	CLRD
	RTS


getc	SUBA	#2
	BEQ	getc1
	JSR	.LINK

getc1	LDB	3,S
	CMPB	#stdin
	BNE	getc2

getc1_1	JSR	GETCHAR1
	IFNE	_RTEX
	TRAP	WAITZ
	ENDC
	BEQ	getc1_1
	CMPB	#CR
	BNE	getc1_2
	LDB	#LF
	BRA	getc1_3

getc1_2	CMPB	#CTRLD
	BNE	getc1_3
	LDD	#EOF
	BRA	getc9

getc1_3	PSHS	D
	PSHS	D
	LDD	#stdout
	PSHS	D
	JSR	putc0
	BRA	getc9

getc2	CMPB	#auxin
	BNE	getc9

getc2_1	JSR	GETCHAR2
	IFNE	_RTEX
	TRAP	WAITZ
	ENDC
	BEQ	getc2_1
	CMPB	#CR
	BNE	getc2_2
	LDB	#LF
	BRA	getc2_3

getc2_2	CMPB	#CTRLD
	BNE	getc2_3
	LDD	#EOF
	BRA	getc9

getc2_3	PSHS	D
	PSHS	D
	LDD	#auxout
	PSHS	D
	JSR	putc0

getc9	PULS	D
	PULS	X
	LEAS	2,S		Does not affect Z bit.
	JMP	0,X


putc	SUBA	#4
	BEQ	putc0
	JSR	.LINK

putc0	LDB	5,S
	LDA	3,S

putc1	CMPA	#stdout
	BNE	putc2
	PSHS	D
	JSR	PUTCHAR1
	BRA	putc3

putc2	CMPA	#auxout
	BNE	putc9
	PSHS	D
	JSR	PUTCHAR2

putc3	EQU	*
	IFNE	_RTEX
	TRAP	WAITZ
	ENDC
	BMI	putc0

putc4	CMPB	#LF
	BNE	putc9

putc4_1	LDB	#CR
	LDA	3,S

	CMPA	#stdout
	BNE	putc5
	PSHS	D
	JSR	PUTCHAR1
	BRA	putc6

putc5	CMPA	#auxout
	BNE	putc9
	PSHS	D
	JSR	PUTCHAR2

putc6	EQU	*
	IFNE	_RTEX
	TRAP	WAITZ
	ENDC
	BMI	putc4_1

putc9	PULS	X
	LEAS	4,S
	JMP	0,X


	PSCT
acia1	EQU	*
ACIA1$	BITA	#1		Is the recieve register full?
	BNE	ACIA1$1		  Yes, it must be an RX interrupt.
	BITA	#2		  No, but is  the transmit data register empty?
	BNE	ACIA1TX		    Yes, it is empty.  So TX that data!
	RTS			  False alarm.

ACIA1$1	BITA	#$70		Errors?
	BEQ	ACIA1RX		  None, so RX that data!
	LDA	ACIA1+1		  Yes, disregard and return.
	RTS

ACIA1RX	LDB	RXCOUNT1	If queue is full,
	CMPB	#RXLEN
	BLT	ACIA1R1
	LDB	ACIA1st		  then disable RX interrupt
	ANDB	#%01111111
	STB	ACIA1st
	STB	ACIA1
	LDA	ACIA1+1
	RTS			    and return.

ACIA1R1	LDA	ACIA1+1		  Else get new char from ACIA status reg.
	ANDA	#%01111111	    Strip the parity bit just incase!
	LDB	RXTAIL1		    Get tail of RX queue.
	LDX	#RXQUE1		    Store the char at the end of the queue.
	STA	B,X
	INCB			    Increment the tail.
	STB	RXTAIL1
	INC	RXCOUNT1	    Increment the queue count.
	CMPB	#RXLEN		    If tail>length,
	BLT	ACIA1R2
	CLR	RXTAIL1		      then tail=0.
ACIA1R2	RTS			    Return

ACIA1TX	TST	TXCOUNT1	If TX queue is empty,
	BNE	ACIA1T1
	LDB	ACIA1st		  then disable the TX interrupt
	ANDB	#$9F
	STB	ACIA1st
	STB	ACIA1
	RTS			  and return.

ACIA1T1	LDB	TXHEAD1		  Else get char from head of queue.
	LDX	#TXQUE1
	LDA	B,X
	STA	ACIA1+1		    Send it out of the ACIA.
	DEC	TXCOUNT1	    Decrement the queue count.
	INCB			    Increment the head.
	STB	TXHEAD1
	CMPB	#TXLEN		    If head>length,
	BLT	ACIA1T2
	CLR	TXHEAD1		      then head=0
ACIA1T2	RTS			    Return.


		PSCT
getchar		SUBA	#0
		BEQ	GETCHAR1
		JSR	.LINK

GETCHAR1	TST	RXCOUNT1
		BNE	GETCH1_1
		CLRD
		BRA	GETCH1_5
GETCH1_1	LDA	RXHEAD1
		LDX	#RXQUE1
		LDB	A,X
		INCA
		STA	RXHEAD1
		CMPA	#RXLEN
		BLT	GETCH1_2
		CLR	RXHEAD1	

GETCH1_2	DEC	RXCOUNT1
		LDA	ACIA1st
		ORA	#$80
		STA	ACIA1st
		STA	ACIA1
		CLRA
GETCH1_5	TSTB
		RTS


		PSCT
putchar		SUBA	#2
		BEQ	PUTCHAR1
		JSR	.LINK

	IFNE	_GADFLY
PUTCHAR1	LDA	ACIA1
		ANDA	#$2
		BEQ	PUTCHAR1
		PULS	X
		LDD	,S++
		STB	ACIA1+1
		SUBD	#0
		JMP	,X
	ENDC

	IFEQ	_GADFLY
PUTCHAR1	LDB	3,S
		LDA	TXCOUNT1
		CMPA	#TXLEN
		BLT	PUTCH1_1
		PULS	X
		LEAS	2,S
		LDD	#EOF
		JMP	0,X

PUTCH1_1	LDA	TXTAIL1
		LDX	#TXQUE1
		STB	A,X
		INCA
		STA	TXTAIL1
		CMPA	#TXLEN
		BLT	PUTCH1_2
		CLR	TXTAIL1
PUTCH1_2	INC	TXCOUNT1
		LDA	ACIA1st
		ORA	#$20
		STA	ACIA1st
		STA	ACIA1
PUTCH1_3	PULS	X		Part of a goofy RTS.
		LDD	,S++		Recover D and set the condition codes.
		JMP	0,X		A goofy RTS.
	ENDC


	PSCT
acia2	EQU	*
ACIA2$	BITA	#1		Is the recieve register full?
	BNE	ACIA2$1		  Yes, it must be an RX interrupt.
	BITA	#2		  No, but is  the transmit data register empty?
	BNE	ACIA2TX		    Yes, it is empty.  So TX that data!
	RTS			  False alarm.

ACIA2$1	BITA	#$70		Errors?
	BEQ	ACIA2RX		  None, so RX that data!
	LDA	ACIA2+1		  Yes, disregard and return.
	RTS

ACIA2RX	LDB	RXCOUNT2	If queue is full,
	CMPB	#RXLEN
	BLT	ACIA2R1
	LDB	ACIA2st		  then disable RX interrupt
	ANDB	#%01111111
	STB	ACIA2st
	STB	ACIA2
	LDA	ACIA2+1
	RTS			    and return.

ACIA2R1	LDA	ACIA2+1		  Else get new char from ACIA status reg.
	ANDA	#%01111111	    Strip the parity bit just incase!
	LDB	RXTAIL2		    Get tail of RX queue.
	LDX	#RXQUE2		    Store the char at the end of the queue.
	STA	B,X
	INCB			    Increment the tail.
	STB	RXTAIL2
	INC	RXCOUNT2		    Increment the queue count.
	CMPB	#RXLEN		    If tail>length,
	BLT	ACIA2R2
	CLR	RXTAIL2		      then tail=0.
ACIA2R2	RTS			    Return

ACIA2TX	TST	TXCOUNT2	If TX queue is empty,
	BNE	ACIA2T1
	LDB	ACIA2st		  then disable the TX interrupt
	ANDB	#$9F
	STB	ACIA2st
	STB	ACIA2
	RTS			  and return.

ACIA2T1	LDB	TXHEAD2		  Else get char from head of queue.
	LDX	#TXQUE2
	LDA	B,X
	STA	ACIA2+1		    Send it out of the ACIA.
	DEC	TXCOUNT2	    Decrement the queue count.
	INCB			    Increment the head.
	STB	TXHEAD2
	CMPB	#TXLEN		    If head>length,
	BLT	ACIA2T2
	CLR	TXHEAD2		      then head=0
ACIA2T2	RTS			    Return.


		PSCT
GETCHAR2	TST	RXCOUNT2
		BNE	GETCH2_1
		CLRD
		BRA	GETCH2_5
GETCH2_1	LDA	RXHEAD2
		LDX	#RXQUE2
		LDB	A,X
		INCA
		STA	RXHEAD2
		CMPA	#RXLEN
		BLT	GETCH2_2
		CLR	RXHEAD2

GETCH2_2	DEC	RXCOUNT2
		LDA	ACIA2st
		ORA	#$80
		STA	ACIA2st
		STA	ACIA2
		CLRA
GETCH2_5	TSTB
		RTS


		PSCT

	IFNE	_GADFLY
PUTCHAR2	LDA	ACIA2
		ANDA	#$2
		BEQ	PUTCHAR2
		PULS	X
		LDD	,S++
		STB	ACIA2+1
		SUBD	#0
		JMP	,X
	ENDC

	IFEQ	_GADFLY
PUTCHAR2	LDB	3,S
		LDA	TXCOUNT2
		CMPA	#TXLEN
		BLT	PUTCH2_1
		PULS	X
		LEAS	2,S
		LDD	#EOF
		JMP	0,X

PUTCH2_1	LDA	TXTAIL2
		LDX	#TXQUE2
		STB	A,X
		INCA
		STA	TXTAIL2
		CMPA	#TXLEN
		BLT	PUTCH2_2
		CLR	TXTAIL2
PUTCH2_2	INC	TXCOUNT2
		LDA	ACIA2st
		ORA	#$20
		STA	ACIA2st
		STA	ACIA2
PUTCH2_3	PULS	X		Part of a goofy RTS.
		LDD	,S++		Recover D and set the condition codes.
		JMP	0,X		A goofy RTS.
	ENDC
		END
