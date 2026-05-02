;-----------------------------------------------------------------------------
;--			  Процедуры обработки меток			    --
;-----------------------------------------------------------------------------
;  Таблица меток построена следующим образом:
; - метки расположены по возрастанию символов
; - каждая метка в таблице занимает от 4 до 255 байт
;    1 байт	- длина записи в таблице
;    1-252 байт - имя метки
;    2 байта	- значение метки
; - байт #00 является признаком конца таблицы
;
;-- Сканирование метки --
;конец метки определяется:
;  по символу табуляции, пробелу, ":", ";" или символам конца строки
;Вход:		HL - адрес второго символа метки
;		A  - первый символ метки
;Выход: HL - адрес первого символа после метки
;
; процедура ScanLabel была полностью изменена в v0.2X
ScanLabel	ld     b,1
		jr     ScanLabel2
ScanLabel1	ld     b,0

ScanLabel2	ld     de,WordBuf
		ld     c,#FC
		cp     "."
		jr     z,SL11
		cp     "@"
		jr     nz,SL9
		ld     a, (hl)
		inc    hl
		cp     "_"
		jr     z,SL7
		call   Letter
		jr     nc,SL10
SL7		set    7, a
		jr     SL5
SL11		push   hl
		ld     hl,SomeBuf ; новый буфер добавленный в v0.2X
SL8		ld     a, (hl)
		or     a
		jr     z,SL6
		ld     (de), a
		inc    de
		inc    hl
		dec    c
		jr     SL8
SL6		ld     a,"."
		ld     (de), a
		inc    de
		dec    c
		pop    hl
		ld     a, (hl)
		inc    hl
		ld     b,2
SL9		cp     "_"
		jr     z,SL5
		call   Letter
		jr     c,SL5
SL10		ld     b,2
		jp     SkipStrC
SL5		dec    c
		inc    c
		jr     z,SL4
		dec    c
		ld     (de), a
		inc    de
SL4		ld     a, (hl)
		inc    hl
		cp     "_"
		jr     z,SL5
		call   Letter
		jr     c,SL5
		call   Numeric
		jr     c,SL5
		cp     "."
		jr     nz,SL3
		bit    1,b
		jr     nz,SL3
		ld     b,2
		jr     SL5
SL3		push   af
		xor    a
		ld     (de), a
		bit    0, b
		jr     z,SL1
		push   hl
		ld     hl,WordBuf
		ld     de,SomeBuf ; новый буфер добавленный в v0.2X
		push   de
		ld     bc,255
		ldir
		pop    hl
		res    7,(hl)
		pop    hl
SL1		pop    af
		ret
;
;-- Занесение метки в таблицу меток --
;
;Метка должна находиться в буфере WordBuf и заканчиваться #00
;При занесении метки возможно возникновение двух ошибок
;
NewLabel	push hl		;адрес в строке
		push af		;текущий символ
		call CapsLetter
		cp "E"
		jr nz,NL5
		ld a,(hl)	;следующий символ
		inc hl
		call CapsLetter
		cp "Q"
		jr nz,NL5
		ld a,(hl)	;следующий символ
		inc hl
		call CapsLetter
		cp "U"
		jr nz,NL5
		ld a,(hl)	;следующий символ
		inc hl
		cp #09		;табуляция
		jr z,$+6
		cp " "		;пробел
		jr nz,NL5
		
		push hl
		ld hl,WordBuf	;спрятать метку из буфера
		ld de,DataBuf
		ld bc,255
		ldir
		pop hl
		call GetVar2

		push hl
		push de
		ld hl,DataBuf	;востановить метку из буфера
		ld de,WordBuf
		ld bc,255
		ldir
		pop de
		pop hl
		
		cp ":"
		jr nz,NL11
		ld a,(hl)
		inc hl
		cp #09		;табуляция
		call z,SkipSpace
		cp #20		;пробел
		call z,SkipSpace
NL11		pop bc
		pop bc
		jr NL6

NL5		ld de,(PCAddres)
		pop af
		pop hl
NL6		ld (LabelVar),de
		exx		;прячем основной набор регистров
		ex af,af' ;'
		call SearchLabel;ищем метку в таблице
		jp m,NL0

		exx		;возвращаем основной набор регистров
		ex af,af' ;'
		ld b,LabelAlrEr ;ошибка "Повторная метка"
		jp SkipStrC	;выход по ошибке

NL0		in a,(Page2)	;номер страницы вкл. во 2-е окно
		push af
		in a,(Page3)	;номер страницы вкл. в 3-е окно
		push af
		push hl
;		 ld hl,(MemID)
;		 ld a,(hl)
		ld a,(MapLabelID)
;		 inc hl
		ld b,0		;номер 1-ой логической страницы
		ld c,a
		push bc

		ld c,SetWin2
;		 rst #10
;		 jp c,Error
		call DSS
