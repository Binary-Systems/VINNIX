*****************************************************************************
*
    TTL    "Vincente's Immitation UNIX"
    NAM    VINNIX
*
*   Copyright (c) 1988-2020 Binary Systems, Inc.
*   All Rights Reserved
*
*
* VINNIX is a Real Time Executive (RTEX) for the 6809 that allows
* cooperative multitasking with "TASKS" writen in C.
*
* This executive is based on the 6800 Real Time Executive
* originally supplied with Motorola real time FORTRAN.
*
* Enhanced and adapted to Wintek C cross-compiler interface
* by Vincente D'Ingianni, II in 1988-1989
*
* This file is assembled by the Wintek 6809 cross-assembler into
* *relocatable* S-Records, then linked via the Wintek linker.
*
* Revision 1.0 by Caron Luk on June, 1989
* Added mpu option.
*
* Revision 1.1 By Caron Luk.
* 5/21/90 The system clock actually at 300.4807692Hz ((4MHz/416)/32)
*      By requiring .5 p more every second, we are requiring 1661
*      more p every day.  To cancel these p, 1 p sub every min, 9 p
*      every hour and 5 p every day, which sum up to 1661.  Now, the
*      different is .538528 p /day, which is 196.56272 p / yr or 2/3
*         of a sec slower.
*
* Revision 1.1 by caron on June,1990
* Modified int1 such that board with reverse logic can use vinnix.asm.
* mask byte that with all LSBs set mean that ctr reg is in reverse logic
* interrupt bit clr when there is an interrupt request.  But the bit must
* on the MSBs side, and RTEX will examine that ctr reg with the MSBs of
* the mask, and transfer with the whole byte of the ctr reg to the handler
* if interrupt request is indicated.
*
*****************************************************************************


* Set these flags for the proper MPU board.

_WINTEK	EQU	1
_MIKUL3	EQU	0
_RTEX	EQU	1

	GLOBAL	NMI$,IRQ$,SWI2$
	GLOBAL	setrt,start,startv,wait,waite,waitz,attch,wtwto,next
	GLOBAL	lock,unlock,set_time,set_date,get_time,get_date
	GLOBAL  sectmr,std_tmr,aux_tmr,rm_tmr,vox_tmr,ts_tmr
	GLOBAL  mintmr,tm_tmr

	EXTERN	STACK$,RESTART$
	EXTERN	main,.LINK

	OPT	NOLIST
	INCLUDE	"c:\include\map.ah"
	OPT	LIST

	INCLUDE	"c:\include\vinnix.ah"

	XDEF	TENTHS,SECOND,MINUTE,HOUR,DAY,YEAR
	XDEF	QCLEAR,NEXT$,MONTH,DAYTBL
	XDEF	WDTSAV,E1RAM,E2RAM

TRAP	MACR
	SWI2
	FCB	\0
	ENDM


* SCRATCH RAM
	DSCT
DATSIZ	EQU	200
DATPOL	RMB	DATSIZ
TASK	RMB	2
POLL	EQU	*
DELAY	RMB	2
BITMSK	EQU	*
UNIT	RMB	1
XPRI	RMB	1
RTCLK	RMB	2
PAA	RMB	2
PAS	RMB	2
WDTADD	RMB	2
WDTMSKs	RMB	1
WDTSAV	RMB	1
PRI$	RMB	1
CCX	RMB	2
QX1	RMB	2
SX1	RMB	2
SX2	RMB	2
PBADR	RMB	2	ADDRESS OF DATA POOL
FREE	RMB	2	EXTERNAL LINK TO FREE QUEUE
AQ$	RMB	2	LINK TO ACTIVE QUEUE
IQ$	RMB	2	LINK TO IRQ QUEUE
TQ$	RMB	4*3	TIMER CONTROL QUEUE

