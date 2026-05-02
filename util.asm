;-----------------------------------------------------------------------------
;--			      Вспомогательные утилиты			    --
;-----------------------------------------------------------------------------
;-- Проверка символа. Буква латинского алфавита или нет? --
;Вход:		A  - код символа
;Выход:"C" - буква
;      "NC"- другой символ
;
Letter		cp "A"
		ccf
		ret nc
		cp "{"
		ret nc
		cp "["
		ret c
		cp "a"
		ccf
		ret
;
;-- Проверка символа. Цифра или нет? --
;Вход:		A  - код символа
;Выход:"C" - цифра
;      "NC"- другой символ
;
Numeric		cp "0"
		ccf
		ret nc
		cp ":"
		ret
;
;-- Перевод символа в CapsLock --
;Символ из A переводится в верхний регистр (только латинские буквы)
;
CapsLetter	cp #61		;<"a"
		ret c
		cp #7b		;>"z"
		ret nc
		and #df
		ret
;
;-- Пропуск табуляции и пробелов --
;Вход:		HL - адрес следующего за пробелом символа
;Выход: A  - первый символ отличный от пробела
;		HL - адрес следующего символа
;		флаг С установлен
;
SkipSpace	ld a,(hl)
		inc hl		;пропускаем пробелы и символы табуляции
;		 inc c
		cp #09
		jr z,SkipSpace
		cp #20
		jr z,SkipSpace
		ret
;
;-- Пропуск оставшейся части строки при возникновени ошибки --
;Вход:		A  - очередной символ строки
;		HL - адрес следующего символа строки
;		B  - номер ошибки
;Выход: HL - адрес начала новой строки
;
SkipStrC	call ErrorAsm	;обработать ошибку
SkipStr		ld sp,(RetAddres)
SStrC2		cp #0d
		jr z,SStrC1
		ld a,(hl)	;ищем конец строки
		inc hl
		jr SStrC2
SStrC1		;inc hl
		ld a,(hl)
		cp #0a
		ret nz
		inc hl
;		 ld a,b
;		 scf		 ;установить флаг "C"
		ret
;
;-- Копирование спецификации файла в буфер --
;Вход: A  - пробел или табуляция
;      HL - начало строки спецификаци
;      DE - выходной буфер
;Выход: HL - адрес следующей строки
;		DE - нулевой байт окончания строки в буфере
;
SpecFile	call SkipSpace
		ld b,SyntaxEr	;"Синтаксическая ошибка"
		ld c,a
		cp "'"		;имя файла заключено в кавычки?
		jr z,SpecF1
		cp '"'
		jp nz,SkipStrC

SpecF1		ld a,(hl)
		inc hl
		cp #20
		jp c,SkipStrC	;не обнаружена закрывающаяся кавычка
		ld (de),a
		inc de
		cp c
		jr nz,SpecF1

		ld a,(hl)	;следующий после ковычек символ
		inc hl
		cp #20		;пробел
		call z,SkipSpace
		cp #09		;табуляция
		call z,SkipSpace
		ld c,a		;добавлено в v0.2X
		cp ","		;запятая добавлена в v0.2X
		jr z,SpecF3	;добавлено в v0.2X
		cp ";"		;комментарии
		jr z,SpecF2
		cp #0d
		jp nz,SkipStrC

SpecF2		call SStrC2	;пропускаем оставшуюся часть строки
SpecF3		dec de
		xor a
		ld (de),a
		ld a,c ; добавлено в v0.2X
		ret
;
;-- Печать строки с проверкой выхода за пределы экрана и --
;-- переводом символов в нижний регистр --
;Вход: HL - начало строки
;
PrString	push hl
		ld c,Cursor
		call DSS	;текущие координаты курсора
		ld c,PutChar
		ld b,e

PrStr1		pop hl
		ld a,(hl)
		or a		;напечатали всю строку?
		jr z,PrStr3

		cp #41
		jr c,PrStr2
		cp #5b
		jr nc,PrStr2
		or #20
PrStr2		inc hl
		inc b
		push hl
		push bc
		call DSS
		pop bc

		ld a,b
		cp 79		;последняя позиция?
		jr nz,PrStr1
		pop hl

PrStr3		ld hl,CRLF
		ld c,PChars
		jp DSS
