;-----------------------------------------------------------------------------
;--		      Процедуры обработки мнемоник и команд ассемблирования --
;-----------------------------------------------------------------------------
;-- Сканирование мнемоники (команд ассемблирования) и операндов --
;конец команды определяется:
;  по ":", ";" или символам конца строки
;Вход:		HL - адрес второго символа мнемоники (команды)
;		A  - первый символ мнемоники (команды)
;Выход: HL - адрес начала следующей строки / команды
;
ScanCmnd	ld b,10		;max длина мнемоники + 1
		ld de,CmndBuf	;рабочий буфер
SC6		dec b
		jr z,SC10
		call Letter	;символ - буква?
		jr c,SC2

SC10		ld b,SyntaxEr	;"Синтаксическая ошибка"
		jp SkipStrC	;выход в головную программу

SC2		and #df		;перевод символа в CapsLock
		ld (de),a	;символ в буфер
		ld a,(hl)	;следующий символ
		inc hl
		inc de
		cp #09		;табуляция
		jr z,SC5	;поиск операндов
		cp #20		;пробел
		jr z,SC5	;поиск операндов
		cp ";"		;конец команды
		jr z,SC5
		cp ":"		;конец команды
		jr z,SC5
		cp #0d		;конец строки
		jr nz,SC6

SC5		ld b,a
		xor a
		ld (de),a	;0 в конец мнемоники
		exx
SC7		call CmndDetect ;определение кода мнемоники
		push de
		exx
		pop de		;адрес служебного байта
		ld a,b		;послений символ в A для правильной обр.ошибок
		jp m,SC10
		ld a,(de)	;служебный байт
;		 ld (MnemByte),a
		inc de
		push de		;obj код команд без операндов,
				;или адрес п/п обработки мнемоники с операнд.
		bit 7,a
		jp nz,SC12	;команда должна иметь операнды
SC16		exx		;новое значение программного счетчика
		ld b,a		;длина команды в байтах
SC4		pop de
		call ObjCopy

;		 ld a,b
;		 or a
;		 jr z,SC13
;		 ld hl,(PCAddres)
;		 ld a,(Pass)	 ;номер прохода
;		 or a
;		 jr z,SC1

;		 push hl	 ;сохранили значение PCAddres
;		 push bc	 ;и длину кода (в рег.B)