* CLOCK/CALENDAR REGS.
* ALL VALUES IN PACKED BCD
MONTH	RMB	1
DAY	RMB	1
YEAR	RMB	1
HOUR	RMB	1
MINUTE	RMB	1
SECOND	RMB	1
TENTHS	RMB	1
* System Timers in Seconds
* Calling routine should set the timer to a +ve number (1to127).  The
* timing routine below will dec the timer in each second if the timer
* is greater than Zero until it reach Zero.  Then, the Calling routine
* should take response and disable the timer afterward by setting it 
* to #$FF.
sectmr	EQU	*
std_tmr	RMB	1	used for keyboard time out.
aux_tmr RMB     1	timer for keypad time out.
rm_tmr  RMB	1	timer for vox comm.
vox_tmr	RMB	1	timer for remote panel comm.
ts_tmr	RMB	1	test sequence timer.
ENDSEC	EQU	*
mintmr	EQU	*
tm_tmr	RMB	1	used for Test Mode time out.
ENDMIN	EQU	*
CLK001	RMB	1	Wintek clk run at 300 Hz.  30*CLK001 = TENTHS
EOFRAM	EQU	*

STKCC	EQU	0
STKPC	EQU	10


* set up dispatch table for functions

	PSCT
SWITAB	EQU	*
	FDB	.SETRT
	FDB	.START
	FDB	.STARV
	FDB	.WAITZ
	FDB	.WAIT
	FDB	.WAITE
	FDB	.ATTCH
	FDB	.WTWTO


* Lock and Unlock provide a C interface for masking and unmasking interrupts.

lock	SEI
	RTS

unlock	CLI
	RTS

*
* char	*time;
*
* set_time("hh:mm:ss");
*

set_time SUBA	#2
	BEQ	settim0
	JSR	.LINK

settim0 SEI
	PULS	Y	Return address.

	PULS	X	Time string.

	LDD	0,X++
	SUBA	#'0
	SUBB	#'0
	JSR	PACK
	STB	HOUR

	INX
	LDD	0,X++
	SUBA	#'0
	SUBB	#'0
	JSR	PACK
	STB	MINUTE

	INX
	LDD	0,X++
	SUBA	#'0
	SUBB	#'0
	JSR	PACK
	STB	SECOND

	CLR	TENTHS
; This is not really needed, but it is here for expansion.
;	INX
;	LDD	0,X++
;	SUBA	#'0
;	SUBB	#'0
;	JSR	PACK
;	STB	TENTHS

	PSHS	Y	Restore return address.
	CLRD
	CLI
	RTS


*
* char	*date;
*
* set_date("mm/dd/yy");
*

set_date SUBA	#2
	BEQ	setdat0
	JSR	.LINK

setdat0 SEI
	PULS	Y	Return address.

	PULS	X	Date string.

	LDD	0,X++
	SUBA	#'0
	SUBB	#'0
	JSR	PACK
	STB	MONTH

	INX
	LDD	0,X++
	SUBA	#'0
	SUBB	#'0
	JSR	PACK
	STB	DAY

	INX
	LDD	0,X++
	SUBA	#'0
	SUBB	#'0
	JSR	PACK
	STB	YEAR

	PSHS	Y	Restore return address.
	CLRD
	CLI
	RTS


*
* char	*time;
*
* time=get_time(time);
*

get_time SUBA	#2
	BEQ	gettim0
	JSR	.LINK

gettim0 SEI
	PULS	Y	Return address.
	PULS	X	This is the beginning of the string.

	PSHS	X	Save X for later.

	LDB	HOUR	Get hours.
	JSR	UNPACK
	ADDA	#'0
	ADDB	#'0
	STD	0,X++
	
	LDA	#':	Field delimeter.
	STA	0,X+

	LDB	MINUTE	Get minute.
	JSR	UNPACK
	ADDA	#'0
	ADDB	#'0
	STD	0,X++

	LDA	#':	Field delimeter.
	STA	0,X+

	LDB	SECOND	Get second.
	JSR	UNPACK
	ADDA	#'0
	ADDB	#'0
	STD	0,X++

; Not needed but here for expansion.
;	LDA	#':	Field delimeter.
;	STA	0,X+
;
;	LDB	TENTHS	Get tenths.
;	JSR	UNPACK
;	ADDA	#'0
;	ADDB	#'0
;	STD	0,X++

	LDA	#0	Mark end of string.
	STA	0,X

	PULS	D	Get the beginning of the string.
	PSHS	Y	Replace the return address.
	CLI
	RTS

