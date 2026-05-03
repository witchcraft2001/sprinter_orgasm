;
;-- Разбор строки листинга --
;
;Вход:		HL - адрес начала строки в памяти
;Выход: HL - адрес следующей строки в памяти
;
ScanString	xor a		;инициализация переменной значения метки
		ld (LabelVar+1),a
		ld a,(CondActive)
		or a
		jp z,CondSkipLine

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

;Разбор строки внутри неактивного блока IF/ELSE/ENDIF.
;Обычные строки пропускаются без синтаксического анализа.
CondSkipLine	ld a,(hl)
		inc hl
		cp #09
		jr z,CondSkipLine
		cp #20
		jr z,CondSkipLine
		cp #0d
		jp z,SkipStr
		cp ";"
		jp z,SkipStr
		call Letter
		jp nc,SkipStr
		ld de,CmndBuf
		ld b,10
CSL1		and #df
		ld (de),a
		inc de
		ld a,(hl)
		inc hl
		cp #09
		jr z,CSL2
		cp #20
		jr z,CSL2
		cp ":"
		jr z,CSL2
		cp ";"
		jr z,CSL2
		cp #0d
		jr z,CSL2
		call Letter
		jp nc,SkipStr
		djnz CSL1
		jp SkipStr
CSL2		ld (CondDelim),a
		xor a
		ld (de),a
		ld a,(CmndBuf)
		cp "I"
		jr z,CSL_IF
		cp "E"
		jr z,CSL_E
		jp SkipStr
CSL_IF		ld a,(CmndBuf+1)
		cp "F"
		jp nz,SkipStr
		ld a,(CmndBuf+2)
		or a
		jr z,CSL_IF0
		cp "D"
		jr z,CSL_IFDEF
		cp "N"
		jp nz,SkipStr
		ld a,(CmndBuf+3)
		or a
		jr z,CSL_IF0
		cp "D"
		jp nz,SkipStr
		ld a,(CmndBuf+4)
		cp "E"
		jp nz,SkipStr
		ld a,(CmndBuf+5)
		cp "F"
		jp nz,SkipStr
		ld a,(CmndBuf+6)
		or a
		jp nz,SkipStr
		jr CSL_IF0
CSL_IFDEF	ld a,(CmndBuf+3)
		cp "E"
		jp nz,SkipStr
		ld a,(CmndBuf+4)
		cp "F"
		jp nz,SkipStr
		ld a,(CmndBuf+5)
		or a
		jp nz,SkipStr
CSL_IF0	call CondPushInactive
		jp SkipStr
CSL_E		ld a,(CmndBuf+1)
		cp "L"
		jr z,CSL_ELSE
		cp "N"
		jp nz,SkipStr
		ld a,(CmndBuf+2)
		cp "D"
		jp nz,SkipStr
		ld a,(CmndBuf+3)
		cp "I"
		jp nz,SkipStr
		ld a,(CmndBuf+4)
		cp "F"
		jp nz,SkipStr
		ld a,(CmndBuf+5)
		or a
		jp nz,SkipStr
		ld a,(CondDelim)
		call _endif
		jp SkipStr
CSL_ELSE	ld a,(CmndBuf+2)
		cp "S"
		jp nz,SkipStr
		ld a,(CmndBuf+3)
		cp "E"
		jp nz,SkipStr
		ld a,(CmndBuf+4)
		or a
		jr z,CSL_ELSE0
		cp "I"
		jp nz,SkipStr
		ld a,(CmndBuf+5)
		cp "F"
		jp nz,SkipStr
		ld a,(CmndBuf+6)
		or a
		jp nz,SkipStr
		ld a,(CondDelim)
		call _elseif
		jp SkipStr
CSL_ELSE0	ld a,(CondDelim)
		call _else
		jp SkipStr
