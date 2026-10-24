	TTL	"VINNIX - Vinnie's Immitation UNIX"
	NAM	VINNIX

	GLOBAL	SSTACK$,RESTART$,IRQ$,ACIA$,VECTOR$
	GLOBAL	getchar,putchar,getc,putc,out2h,out4h

	EXTERN	main,.LINK

_WINTEK		EQU	0
_MIKUL3		EQU	1

	INCLUDE	"c:\include\map.ah"
	INCLUDE	"c:\include\stdio.ah"
	INCLUDE "c:\include\osdef.ah"


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


	PSCT
IRQ$	TST	PIA1B+2
	BPL	IRQ0
	CLRA
*	JSR	Ack
	LDA	PIA1B

IRQ0	TST	PIA2B+2
	BPL	IRQ1
	CLRA
*	JSR	LampTest
	LDA	PIA2B

IRQ1	LDA	ACIA
	BPL	IRQ2
	BSR	ACIA$
IRQ2	RTI


	PSCT
ACIA$	BITA	#1		Is the recieve register full?
	BNE	ACIA$1		  Yes, it must be an RX interrupt.
	BITA	#2		  No, but is  the transmit data register empty?
	BNE	ACIATX		    Yes, it is empty.  So TX that data!
	RTS			  False alarm.

ACIA$1	BITA	#$70		Errors?
	BEQ	ACIARX		  None, so RX that data!
	LDA	ACIA+1		  Yes, disregard and return.
	RTS

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


	PSCT
getc	SUBA	#2
	BEQ	getc0
	JSR	.LINK

getc0	BSR	getchr0
	BCS	getc0
	PSHS	D
	LDA	#2
	BSR	putchar
	PULS	X
	LEAS	2,S
	JMP	0,X


	PSCT
getchar	SUBA	#0
	BEQ	getchr0
	JSR	.LINK

getchr0	TST	RXCOUNT
	BNE	getchr1
	CLRD
	SEC
	BRA	getchr5
getchr1	LDA	RXHEAD
	LDX	#RXQUE
	LDB	A,X
	INCA
	STA	RXHEAD
	CMPA	#RXLEN
	BLT	getchr2
	CLR	RXHEAD

getchr2	DEC	RXCOUNT
	CLC
	LDA	ACIAst
	ORA	#$80
	STA	ACIAst
	STA	ACIA

getchr3	CLRA
	CMPB	#CR
	BNE	getchr4
	LDB	#LF
	BRA	getchr5
getchr4	CMPB	#CTRLD
	BNE	getchr5
	LDD	#EOF
getchr5	TSTB
	RTS


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
	ORG	$DFF2
VECTOR$	EQU	*

	FDB	0		Software Interrupt #3
	FDB	0		Software Interrupt #2
	FDB	0		Fast Interrupt Request
	FDB	IRQ$		Interrupt Request
	FDB	0		Software Interrupt
	FDB	RESTART$	Non-Maskable Interrupt
	FDB	RESTART$	Restart

	end