*
* char	*date;
*
* date=get_date(date);
*

get_date SUBA	#2
	BEQ	getdat0
	JSR	.LINK

getdat0 SEI
	PULS	Y	Return address.
	PULS	X	This is the beginning of the string.

	PSHS	X	Save X for later.

	LDB	MONTH	Get month.
	JSR	UNPACK
	ADDA	#'0
	ADDB	#'0
	STD	0,X++
	
	LDA	#'/	Field delimeter.
	STA	0,X+

	LDB	DAY	Get day.
	JSR	UNPACK
	ADDA	#'0
	ADDB	#'0
	STD	0,X++

	LDA	#'/	Field delimeter.
	STA	0,X+

	LDB	YEAR	Get year.
	JSR	UNPACK
	ADDA	#'0
	ADDB	#'0
	STD	0,X++

	LDA	#0	Mark end of string.
	STA	0,X

	PULS	D	Get the beginning of the string.
	PSHS	Y	Replace the return address.
	CLI
	RTS


* ---------------------------------------------------------- *
* PACK - MAKES 2 NIBBLES IN A:B INTO 1 BYTE IN B.
* ---------------------------------------------------------- *
PACK	LSLA
	LSLA
	LSLA
	LSLA
	ANDA	#$F0	A> XXXX0000
	ANDB	#$0F	B> 0000YYYY
	PSHS	A
	ORB	,S+	B> XXXXYYYY
	RTS
* ---------------------------------------------------------- *   
* UNPACK - makes byte in B into 2 nibbles in A:B    
* ---------------------------------------------------------- *    
UNPACK	TFR	B,A
	ANDB	#$F
	LSRA
	LSRA
	LSRA
	LSRA
	RTS


* function SETRT
* this function sets up the real-time system's
* scratch ram and programs the ptm to provide
* timing. arguments and stack offsets:
* 0 BASE ADDRESS OF PTM
* 2 BASE ADDRESS OF SCRATCH RAM
* 4 SIZE OF SCRATCH RAM AREA
* 6 WATCHDOG TIMER ADDRESS
* 8 WDT BIT MASK
* the ram area size must be at least 20 bytes
* and must be a multiple of 10.

setrt	SUBA	#6
	BEQ	setrt0
	JSR	.LINK

setrt0	PULS	X
	PULS	D
	STB	WDTMSKs
	PULS	D
	STD	WDTADD
	PULS	D
	STD	RTCLK
	PSHS	X
	LDD	#DATPOL
	STD	PAA
	LDD	#DATSIZ
	STD	PAS
	TRAP	SETRT
	RTS

.SETRT	SEI	NO		IRQ'S
	LDD	PAS		CHECK SIZE OF RAM
	CMPD	#20
	BHS	SETRT2		OK
	LDA	STKCC,S		ERROR - SET CARRY
	ORA	#1
	STA	STKCC,S
SETRT1	RTI	RETURN
SETRT2	BSR	QCLEAR		SET UP QUEUE ENTRIES
* disable all second & minute timers.
	LDA	#$FF
	LDX	#sectmr  
SETENR  STA	,X+      	; GET TIMER
	CPX	#ENDMIN
        BNE	SETENR
*
	LDX	#CLKINT		INIT. CLOCK REGS
	LDY	#MONTH
	LDB	#7
	BSR	MOVE

	IFNE	_MIKUL3
	LDX	RTCLK		GET PTM ADD.
	CLRA
	STA	1,X		ACCESS TIMER #3
	LDA	#$C3		/8 CLOCK,IRQ
	STA	,X
	LDA	#1
	STA	1,X		ACCESS CR1
	CLRA
	STA	,X		CLEAR INTERNAL RESET
	LDD	#$30D4		0.1 SECOND COUNTER LATCH
	STD	6,X		START CLOCK
	ENDC

	RTI			RETURN