;		 in a,(#c2)	 ;номер страницы вкл. во 2-е окно
;		 push af
;		 in a,(#e2)	 ;номер страницы вкл. в 3-е окно
;		 push af
;		 push de
;		 ld e,b
;		 ld d,0
;		 push de
;		 ld hl,(MemID)
;		 inc hl
;		 inc hl		 ;к id блока obj кода
;		 ld a,(hl)
;		 inc hl
;		 ld b,(hl)	 ;кол-во выделенных страниц
;		 dec b		 ;номер последней логической страницы
;		 ld c,a
;		 push hl
;		 push bc
;		 push de
;		 ld c,EMM_Fn4
;		 call BIOS	 ;вычисление физического номера страницы
;		 out (#c2),a	 ;вкл. ее во 2-е окно
;		 pop de		 ;длина obj кода
;		 ld hl,(SaveObjAdr)
;		 add hl,de
;;		  ld (SaveObjAdr),hl
;		 ld a,h
;		 pop bc
;		 pop hl
;		 cp #c0		 ;проверка, хватит ли страницы на запись кода
;		 jr c,SC20

;;		  sub #40	  ;корр. старший адрес записи кода в память
;;		  ld (SaveObjAdr+1),a
;		 inc b		 ;увеличить размер блока под obj код
;		 push bc
;		 inc b
;		 ld (hl),b	 ;сохраняем новый размер блока
;		 ld a,c
;		 ld c,SetMem
;		 call DSS	 ;изменить размер блока
;		 pop bc		 ;b - лог.ном. новой страницы, c - id блока
;		 ld a,c
;		 ld c,EMM_Fn4
;		 call BIOS	 ;вычисление физического номера страницы
;		 out (#e2),a	 ;вкл. ее в 3-е окно

;SC20		 pop bc		 ;длина obj кода
;		 pop hl		 ;откуда переносить
;		 ld de,(SaveObjAdr)
;		 ldir		 ;генерация кода на втором проходе
;		 ld (SaveObjAdr),de
;		 ld a,d
;		 cp #c0
;		 jr c,SC21
;		 sub #40	 ;корр. старший адрес записи кода в память
;		 ld (SaveObjAdr+1),a
		
;SC21		 pop af
;		 out (#e2),a	 ;востановили банку в 3-eм окне
;		 pop af
;		 out (#c2),a	 ;востановили банку во 2-ом окне

;		 pop bc
;		 pop hl

;SC1		 ld e,b		 ;расчет нового значения PC
;		 ld d,0
;		 add hl,de	 ;новое значение PC

;SC3		 ld (PCAddres),hl
SC13		exx
		ld a,b		;следующий за командой символ
		cp #20
		call z,SkipSpace
		cp #09
		call z,SkipSpace
		cp ":"
		ret z
;		 jp z,NextMnem
		cp #0d
;		 ret z
		jp z,SkipStr
		cp ";"
;		 ret z
		jp z,SkipStr
		ld b,SyntaxEr	;"Синтаксическая ошибка"
		jp SkipStrC	;выход в головную программу

SC12		bit 0,a
		jr nz,SC14	 

		ld a,b		 ;мнемоника, ищем операнды
		call OperDetect
;		 ret c		 ;ошибка в операндах
;
;Производим переход на обработку соответствующей мнемоники с операндами
;
		ld b,a		;следующий символ в строке
		exx
		pop hl		;(адрес) п/п обработки мнемоники с операнд.
		ld de,DataBuf
		push  de	;адрес размещения строки с кодом
		ld bc,SC4
		push bc		;адрес возврата из процедур
		ld c,(hl)
		inc hl
		ld b,(hl)
		push bc		;адрес п/п анализа команды с операндами
		ld hl,(Operand1);L - Operand1, H - Operand2
		ld bc,#0100
		ret		;переход на анализ команды с операндами

SC14		exx
		pop hl		;(адрес) п/п обработки оператора
		ld de,DataBuf
		push  de	;адрес размещения строки с кодом
		ld bc,SC15
		push bc		;адрес возврата из процедур
		ld c,(hl)
		inc hl
		ld b,(hl)
		push bc		;адрес п/п анализа оператора
		exx 
		ld a,b
		ld b,#00
		ld de,DataBuf	;начало буфера
;		 ld hl,(Operand1);L - Operand1, H - Operand2
;		 ld bc,#0100
		ret		;переход на анализ команды с операндами
SC15		ld c,a
		ld a,b
		ld b,c
		jp SC16
;
;-- Запись буфера с кодом в память --
;Вход: B - длина кода
;DE - начало буфера
ObjCopy
		ld a,b
		or a
		ret z
;		 jr z,SC13
		ld hl,(PCAddres)
		ld a,(Pass)	;номер прохода
		or a
		jr z,OC2

ObjCopy2	push hl		;сохранили значение PCAddres
		push bc		;и длину кода (в рег.B)

		in a,(Page2)	;физ.номер банки вкл. во 2-е окно
		push af
		in a,(Page3)	;физ.номер банки вкл. в 3-е окно
		push af

		push de		;начало буфера

		ld e,b
		ld d,0
		push de		;длина кода
		push de
		ld bc,(OutFileID)
		push bc
		dec b		;номер последней логической страницы
		ld a,c		;ID блока памяти
		ld c,SetWin2
		rst #10		;включить во 2-е окно
		jp c,Error	;выход, если произошла ошибка
		pop bc
		pop de		;длина obj кода
		ld hl,(SaveObjAdr)
		add hl,de

		bit 6,h		;проверка, хватит ли страницы на запись кода
		jr z,OC1

		push bc
		inc b
		ld (OutFileID),bc;сохраняем новый размер блока
		ld a,c
		ld c,SetMem
		rst #10		;изменить размер блока
		jp c,Error
		pop bc		;b - лог.ном. новой страницы, c - id блока
		ld a,c
		ld c,SetWin3
		rst #10		;включить в 3-е окно
		jp c,Error	;выход, если произошла ошибка

OC1		pop bc		;длина obj кода
		pop hl		;откуда переносить
		ld de,(SaveObjAdr)
		ldir		;генерация кода на втором проходе

		res 6,d
		ld (SaveObjAdr),de

		pop af
		out (Page3),a	;востановили банку в 3-eм окне
		pop af
		out (Page2),a	;востановили банку во 2-ом окне

		pop bc
		pop hl

OC2		ld e,b		;расчет нового значения PC
		ld d,0
		add hl,de	;новое значение PC

		ld (PCAddres),hl
		ret
;
;-- Поиск команды в таблице --
;Имя команды должно быть в буфере CmndBuf
;Таблица команд	 начинается с адреса TabCmnd
;результат:
; "M" - не найдена
; "P" - найдена,    HL - адрес команды в таблице
;		    DE - адрес служебного байта команды
;
CmndDetect	ld hl,TabCmnd	;адрес начала таблицы команд
CD1		ld a,(hl)
		dec a		;конец таблицы?
		ret m
		push hl
		ld b,a
		inc b		;длина записи в таблице команд
		sub 3		;длина команды
		ld c,a
		inc hl
		ld de,CmndBuf
CD2		push bc
		ld a,(de)
		ld b,(hl)	;символ команды
		cp b
		pop bc
		jr z,CD3
		pop hl
		ret m
CD4		ld c,b
		ld b,0		;в BC длина записи в таблице
		add hl,bc	;к следующей команде
		jr CD1
CD3		inc de
		inc hl
		dec c
		jr nz,CD2	;все символы команды из таблицы?
		ld a,(de)	;следующий символ из буфера команды
		ex de,hl
		pop hl
		or a		;конец команды в буфере?
		jr nz,CD4	;продолжаем поиск
		ret		;команда найдена
;
;-- Основная таблица команд --
;
;Формат таблицы:
;---------------
;длина записи -	 1 байт
;мнемоника или команда - 2-?? байта
;длина команды в байтах	 (1 или 2) - 1 байт (для мнемоник без операндов)
;    #80 - для команд с	 операндами
;    для команд	 компиляции этот байт равен 0???
;адрес обработки однотипных команд - 2 байта (для группы мнемоник)
;    код мнемоники (мл., ст.) -	 2 байта (для одиночных мнемоник)
;конец таблицы - байт #00
TabCmnd		db 7,"ADC",#80
		dw _adc
		db 7,"ADD",#80
		dw _add
		db 7,"AND",#80
		dw _and
		db 10,"ASSERT",#81
		dw _assert
		db 7,"BIT",#80
		dw _bit
		db 9,"BLOCK",#81
		dw _ds
		db 8,"BYTE",#81
		dw _db
		db 8,"CALL",#80
		dw _call
		db 7,"CCF",1
		db #3f,#00
		db 6,"CP",#80
		dw _cp
		db 7,"CPD",2
		db #ed,#a9
		db 8,"CPDR",2
		db #ed,#b9
		db 7,"CPI",2
		db #ed,#a1
		db 8,"CPIR",2
		db #ed,#b1
		db 7,"CPL",1
		db #2f,#00
		db 7,"DAA",1
		db #27,#00
		db 6,"DB",#81
		dw _db
		db 6,"DD",#81
		dw _dd
		db 7,"DEC",#80
		dw _dec
		db 8,"DEFB",#81
		dw _db
		db 8,"DEFD",#81
		dw _dd
		db 10,"DEFINE",#81
		dw _define
		db 8,"DEFS",#81
		dw _ds
		db 8,"DEFW",#81
		dw _dw
		db 11,"DEPHASE",#81
		dw _dephase
		db 6,"DI",1
		db #f3,#00
		db 8,"DISP",#81
		dw _phase
		db 11,"DISPLAY",#81
		dw _display
		db 8,"DJNZ",#80
		dw _djnz
		db 6,"DS",#81
		dw _ds
		db 7,"DUP",#81
		dw _dup
		db 6,"DW",#81
		dw _dw
		db 9,"DWORD",#81
		dw _dd
		db 8,"EDUP",#81
		dw _edup
		db 6,"EI",1
		db #fb,#00
		db 8,"ELSE",#81
		dw _else
		db 10,"ELSEIF",#81
		dw _elseif
		db 9,"ENDIF",#81
		dw _endif
		db 7,"ENT",#81
		dw _dephase
		db 9,"ENTRY",#81	; добавлено в v0.2X
		dw _entry		; добавлено в v0.2X
		db 9,"ERROR",#81
		dw _error
		db 6,"EX",#80
		dw _ex
		db 7,"EXA",1
		db #08,#00
		db 7,"EXX",1
		db #d9,#00
		db 8,"HALT",1
		db #76,#00
		db 6,"IF",#81
		dw _if
		db 9,"IFDEF",#81
		dw _ifdef
		db 7,"IFN",#81
		dw _ifn
		db 10,"IFNDEF",#81
		dw _ifndef
		db 6,"IM",#80
		dw _im
		db 6,"IN",#80
		dw _in
		db 7,"INC",#80
		dw _inc
		db 10,"INCBIN",#81	; добавлено в v0.2X
		dw _incbin		; добавлено в v0.2X
		db 11,"INCLUDE",#81
		dw _include
		db 7,"IND",2
		db #ed,#aa
		db 8,"INDR",2
		db #ed,#ba
		db 7,"INF",2
		db #ed,#70
		db 7,"INI",2
		db #ed,#a2
		db 8,"INIR",2
		db #ed,#b2
		db 6,"JP",#80
		dw _jp
		db 6,"JR",#80
		dw _jr
		db 6,"LD",#80
		dw _ld
		db 7,"LDD",2
		db #ed,#a8
		db 8,"LDDR",2
		db #ed,#b8
		db 7,"LDI",2
		db #ed,#a0
		db 8,"LDIR",2
		db #ed,#b0
		db 7,"NEG",2
		db #ed,#44
		db 7,"NOP",1
		db #00,#00
		db 6,"OR",#80
		dw _or
		db 7,"ORG",#81
		dw _org
		db 8,"OTDR",2
		db #ed,#bb
		db 8,"OTIR",2
		db #ed,#b3
		db 7,"OUT",#80
		dw _out
		db 8,"OUTD",2
		db #ed,#ab
		db 10,"OUTEND",#81
		dw _outend
		db 8,"OUTI",2
		db #ed,#a3
		db 10,"OUTPUT",#81
		dw _output
		db 9,"PHASE",#81
		dw _phase
		db 7,"POP",#80
		dw _pop
		db 8,"PUSH",#80
		dw _push
		db 7,"RES",#80
		dw _res
		db 7,"RET",#80
		dw _ret
		db 8,"RETI",2
		db #ed,#4d
		db 8,"RETN",2
		db #ed,#45
		db 6,"RL",#80
		dw _rl
		db 7,"RLA",1
		db #17,#00
		db 7,"RLC",#80
		dw _rlc
		db 8,"RLCA",1
		db #07,#00
		db 7,"RLD",2
		db #ed,#6f
		db 6,"RR",#80
		dw _rr
		db 7,"RRA",1
		db #1f,#00
		db 7,"RRC",#80
		dw _rrc
		db 8,"RRCA",1
		db #0f,#00
		db 7,"RRD",2
		db #ed,#67
		db 7,"RST",#80
		dw _rst
		db 8,"SAVE",#81
		dw _savebin
		db 11,"SAVEBIN",#81
		dw _savebin
		db 7,"SBC",#80
		dw _sbc
		db 7,"SCF",1
		db #37,#00
		db 7,"SET",#80
		dw _set
		db 7,"SLA",#80
		dw _sla
		db 7,"SLI",#80
		dw _sll
		db 7,"SLL",#80
		dw _sll
		db 7,"SRA",#80
		dw _sra
		db 7,"SRL",#80
		dw _srl
		db 9,"STACK",#81	; добавлено в v0.2X
		dw _stack		; добавлено в v0.2X
		db 7,"SUB",#80
		dw _sub
		db 12,"UNDEFINE",#81
		dw _undefine
		db 11,"WARNING",#81
		dw _display
		db 8,"WORD",#81
		dw _dw
		db 7,"XOR",#80
		dw _xor
		db #00