;
;-- Проверка наличия расширеия и автоматическое его добавление --
;Вход: DE - нулевой байт спецификации файла
;      
AddExtAsm	push bc
		push hl
		ld a,"."
		ld h,d
		ld l,e
		dec hl
		ld bc,4
		cpdr
		pop hl
		pop bc
		ret z
		ld a,"."
		ld (de),a
		inc de
		ld a,"a"
		ld (de),a
		inc de
		ld a,"s"
		ld (de),a
		inc de
		ld a,"m"
		ld (de),a
		inc de
		xor a
		ld (de),a	;0 - окончание строки спецификации
		ret
		  

; Новый код, добавленный в v0.2X

NewSub		ld     a, 1
		ld     (OutFileID+1), a ; ???
		ld     b, a
		ld     a, (OutFileID) ; ???
		ld     c, SetMem
		rst    #10
		jp     c, ErrorDSS
		ld     c, 0
		ld     hl, #8000
		ld     (SaveObjAdr), hl
L0201		ld     a, c
		push   bc
		call   SetBankMap
		pop    bc
L0202		ld     a, (hl)
		or     a
		ret    z
		ld     d, h
		ld     e, l
		push   bc
		ld     b, 0
		ld     c, a
		add    hl, bc
		push   hl
		ex     de, hl
		inc    hl
		ld     a, (Operand1)
		or     a
		jr     z, L0213
		bit    7, (hl)
		jp     z, L0212
L0213		dec    c
		dec    c
		dec    c
		ld     a, c
		cp     #DD
		jr     c, L0211
		ld     c, #DC
L0211		db #FD,#60 	; undefined
		db #FD,#69 	; undefined
		ld     ix, 0
		push   hl
		push   bc
		ld     c, a
		ld     a, "."
		cpir
		pop    bc
		pop    hl
		jr     nz, L0210
		db #DD,#2C 	; undefined
		inc    c
L0210		ld     a, c
		cp     #08
		jr     nc, L0209
		db #DD,#24 	; undefined
		inc    c
L0209		push   bc
		push   de
		ld     de, DataBuf
		db #FD,#44 	; undefined
		db #FD,#4D 	; undefined
		db #DD,#7D 	; undefined
		or     a
		jr     z, L0208
		ld     a, ";"
		ld     (de), a
		inc    de
L0208		ldir
		db #DD,#7C 	; undefined
		or     a
		ld     a, #09
		jr     z, L0207
		ld     (de), a
		inc    de
L0207		ld     (de), a
		inc    de
		ld     a, "E"
		ld     (de), a
		inc    de
		ld     a, "Q"
		ld     (de), a
		inc    de
		ld     a, "U"
		ld     (de), a
		inc    de
		ld     a, " "
		ld     (de), a
		inc    de
		ld     a, "#"
		ld     (de), a
		inc    de
		pop    hl
		dec    hl
		ld     a, (hl)
		and    #f0
		rra
		rra
		rra
		rra
		add    a, #30
		cp     ":"
		jr     c, L0206
		add    a, #07
L0206		ld     (de), a
		inc    de
		ld     a, (hl)
		and    #0f
		add    a, #30
		cp     ":"
		jr     c, L0205
		add    a, #07
L0205	 	ld     (de), a
		inc    de
		dec    hl
		ld     a, (hl)
		and    #f0
		rra
		rra
		rra
		rra
		add    a, #30
		cp     ":"
		jr     c, L0204
		add    a, #07
L0204		ld     (de), a
		inc    de
		ld     a, (hl)
		and    #0f
		add    a, #30
		cp     ":"
		jr     c, L0203
		add    a, #07
L0203		ld     (de), a
		inc    de
		ld     a, #09
		ld     (de), a
		inc    de
		ld     a, ";"
		ld     (de), a
		inc    de
		ld     a, (hl)
		inc    hl
		ld     h, (hl)
		ld     l, a
		call   Hex2Dec
		inc    de
		ld     a, #0d
		ld     (de), a
		inc    de
		ld     a, #0a
		ld     (de), a
		pop    bc
		ld     hl, #0013
		add    hl, bc
		ld     b, l
		ld     de, 06baeh
		ld     a, (de)
		res    7, a
		ld     (de), a
		call   ObjCopy2
L0212		pop    hl
		pop    bc
		bit    6, h
		jp     z, L0202
		res    6, h
		inc    c
		jp     L0201