QCLEAR	LDX	PAA		GET ADDRESS OF RAM AREA
	LDD	PAS		GET SIZE
	CLR	0,X		CLEAR LOWEST LINK WORD
	CLR	1,X
	SUBD	#20
	PSHS	D
QCLR2	STX	10,X		STORE LINK ADDRESS
	LDB	#8		CLEAR 8 BYTES
	LEAX	2,X
QCLR4	CLR	,X+
	DECB
	BNE	QCLR4
	LDD	0,S		DEC SIZE COUNTER
	SUBD	#10
	STD	0,S
	BPL	QCLR2		STILL MORE ROOM
	STX	FREE		SAVE LAST LINK ADD.
	LDAB	#8		CLEAR 8 MORE BYTES
	LEAX	2,X
QCLR6	CLR	,X+
	DECB
	BNE	QCLR6
	CLRA
	STD	IQ$		INIT QUEUE POINTERS
	STD	AQ$
	PULS	D		FIX STACK
	LDA	#192		SET INITIAL PRIORITY
	STA	PRI$
	LDX	#TQC		INIT TIMER CONTROL QUEUE
	LDY	#TQ$
	LDB	#12
MOVE	LDA	,X+
	STA	,Y+
	DECB
	BNE	MOVE
	RTS

TQC	FCB	0,0,1,1		0.1 SEC. QUEUE
	FCB	0,0,10,10	1 SEC. QUEUE
	FCB	0,0,60,60	1 MIN. QUEUE

CLKINT	FCB	1,1,0,0,0,0,0


* function START
* this function enters a task into the
* active queue. offsets and arguments:
* 0 TASK PROGRAM START ADDRESS
* 2 DELAY TIME FOR STARTING TASK
* 4 TIME UNIT ASS. WITH DELAY TIME

start	SUBA	#6
	BEQ	start0
	JSR	.LINK

start0	PULS	X
	PULS	D
	STB	UNIT
	PULS	D
	STD	DELAY
	PULS	D
	STD	TASK
	PSHS	X
	TRAP	START
	RTS

.START	BSR	DQFP1	GET QUEUE BUFFER
	BCS	START1	ERROR
STARTX	LDD	TASK	GET TASK ADDRESS
	JSR	STQ	QUEUE IT UP
	BCC	START2	NO ERRORS
START1	LDA	STKCC,S	SET CARRY
	ORA	#1
	STA	STKCC,S
START2	RTI		RETURN


* dequeue buffer from free pool

DQFP1	SEI
	BSR	DQFP	GET BUFFER
	BCS	DQFP9	ERROR
	CLI
	STX	PBADR	SAVE BUFFER ADD.
	LDA	PRI$	GET PRIORITY
	STA	2,X	SAVE
	CLC
DQFP9	RTS

DQFP	LDX	FREE
	BNE	DQFP2
	SEC	NO	FREE SPACE LEFT
	RTS

DQFP2	CLR	3,X	SET ENTRY MODE
	CLR	8,X	CLEAR LOCK CELL
	CLR	9,X
	LDD	0,X	DEQ FROM FREE POOL
	STD	FREE
	RTS

* queue up task to timer or active queue
* enter with task add. in D
STQ	LDX	PBADR	GET BUFFER ADD.
	STD	4,X	STORE TASK ADD.
	LDD	DELAY	GET DELAY TIME
	STD	6,X	STORE IT
	BEQ	STQ3	PUT IN ACTIVE Q IF 0
	LDB	UNIT	GET TIME UNIT
	BEQ	STQ0
	DECB
STQ0	CMPB	#3	CHECK RANGE
	BCS	STQ1	RANGE OK
	SEC	ERROR
	RTS

STQ1	ASLB		GENERATE OFFSET
	ASLB
	LDX	#TQ$	GET TIMER Q ADD.
	ABX
	SEI
	LDD	,X	ENQUEUE TO TIMER QUEUE
	STD	[PBADR]
	LDD	PBADR
	STD	,X
	ANDCC	#$EE	CLEAR IRQ MASK AND CARRY
	RTS

