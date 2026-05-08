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

;ErrorAsm — полная реализация в win1. В overlay вынесена только
;таблица сообщений и lookup+print строки (см. OverlayPrintErrMsg).
;Всё, что трогает source-память через win2/win3 (location, log,
;source-line print, underline) выполняется здесь, где win-mapping
;соответствует обычному состоянию parser'а.
ErrorAsm
		push hl
		push af
		push bc
		ld c,Cursor
		rst #10		;координаты курсора
		ld e,30
		ld c,Locate
		rst #10		;новые координаты курсора
		;Печать строки-сообщения через overlay (B = код ошибки).
		;OverlayPrintErrMsg сохраняет HL/DE/BC, печатает строку
		;и записывает её адрес в ErrMsgPtr для последующего
		;использования в WriteErrLog.
		ld hl,OverlayPrintErrMsg
		call CallOverlay
		ld hl,ErrCRLF
		ld c,PChars
		rst #10		;перевод строки
		call PrintErrLocation
		call WriteErrLog

		ld c,Cursor
		rst #10		;координаты курсора
		ld hl,(BegString)

ErAsm4		ld b,00001110b
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

ErAsm3		ld hl,ErrCRLF
		ld c,PChars
		rst #10		;перевод строки
		ld e,00000111b
		ld b,78
		ld c,LP_Print_Atr
		rst #8
		ld hl,CRLF+1
		ld c,PChars
		rst #10		;CR (без LF) — в начало строки
		ld hl,(ErrorPass)
		inc hl
		ld (ErrorPass),hl
		pop bc
		bit 7,b
		jp nz,ExitDSS	;выход при фатальной ошибке
		pop af
		pop hl
		ret
