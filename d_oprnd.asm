;-----------------------------------------------------------------------------
;--		     Определение операндов мнемоник			    --
;-----------------------------------------------------------------------------
;Код операнда помещается в переменные Operand1 и Operand2
;и имеет следующие значения:
;#00 - нет операнда   #10 - DE		  #20 - (HL)
;#01 - A	      #11 - HL		  #21 - (IX)
;#02 - B	      #12 - SP		  #22 - (IX+n)
;#03 - C	      #13 - PO		  #23 - (IY)
;#04 - D	      #14 - NZ		  #24 - (IY+n)
;#05 - E	      #15 - PE		  #25 - (SP)
;#06 - H	      #16 - NC
;#07 - L	      #17 - IX
;#08 - I	      #18 - HX или XH
;#09 - R	      #19 - LX или XL
;#0A - M	      #1A - IY
;#0B - P	      #1B - HY или YH
;#0C - Z	      #1C - LY или YL
;#0D - AF	      #1D - (C)
;#0E - AF"	      #1E - (BC)	  #FE - (выражение)
;#0F - BC	      #1F - (DE)	  #FF - выражение
;
;Вход:		A  - первый символ операнда
;		HL - адрес следующего символа операнда
;Выход: A  - код символа, заканчивающий команду (";",":",#0D или ",")
;		HL - адрес следующего символа
; Operand1 - код первого операнда
; Operand2 - код второго операнда
;
OperDetect	cp " "
		call z,SkipSpace
		cp #09
		call z,SkipSpace
		cp #0d
		ret z
		cp ":"
		ret z
		cp ";"
		ret z
		call OD100	;определение первого операнда
		ld a,b
		ld (Operand1),a
		ld a,(hl)	;следующий за операндом символ
		inc hl
		cp " "
		call z,SkipSpace
		cp #09
		call z,SkipSpace
		cp ","
		jr z,OD101	;ищем второй операнд
		cp #0d
		ret z
		cp ":"
		ret z
		cp ";"
		ret z
OD10		ld b,SyntaxEr	;"Синтаксическая ошибка"
		jp SkipStrC	;выход в головную программу

OD101		ld a,(hl)
		inc hl
		cp " "
		call z,SkipSpace
		cp #09
		call z,SkipSpace
		call OD100
		ld a,b
		ld (Operand2),a
		ld a,(hl)	;следующий за операндом символ
		inc hl
		cp " "
		call z,SkipSpace
		cp #09
		call z,SkipSpace
		cp #0d
		ret z
		cp ":"
		ret z
		cp ";"
		ret z
		ld b,SyntaxEr	;ошибка
		jp SkipStrC
;
;Вход:		A  - первый символ операнда
;		HL - адрес следующего символа
;Выход: HL - адрес символа, идущего после операнда
;		B  - код определенного операнда
;
OD100		ld e,a
		call Letter	;символ - буква?
		jr c,OD1	;да - "C"

		cp "("		;операнд в скобках
		jr nz,ODVar
		ld a,(hl)
		inc hl
		cp " "		;пробел
		call z,SkipSpace
		cp #09		;табуляция
		call z,SkipSpace
		dec hl
		call Letter	;символ - буква?
		ld a,e
		jr nc,ODVar
		jp ODSkob	;да - "C"

OD1		ld a,(hl)	;смотрим следующий символ
		cp " "		;операнд состоит из одного символа?
		jp z,ODOne
		cp #09
		jp z,ODOne
		cp ","
		jp z,ODOne
		cp #0d
		jp z,ODOne
		cp ":"
		jp z,ODOne
		cp ";"
		jp z,ODOne

		call Letter	;символ - буква?
		jr nc,ODVar

		ld b,a
		inc hl		;к 3-му символу операнда
		ld a,(hl)
		cp " "		;операнд состоит из двух символов?
		jp z,ODTwo
		cp #09
		jp z,ODTwo
		cp ","
		jp z,ODTwo
		cp #0d
		jp z,ODTwo
		cp ":"
		jp z,ODTwo
		cp ";"
		jp z,ODTwo

OD4		dec hl
;
;Определение выражения
;Вход: E - первый символ выражения
;      HL - адрес следующего символа
;
ODVar		ld a,e
		ld b,#fe	;код выражения в скобках
		cp "("
		jr z,ODV1
		inc b		;код выражения

ODV4		call Letter	;попытка определить забытую пару AF'
		jr nc,ODV1
		and #df
		cp "A"		;пара AF?
		ld a,e
		jr nz,ODV1
		ld a,(hl)
		inc hl
		and #df
		cp "F"
		jr nz,ODV2
		ld a,(hl)
		inc hl
		cp "'"
		jr nz,ODV3
		ld b,#0e	;код пары AF' 
		ret

ODV3		dec hl
ODV2		ld a,e
		dec hl


ODV1		call GetVar	;расчет выражения
		push hl
		ld hl,Var1
		ld (hl),e
		inc hl
		ld (hl),d
		pop hl

		dec hl		;на символ, идущий после выражения
		ret
;
;Определение односимвольного операнда
;Вход: E  - символ операнда
;Выход: B  - значение операнда
;      HL - адрес символа, идущего после операнда
;      при ошибке переходим на поиск переменной
;
ODOne		ld a,e
		and #df		;переводим в верхний регистр
		cp "F"		;проверка диапазона "A"..."E"
		jr nc,ODO2

		sub #40		;вычисляем номер регистра
		ld b,a
		ret

ODO2		ld b,#06
		cp "H"		;регистр H?
		ret z

		inc b
		cp "L"		;регистр L?
		ret z

		inc b
		cp "I"		;регистр I?
		ret z

		inc b
		cp "R"		;регистр R?
		ret z

		inc b
		cp "M"		;флаг M?
		ret z

		inc b
		cp "P"		;флаг P?
		ret z

		inc b
		cp "Z"		;флаг Z?
		ret z

		jp ODVar	;попытка определить переменную
;
;Определение двухсимвольного операнда
;Вход:		B  - второй символ операнда
;		E  - первый символ олеранда
;		HL - адрес следующего символа
;Выход: B  - значение операнда
;		HL - адрес символа, идущего после операнда
;      при ошибке переходим на поиск переменной
;
ODTwo		ld a,e
		and #df		;переводим в верхний регистр 1-ый символ
		ld d,a
		ld a,b
		and #df		;переводим в верхний регистр 2-ой символ
		ld b,#0d	;код пары AF

		cp "F"		;пара AF?
		jr nz,ODT1
		ld a,d
		cp "A"
		ret z

		jp OD4

ODT1		inc b
		inc b
		cp "C"		;пара BC?
		jr nz,ODT2
		ld a,d
		cp "B"
		ret z

		ld b,#16
		cp "N"		;флаг NC?
		ret z

		jp OD4

ODT2		inc b
		cp "E"		;пара DE?
		jr nz,ODT3
		ld a,d
		cp "D"
		ret z

		ld b,#15
		cp "P"		;флаг PE?
		ret z

		jp OD4

ODT3		inc b
		cp "L"		;пара HL?
		jr nz,ODT4
		ld a,d
		cp "H"
		ret z

		ld b,#19
		cp "X"		;регистр XL?
		ret z

		ld b,#1c
		cp "Y"		;регистр YL?
		ret z

		jp OD4

ODT4		inc b
		cp "P"		;пара SP?
		jr nz,ODT6
		ld a,d
		cp "S"
		ret z

		jp OD4

ODT6		inc b
		cp "O"		;флаг PO?
		jr nz,ODT7
		ld a,d
		cp "P"
		ret z

		jp OD4

ODT7		inc b
		cp "Z"		;флаг NZ?
		jr nz,ODT8
		ld a,d
		cp "N"
		ret z

		jp OD4

ODT8		inc b
		inc b
		inc b
		cp "X"		;пара IX?
		jr nz,ODT9
		ld a,d
		cp "I"
		ret z

		inc b
		cp "H"		;регистр HX?
		ret z

		inc b
		cp "L"		;регистр LX?
		ret z

		jp OD4

ODT9		ld b,#1A
		cp "Y"		;пара IY?
		jr nz,ODT10
		ld a,d
		cp "I"
		ret z

		inc b
		cp "H"		;регистр HY?
		ret z

		inc b
		cp "L"		;регистр LY?
		ret z

		jp OD4

ODT10		ld b,#18
		cp "H"		;регистр XH?
		jp nz,OD4
		ld a,d
		cp "X"
		ret z

		ld b,#1b
		cp "Y"		;регистр YH?
		ret z

		jp OD4
;
;Определение операнда в скобках
;Вход:		A  - первый символ операнда "("
;		E  -	 - " -
;		HL - адрес следующего символа
;Выход: B  - значение операнда
;      при ошибке переходим на поиск переменной
;
ODSkob		push hl		;сохраняем адрес в строке
		ld b,#1d

		ld a,(hl)
		inc hl
		and #df		;переводим в верхний регистр 1-ый символ
		ld d,a
		cp "C"		;(C ?
		ld a,(hl)	;смотрим следующий символ
		jr nz,ODS1
		inc hl
		cp " "		;пробел
		call z,SkipSpace
		cp #09		;табуляция
		call z,SkipSpace
		dec hl
		cp ")"		;(C) ?
		jr z,ODSEx	;выход из процедуры

ODS1		call Letter	;2-ой символ буква?
		jr nc,ODSEx1

		and #df		;переводим в верхний регистр 2-ый символ

		inc b
		cp "C"
		jr nz,ODS2
		ld a,d
		cp "B"		;(BC ?
		jr z,ODS10
		jr ODSEx1

ODS2		inc b
		cp "E"
		jr nz,ODS3
		ld a,d
		cp "D"		;(DE ?
		jr z,ODS10
		jr ODSEx1

ODS3		inc b
		cp "L"
		jr nz,ODS5
		ld a,d
		cp "H"		;(HL ?
		jr z,ODS10
		jr ODSEx1

ODS5		inc b
		cp "X"
		jr nz,ODS6
		ld a,d
		cp "I"		;(IX ?
		jr z,ODS100
		jr ODSEx1

ODS6		inc b
		inc b
		cp "Y"
		jr nz,ODS4
		ld a,d
		cp "I"		;(IY ?
		jr z,ODS100
		jr ODSEx1

ODS4		inc b
		inc b
		cp "P"
		jr nz,ODSEx1
		ld a,d
		cp "S"		;(SP ?
		jr z,ODS10

ODSEx1		pop hl
		jp ODVar	;попытка определить переменную

ODS10		inc hl
		ld a,(hl)
		inc hl
		cp " "		;пробел
		call z,SkipSpace
		cp #09		;табуляция
		call z,SkipSpace
		dec hl
		cp ")"		;проверка наличия закрывающейся скобки
		jr nz,ODSEx1

ODSEx		pop de
		inc hl
		ret

ODS100		inc hl
		ld a,(hl)
		inc hl
		cp " "		;пробел
		call z,SkipSpace
		cp #09		;табуляция
		call z,SkipSpace
		dec hl
		ld c,a
		cp ")"		;(IX) или (IY) ?
		jr z,ODSEx
		cp "-"		;(IX- или (IY- ?
		jr z,ODS101
		cp "+"		;(IX+ или (IY+ ?
		jr nz,ODSEx1	;неопределен

ODS101		inc b
		ld a,"("
		inc hl
		call GetVar
		ex af,af' ;'
		ld a,c
		cp "+"
		jr z,ODS102

		xor a
		sub e
		ld e,a
ODS102		ld a,e
		ld (Var2),a
		ex af,af' ;'
		pop de
		dec hl
		ret