STQ3	BSR	EAQ1	ENQUEUE TO ACTIVE QUEUE
	ANDCC	#$EE
	RTS

EAQ1	SEI
EAQ	LDD	AQ$
	STD	,X
	STX	AQ$
	RTS


* STARV FUNCTION
* SAME AS START EXCEPT HAS ADDITIONAL
* ARGUMENT FOR PRIORITY

startv	SUBA	#8
	BEQ	startv0
	JSR	.LINK

startv0	PULS	X
	PULS	D
	STB	XPRI
	PULS	D
	STB	UNIT
	PULS	D
	STD	DELAY
	PULS	D
	STD	TASK
	PSHS	X
	TRAP	STARTV
	RTS

.STARV	JSR	DQFP1	GET BUFFER
	LBCS	START1	ERROR
	LDX	PBADR	GET BUFFER ADD.
	LDB	XPRI	GET PRIORITY
	STB	,X	STORE IT
	LBRA	STARTX	CONTINUE


* WAIT FUNCTION
* ARGUMENTS:
* 0 TIME TO WAIT
* 2 UNIT OF TIME


wait	SUBA	#4
	BEQ	wait0
	JSR	.LINK

wait0	PULS	X
	PULS	D
	STB	UNIT
	PULS	D
	STD	DELAY
	PSHS	X
	TRAP 	WAIT
	RTS

.WAIT	EQU	*
WAIT2	JSR	DQFP1	GET FREE BUFFER
WAIT1	LBCS	START1	ERROR
WAIT3	INC	3,X	USE OLD STACK
	TFR	S,D
	JSR	STQ	QUEUE UP TASK
	BCS	WAIT1	ERROR
	JMP	NEXT$	SEARCH ACTIVE Q


* WAITE FUNCTION
* WAITS FOR FLAG VALUE TO GO TO 0
* ONLY ARGUMENT IS ADDRESS OF FLAG

waite	SUBA	#2
	BEQ	waite0
	JSR	.LINK

waite0	PULS	X
	PULS	D	flag address
	STD	POLL
	PSHS	X	
	TRAP	WAITE
	RTS

.WAITE	LDY	POLL	GET ARG
	LDA	,Y	GET FLAG VALUE
	BNE	SPND$
	RTI		DON'T WAIT IF ALREADY 0
SPND$	JSR	DQFP1	GET BUFFER
	BCS	WAIT1	ERROR
	INC	3,X	FLAG OLD STACK
	STY	8,X	SET LOCK ADD.
	STS	4,X	SAVE STACK
	JSR	EAQ1	ENQ TO AQ$
	CLI
	JMP	NEXT$	SEARCH ACTIVE Q



* WTWTO function
* this function puts a task on hold
* until a flag goes to zero or until a
* timer times out, whichever comes first.
* carry is set on return if a timeout
* occurred. ARGUMENTS:
* 0 ADDRESS OF FLAG VALUE
* 2 DELAY TIME
* 4 TIME UNIT
* the value of the flag is checked
* every time unit.

wtwto	SUBA	#6
	BEQ	wtwto0
	JSR	.LINK

wtwto0	PULS	X
	PULS	D
	STB	UNIT
	PULS	D
	STD	DELAY
	PULS	D
	STD	TASK
	PSHS	X
	TRAP	WTWTO
	RTS


.WTWTO	JSR	DQFP1	GET BUFFER
	LBCS	START1	ERROR
	LDD	TASK	GET LOCK ADD.
	STD	8,X	STORE IT
	BRA	WAIT3	CONTINUE


* WAITZ function
* puts A task on hold with no minimum
* time delay before resuming task.
* if no other tasks are active, old
* task will resume immediately.

waitz	TSTA
	BEQ	waitz0
	JSR	.LINK

waitz0	TRAP	WAITZ
	RTS


.WAITZ	CLRA
	CLRB
	STD	DELAY
	STA	UNIT
	LBRA	WAIT2



* next() transfers the processor to the next task in the queue.  This
* function should be used when a task ends (is finished executing).

