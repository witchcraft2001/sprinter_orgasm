;
;-- Разбор строки листинга --
;
;Вход:		HL - адрес начала строки в памяти
;Выход: HL - адрес следующей строки в памяти
;
ScanString	xor a		;инициализация переменной значения метки
		ld (LabelVar+1),a

		ld a,(hl)
		inc hl
		cp #09		;символ табуляции
		jr z,SS1
		cp #20		;символ пробела
		jr z,SS1
		cp #0d		;конец строки
		jp z,SkipStr
		cp ";"		;комментарий
		jp z,SkipStr

		call ScanLabel	;иначе, ищем метку
		cp #09		;табуляция
		jr z,SS7
		cp #20		;пробел
		jr z,SS7
		cp #0d		;конец строки
		jr z,SS2
		cp ";"		;коментарии
		jr z,SS2
		cp ":"		;символ двоеточия
		jp nz,SL10	;ошибка, неверный символ в имени метки
		ld a,(hl)	;пропускаем ":"
		inc hl
		cp #09		;табуляция
		call z,SkipSpace
		cp #20		;пробел
SS7		call z,SkipSpace

SS2		ld c,a
		ld a,(Pass)	;номер прохода
		or a
		ld a,c
		jr nz,SS5	;если 1-ый проход, то
		call NewLabel	;заносим ее в таблицу меток
		jr SS3
SS1		call SkipSpace
SS3		cp #0d		;конец строки
		jp z,SkipStr
		cp ";"		;комментарий
		jp z,SkipStr
;		 cp #09		 ;символ табуляции
;		 call z,SkipSpace
;		 cp #20		 ;символ пробела
;		 call z,SkipSpace

SS4		ex af,af' ;'
		xor a		;инициализация переменных и буферов
		ld (CmndBuf),a
		ld (Operand1),a
		ld (Operand2),a
		ld (Var1),a
		ld (Var1+1),a
		ld (Var2),a
		ex af,af' ;'

		call ScanCmnd	;определение команды
;		 cp ':'
;		 jr z,SS4
		ld a,(hl)
		inc hl
		cp #09		;символ табуляции
		call z,SkipSpace
		cp #20		;символ пробела
		call z,SkipSpace
		cp #0d		;конец строки
		jp z,SkipStr
		cp ";"		;комментарий
		jp z,SkipStr
		jr SS4
;		 jp SkipStr

SS5		push hl
		push af
		call CapsLetter
		cp "E"
		jr nz,SS6
		ld a,(hl)
		inc hl
		call CapsLetter
		cp "Q"
		jr nz,SS6
		ld a,(hl)
		inc hl
		call CapsLetter
		cp "U"
		jr nz,SS6
		ld a,(hl)
		inc hl
		cp #20 ; пробел
		jr z,SS8
		cp #09 ; табуляция
		jr nz,SS6 ; начало добавления в v0.2X
SS8		call GetVar2
		cp ':'
		jr nz,SS9
		ld a,(hl)
		inc hl
		cp #09 ; табуляция
		call z,SkipSpace
		cp #20 ; пробел
		call z,SkipSpace
SS9		pop de
		pop de
		jr SS3 ; конец добавления в v0.2X
SS6		pop af
		pop hl
		jr SS3



