;
;Обработка ошибок компилятора
;
SyntaxEr	equ #01
InvalidLab	equ #02
LabelAlrEr	equ #03
NoLabel		equ #04
JumpEr		equ #05
PhaseEr		equ #06
DephaseEr	equ #07
InadmisORG	equ #08
IncludeEr	equ #09
DBInstrEr	equ #0a
InvalidExp	equ #0b
MissingEr1	equ #0c
MissingEr2	equ #0d
DivZeroEr	equ #0e
LabelTabEr	equ #8f
StackOpEr	equ #90
GeneralFail	equ #91
UserError	equ #12
AssertionEr	equ #13

ErrorAsm
;		 exa
;		 exx
;		 push hl
;		 push de
;		 push bc
;		 push af
;		 exa
;		 exx
		push hl
;		 push de
;		 push bc
		push af

;		 ld de,(BegString)
;		 or a
;		 sbc hl,de	 ;номер ошибочной позиции
;		 dec hl
;		 push hl

		push bc
		ld a,b
		res 7,a		;сбрасываем бит фатальной ошибки
		cp #14
		jr c,ErAsm1
		ld a,#11
ErAsm1		dec a
		add a,a
		ld c,a
		ld b,0
		ld hl,ErrAsmTbl
		add hl,bc
		ld a,(hl)
		inc hl
		ld h,(hl)
		ld l,a
		ld (ErrMsgPtr),hl
		push hl

		ld c,Cursor
		rst #10		;координаты курсора
		ld e,30
		ld c,Locate
		rst #10		;новые координаты курсора
		pop hl
		ld c,PChars
		rst #10		;сообщение об ошибке
		ld hl,CRLF
		ld c,PChars
		rst #10		;перевод строки
		call PrintErrLocation
		call WriteErrLog

		ld c,Cursor
		rst #10		;координаты курсора
		ld hl,(BegString)
;		 pop bc		 ;номер ошибочной позиции
;		 ld a,e
		
ErAsm4		;CALL Debug
;		 cp c		 ;сравниваем печатаемую позицию с ошибочной
		ld b,00001110b
;		 jr nz,ErAsm2
;		 ld b,%11001110
ErAsm2		ld a,(hl)
		inc hl
		cp #09
		jr nz,ErAsm6
		ld a,e
		cp 72
		jr nc,ErAsm7
		cpl
		and 00000111b	;кол-во позиций до следующей позиции табул.
		inc a
		push af
		add a,c
		ld c,a
		pop af
		add a,e
		ld e,a
;		 push bc
;		 push de
;		 push hl
;		 ld hl,nTab
;		 ld c,PChars
;		 call DSS
;		 pop hl
;		 pop de
;		 pop bc
		jr ErAsm4

ErAsm6		cp #20
		jr c,ErAsm3

		push bc
		push de
		push hl
		ld c,WrChar
		rst #10		;печать символа строки с цветом
		pop hl
		pop de
		pop bc
		inc e
		ld a,e
		cp 76
		jr c,ErAsm4
ErAsm7		ld b,3
		ld c,PutChar
ErAsm5		ld a,"."
		push bc
		rst #10		;печать символа
		pop bc
		djnz ErAsm5


ErAsm3		ld hl,CRLF
		ld c,PChars
		rst #10		;перевод строки
		ld e,00000111b
		ld b,78
		ld c,LP_Print_Atr
		rst #8 ; изменено в v0.2X
		ld hl,CRLF+1
		ld c,PChars
		rst #10		;в начало строки
		ld hl,(ErrorPass)
		inc hl
		ld (ErrorPass),hl
		pop bc
		bit 7,b
		jp nz,ExitDSS	;выход при фатальной ошибке
;		 pop af
;		 pop bc
;		 pop de
;		 pop hl
;		 exa
;		 exx
		pop af
;		 pop bc
;		 pop de
		pop hl
;		 exa
;		 exx
		ret

;nTab		 db 9,0

ErrAsmTbl	dw er01
		dw er02
		dw er03
		dw er04
		dw er05
		dw er06
		dw er07
		dw er08
		dw er09
		dw er0A
		dw er0B
		dw er0C
		dw er0D
		dw er0E
		dw er8F
		dw er90
		dw er91
		dw er12
		dw er13
;		 dw er14
;		 dw er15

er01		db "Syntax error",0
er02		db "Invalid label",0
er03		db "Label already defined",0
er04		db "No such label",0
er05		db "Relative jump out of range",0
er06		db "PHASE directive before DEPHASE",0
er07		db "Missing DEPHASE",0
er08		db "Inadmissible ORG in block PHASE/DEPHASE",0
er09		db "Too many INCLUDE file",0
er0A		db "Too many data in DB, DW or DS instructions",0
er0B		db "Invalid expression",0
er0C		db "Missing (",0
er0D		db "Missing )",0
er0E		db "Division by zero",0
er8F		db "Overflowing of labels table",0
er90		db "Overflowing of operations stack",0
er91		db "General failure",0
er12		db "User error",0
er13		db "Assertion failed",0