next	TSTA			Make sure no arguments were passed in.
	BEQ	next0
	JSR	.LINK

next0	JMP	NEXT$



* ATTCH (ATTACH) function
* provides connection between a device
* which generates an irq and the
* interrupt handler task associated with
* it. arguments:
* 0 IRQ HANDLER ADDRESS
* 2 ADDRESS TO READ FROM DURING POLL
* 4 BIT TO TEST DURING POLL
* the handler must clear the IRQ.


attch	SUBA	#6
	BEQ	attch0
	JSR	.LINK

attch0	PULS	X
	PULS	D
	STB	BITMSK
	PULS	D
	STD	POLL
	PULS	D
	STD	TASK
	PSHS	X
	TRAP	ATTCH
	RTS

.ATTCH	LDX	FREE	GET BUFFER
	BNE	ATTCH1	BRANCH IF OK
	LDA	STKCC,S	NO SPACE LEFT
	ORA	#1
	STA	STKCC,S
	RTI		RETURN

ATTCH1	SEI
	LDD	POLL	SET UP QUEUE ENTRY
	STD	2,X
	LDB	BITMSK
	STB	4,X
	LDD	TASK
	STD	5,X
	LDD	,X	DEQ FROM FREE POOL
	STD	FREE
	LDD	IQ$
	STD	,X
	STX	IQ$
	CLI
	RTI



* this is the real-time dispatcher loop
* it searches AQ$ for the highest priority
* task and runs it.
	
NEXT$	LDX	#AQ$	POINT TO QUEUE
	LDA	#$FF	LOAD LOWEST PRIORITY
	BRA	SS3	1ST TIME
SS2	CMPA	2,X	COMPARE PRIORITIES
	BLO	SS3	OLD IS TOP
	LDAB	2,X	NEW TOP
	LDX	8,X	WAIT CELL ADDRESS
	BEQ	SS2A	NO WAIT CELL
	TST	0,X	WAIT ACTIVE?
	BEQ	SS2A	NO
	LDX	SX2	YES, RESET X
	BRA	SS2B	CONTINUE
SS2A	TFR	B,A	SAVE NEW PRIORITY
	LDX	SX2
	STX	SX1	SAVE ENTRY ADDRESS
SS2B	LDX	,X
SS3	STX	SX2	SAVE ADD. OF PREVIOUS ENTRY
	LDX	,X	ADD. OF NEXT ITEM
	BNE	SS2	NOT END
	INCA		ANYTHING FOUND?
	BEQ	NEXT$	NO
	LDX	SX1	DEQ FROM AQ$
	SEI
	LDY	,X
	LDD	,Y
	STD	,X
	LDD	FREE	ENQ TO FREE POOL
	STD	,Y
	STY	FREE
	LDA	2,Y	SAVE PRIORITY
	STA	PRI$
	TST	3,Y	CHECK STACK FLAG
	BEQ	SS4	NO OLD STACK
	LDS	4,Y	RELOAD STACK
	RTI		RESUME TASK

SS4	LDX	4,Y	TASK ADD.
	LDS	8,X	LOAD STACKS
	CLI		CLEAR IRQ
	JMP	$0A,X	START TASK



* IRQ handler
* updates clock/calendar,searches timer queues
* and irq queue

IRQ$	EQU	*
	IFNE	_MIKUL3
	LDX	RTCLK	GET PTM ADD
	LDA	1,X	STATUS REG.
	LBPL	INT1	NOT CLOCK
	ANDA	#4	TIMER 3?
	LBEQ	INT1	NO
	LDA	6,X	CLEAR IRQ
	LDX	WDTADD	CHECK FOR WDT
	BEQ	TQ1	NONE
	LDA	,X
	EORA	WDTMSKs
	STA	WDTSAV	SAVE TOGGLE BIT
	ENDC

	IFNE	_WINTEK
	LDX	RTCLK
	LDA	,X
	LBPL	INT1
	LDA	-2,X	clr irq
	DEC	CLK001
	BGT	TQ10
	LDA	#30
	STA	CLK001
	ENDC

*
* SEARCH TIMER QUEUES        1/10 sec has passed
*