;		 ld c,EMM_Fn4
;		 call BIOS	 ;вычисление физического номера страницы
;		 out (#c2),a	 ;вкл. ее во 2-е окно
		pop bc
		ld a,c
		inc b

		ld c,SetWin3
;		 rst #10
;		 jp c,Error
		call DSS
;		 ld c,EMM_Fn4
;		 call BIOS	 ;вычисление физического номера страницы
;		 out (#e2),a	 ;вкл. ее в 3-е окно

		pop hl		;адрес вставки метки
		push hl
		push hl

		ld d,0
NL1		ld a,(hl)	;поиск конца таблицы меток
		or a
		jr z,NL10
		ld e,a
		add hl,de	;к следующей метке
		jr NL1

NL10		pop de
;		 push de	 ;адрес вставки
		push hl
		push hl		;конец таблицы меток
		or a
		sbc hl,de
		inc hl		;длина перемещаемого блока
		push hl

		ld hl,WordBuf	;вычисляем длину метки из буфера
		ld bc,#00ff
		xor a
		cpir		;поиск конца метки в буфере	 
		inc bc
		sub c		;в A длина метки
		inc a		;увеличиваем длину метки
		inc a		;1 байт - длина метки
;		 inc a		 ;2 байта - значение метки
		ld e,a
		ld d,b

		pop bc


;		 ld de,#00ff	 ;вычисляем длину метки из буфера
;		 ld hl,WordBuf	 ;начало новой метки
;NL2		 ld a,(hl)	 ;очередной байт из буфера
;		 inc e
;		 inc hl
;		 or a
;		 jr nz,NL2
;		 inc e		 ;увеличиваем длину метки
;		 inc e		 ;1 байт - длина метки
;		 inc e		 ;2 байта - значение метки

		pop hl
;		 CALL Debug
		add hl,de	;куда переносим блок
		pop de
		jr nc,NL3	;переход через #0000 (переполнение таблицы)
;		 ld a,(EndLabel) ;старший байт max адреса таблицы меток
;		 cp h
;		 ld a,c		 ;длина вставляемой записи
;NL4		 ;pop de
;		 jr nc,NL3	 ;переполнения нет

		exx
		ex af,af' ;'
		ld b,LabelTabEr ;ошибка "Переполнение таблицы меток"
		jp SkipStrC

NL3		ex de,hl	;hl-откуда, de-куда, bc-сколько
;		 CALL Debug
		lddr		;раздвигаем таблицу меток

		pop hl
		ld (hl),a	;заносим длину метки
		sub 3
		ld c,a		;кол-во переносимых из буфера символов
		inc hl
		ex de,hl
		ld hl,WordBuf
;		 CALL Debug
		ldir		;переносим метку из буфера
;		 push de
		ex de,hl
		ld de,(LabelVar);значение метки
;		 CALL Debug
		ld (hl),e
		inc hl
		ld (hl),d
;		 pop de 
;		 or a		 ;сброс флага "C"
		pop af
		out (Page3),a	;востановили банку в 3-eм окне
		pop af
		out (Page2),a	;востановили банку во 2-ом окне
		exx
		ex af,af' ;'
		ret
;
;-- Поиск метки в таблице меток --
;
;Имя метки должно быть в буфере WordBuf
;Таблица меток начинается с адреса TabLabel
;Если переменная CapsLabel = #ff, то регистр символов не различается
;результат:
; "M" - не найдена, HL - адрес вставки метки в таблицу
; "P" - найдена,    HL - адрес метки в таблице
;		    DE - значение метки
;
SearchLabel	in a,(Page2)	;номер страницы вкл. во 2-е окно
		push af
		in a,(Page3)	;номер страницы вкл. в 3-е окно
		push af
;		 ld hl,(MemID)
;		 ld a,(hl)
		ld a,(MapLabelID)
;		 inc hl
		ld b,0		;номер 1-ой логической страницы
		ld c,a
		push bc

		ld c,SetWin2
;		 rst #10
;		 jp c,Error
		call DSS

;		 ld c,EMM_Fn4
;		 call BIOS	 ;вычисление физического номера страницы
;		 out (#c2),a	 ;вкл. ее во 2-е окно
		pop bc
		ld a,c
		inc b

		ld c,SetWin3
;		 rst #10
;		 jp c,Error
		call DSS
;		 ld c,EMM_Fn4
;		 call BIOS	 ;вычисление физического номера страницы
;		 out (#e2),a	 ;вкл. ее в 3-е окно

		ld hl,TabLabel	;адрес начала таблицы меток
SrL1		ld a,(hl)
		dec a		;конец таблицы?
		jp p,SrL6
SrL7		pop af
		out (Page3),a	;востановили банку в 3-eм окне
		pop af
		out (Page2),a	;востановили банку во 2-ом окне
		xor a
		dec a
		ret

SrL6		push hl
		ld b,a
		inc b		;длина записи в таблице меток
		dec a
		dec a		;длина метки
		ld c,a
		inc hl
		ld de,WordBuf
SrL2		push bc
		ld b,(hl)	;символ метки
		res 7,b ;добавлено в v0.2X
		ld a,(CapsLabel)
		inc a
		ld a,(de)
		res 7,a ;добавлено в v0.2X
		jr nz,SrL5
		ld c,a
		ld a,b
		call CapsLetter
		ld b,a
		ld a,c
		call CapsLetter
SrL5		cp b
		pop bc
		jr z,SrL3
		pop hl
		jp m,SrL7
SrL4		ld c,b
		ld b,0		;в BC длина записи в таблице
		add hl,bc	;к следующей метке
		jr SrL1
SrL3		inc de
		inc hl
		dec c
		jr nz,SrL2	;все символы метки из таблицы?
;		 pop hl
		ld a,(de)	;следующий символ из буфера метки
		ex de,hl
		pop hl
		or a		;конец метки в буфере?
;		 ret z		 ;метка найдена
		jr nz,SrL4	;продолжаем поиск
		ex de,hl
		ld e,(hl)	;младший байт значения метки
		inc hl
		ld d,(hl)	;старший байт значения метки
		pop af
		out (Page3),a	;востановили банку в 3-eм окне
		pop af
		out (Page2),a	;востановили банку во 2-ом окне
		xor a
		ret