TQ1	LDX	#TQ$	0.1 SEC. QUEUE
TQ2	DEC	3,X	DEC COUNTER
	BNE	TQ9	STILL RUNNING
	LDA	2,X	RESET COUNTER
	STA	3,X
	STX	CCX	SAVE CONTROL ADD.
TQ3	STX	QX1	SAVE CURRENT ENTRY ADD.
TQ4	LDX	,X	GET NEXT
	BEQ	TQ7	NONE
	LDY	8,X	LOCK ADD.
	BEQ	TQ6	NONE
	LDA	,Y	CHECK FLAG
	BNE	TQ6	STILL WAITING
TQ5	CLR	6,X	RESET TIMER
	CLR	7,X
	BSR	TOSET	SETUP TIMEOUT BIT
	LDD	,X	LINK ADD.
	PSHS	D
	JSR	EAQ	ENQUEU TO AQ$
	LDX	QX1	DEQUEUE FROM TQ$
	PULS	D
	STD	,X
	BRA	TQ4	GET NEXT ENTRY
TQ6	LDD	6,X	GET TIMER
	SUBD	#1	DEC
	STD	6,X
	BPL	TQ3	NO HIT
	BRA	TQ5	RESET TIMER AND QUEUE UP
TQ7	LDX	CCX	QUEUE ADD.
	LEAX	4,X	GO TO NEXT CONTROL
	CPX	#3*4+TQ$	END?
	BNE	TQ2	CONTINUE IF NOT
TQ9	BSR	CLKCAL	UPDATE CLOCK/CALENDAR
TQ10	RTI		RETURN



* subroutine to set carry if a timeout
* occurred while waiting for an event
* if acca=0, carry is cleared, if acca
* not 0, carry is set.

TOSET	LDB	3,X	CHECK OLD/NEW STACK
	LSRB
	BCS	TOSET1	USE OLD STACK
	RTS		RETURN

TOSET1	LDY	4,X	STACK ADD.
	LDB	STKCC,Y	GET CC
	TSTA	SET	OR CLEAR CARRY?
	BNE	TOSET2
	ANDB	#$FE	CLEAR CARRY - NO TIMEOUT
	BRA	TOSET3
TOSET2	ORB	#1	SET CARRY
	CLR	8,X	CLEAR LOCK ADD.
	CLR	9,X
TOSET3	STB	STKCC,Y
	RTS


* update the clock calendar registers

CLKCAL	LDA	TENTHS	UPDATE 0.1 SEC REG
	ADDA	#1
	CMPA	#9	OVERRUN?
	BGT	SEC
	STA	TENTHS
	RTS
SEC	CLR	TENTHS
*
DECSEC LDX    #sectmr  ;POINT TO SEC TIMER
GETENR LDA    ,X+      ;GET TIMER
       BLE    NXTENR   SKIP IF TIME OUT OR OFF
       DECA
       STA    -1,X
NXTENR CPX    #ENDSEC
       BNE    GETENR
*
	LDA	SECOND
	ADDA	#1
	DAA
	IFNE	_WINTEK		@ require 1 pulse more every 2 seconds
	BITA	#1
	BNE	T_ADJ1
	INC	CLK001		inc clk001 from 30 to 31.
	ENDC
T_ADJ1	CMPA	#$59
	BHI	MINT
	STA	SECOND
	RTS
MINT	CLR	SECOND
*
DECMIN LDX    #mintmr  ;POINT TO MIN TIMER
GETmr  LDA    ,X+      ;GET TIMER
       BLE    NXTmr    ;SKIP IF TIME OUT OR OFF
       DECA
       STA    -1,X
NXTmr  CPX    #ENDMIN
       BNE    GETmr
*
	IFNE	_WINTEK		@ dec 1 pulse every min
	DEC	CLK001
	ENDC
	LDA	MINUTE
	ADDA	#1
	DAA
	CMPA	#$59
	BHI	HOURST
	STA	MINUTE
	RTS
HOURST	CLR	MINUTE
	IFNE	_WINTEK		@ require 9 pulse less every hour
	LDA	CLK001
	SUBA	#9
	STA	CLK001		dec clk001 by 9
	ENDC
	LDA	HOUR
	ADDA	#1
	DAA
	CMPA	#$23
	BHI	DAYST
	STA	HOUR
	RTS

DAYST	CLR	HOUR
	IFNE	_WINTEK		@ dec clk001 by 5 every day
	LDA	CLK001	
	SUBA	#5
	STA	CLK001
	ENDC	
	LDA	DAY
	ADDA	#1
	DAA
	PSHS	A
	LDA	MONTH
	TFR	A,B
	CMPA	#9	GO BCD TO BINARY IF NEC.
	BLS	BINARY
	ANDA	#$F
	ADDA	#10
BINARY	DECA	OFFSET
	LDX	#DAYTBL	GET DAYS IN MONTH
	LDA	A,X
	CMPB	#2	CHECK MONTH
	BNE	NOTFEB	FEB. IS SPECIAL
	PSHS	A	SAVE DAYS
	LDA	YEAR	GET YEAR
	TFR	A,B
	ANDB	#$F	STRIP HI SIDE & SAVE LOW
	PSHS	B
	LSRA	MUL	HI SIDE BY 10
	LSRA
	LSRA
	LSRA
	LDB	#10
	MUL
	ADDB	,S+	ADD TO LOW SIDE
	PULS	A	RETRIEVE DAYS
	ANDB	#3	CHECK FOR LEAP YEAR
	BNE	NOTFEB	NOT LEAP
	INCA	ADD	29TH DAY
NOTFEB	LDB	,S
	CMPA	0,S+	COMPARE MAX DAYS TO CURRENT DAYS
	BLO	MONSET	BRANCH IF DAYS TOO HIGH
	STB	DAY	UPDATE DAYS
	RTS

MONSET	LDA	#1	RESET DAYS
	STA	DAY
	LDA	MONTH
	ADDA	#1
	DAA
	CMPA	#$12
	BHI	YRSET
	STA	MONTH
	RTS

YRSET	LDA	#1
	STA	MONTH
	LDA	YEAR
	ADDA	#1
	DAA
	STA	YEAR
	RTS

DAYTBL	FCB	$31,$28,$31,$30,$31,$30
	FCB	$31,$31,$30,$31,$30,$31


* search interrupt queue for cause of irq
* call irq handler for each interrupting
* device

INT1	LDX	#IQ$
INT2	LDX	,X	NEXT ITEM
	BEQ	INT9	END OF QUEUE
	LDA	[2,X]	READ POLL REG.
	ldb	4,X	check mask		<<<  Revision 1.1.
	andb	#$F	if LSBs all set, its a reverse logic int bit type.
	beq	int_c	if LSBs all clr, its normal, goto int_c.
	coma		reserve reading from ctr reg.
	anda	#$F0	make sure the mask mark (LSBs) won't affect result.
	bita	4,x	bit mask
	beq	INT2	no hit
	lda	[2,x]	reload ctr reg
	coma		reverse value for negative logic
	bra	negA
*
int_c	BITA	4,X	BIT MASK
	BEQ	INT2	NO HIT-GET NEXT
negA	PSHS	X	SAVE QUEUE INDEX
	JSR	[5,X]	CALL HANDLER
	PULS	X	RETRIEVE INDEX
	BRA	INT2	CHECK MORE
INT9	RTI	RETURN


* SWI2 handler
* this routine transfers control to the
* special functions through a dispatch
* table. each function call is of the form
*      swi2
*      fcb    code
* where code is used to generate the
* correct offset to the function table.
* the stacked carry bit is cleared
* before a function is called.

SWI2$	LDX	STKPC,S	get return add.
	LDB	,X+	get code
	STX	STKPC,S	adjust return add.
	LDA	STKCC,S	get stacked condition codes
	ANDA	#$FE	clear carry
	STA	STKCC,S
	LDX	#SWITAB	point to table
	ASLB		double code for offset
	JMP	[B,X]	go to routine

	END

*
