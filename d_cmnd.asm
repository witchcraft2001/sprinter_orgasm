;-----------------------------------------------------------------------------
;--		       Разбор операторов компилятора			    --
;-----------------------------------------------------------------------------
;
;ORG ...
_org		ex af,af' ;'
		ld b,InadmisORG ;недопустим ORG в блоке PHASE/DEPHASE
		ld a,(PhaseFlag)
		inc a
		jp z,SkipStrC
		ex af,af' ;'
		call GetVar2	;вызов калькулятора
		ld (PCAddres),de
		ex af,af' ;';начало доработки для v0.2X
		ld a,(Pass)
		inc a
		jr nz,_org1
		ld bc,(SaveObjAdr)
		ld a,#80
		sub b
		or c
		jr nz,_org1
		ld (New1),de
		ld (New2),de
_org1		ex af,af' ;';конец доработки для v0.2X
		ld b,0
		ret
;ENTRY...
_entry		call GetVar ; добавлено целиком в v0.2X
		ld (New2), de
		ld b,0
		ret
;STACK...
_stack		call GetVar ; добавлено целиком в v0.2X
		ld (New3), de
		ld b,0
		ret
;PHASE...
_phase		ex af,af' ;'
		ld b,PhaseEr	;ошибка "Вложенный Phase"
		ld a,(PhaseFlag)
		dec a
		inc a
		jp nz,SkipStrC
		dec a
		ld (PhaseFlag),a;устанавливаем флаг Phase
		ex af,af' ;'
		push hl
		ld hl,(PCAddres);сохраняем текущий адрес ассемблирования
		ld (OrgAddres),hl
		pop hl
		call GetVar2	;расчет адреса
		ld (PCAddres),de
		ld (PhaseAddres),de
		ld b,0
		ret
;DEPHASE...
_dephase	ex af,af' ;'
		ld b,PhaseEr	;ошибка "Не было Phase"
		ld a,(PhaseFlag)
		inc a
		jp nz,SkipStrC
		ld (PhaseFlag),a;сбрасываем флаг Phase
		ex af,af' ;'
		push hl
		ld de,(PhaseAddres)
		ld hl,(PCAddres)
		or a
		sbc hl,de
		ld de,(OrgAddres)
		add hl,de
		ld (PCAddres),hl
		pop hl
		ld b,0
		ret
;DB ...
_db		ld (SaveSP),sp ; добавлено в v0.2X
		jr _db2
_db1		ld a,(hl)
		inc hl
_db2		cp " "
		call z,SkipSpace
		cp #09
		call z,SkipSpace

		cp "'"		;символьное выражение
		jr z,CharVar
		cp '"'		;символьное выражение
		jr z,CharVar
_db0		push de
		call GetVar
		ld c,a
		ld a,e		;значение после калькулятора
		pop de
		ld (de),a	;в буфер
		ld a,c
		inc de
		inc b
		jr nz,CV3
		ld b,DBInstrEr	;"В DB, DW болше 255 байт"
		jp SkipStrC

CharVar		ld c,a		;запомнили тип кавычки
		push bc ; добавлено в v0.2X
		push de ; добавлено в v0.2X
		push hl ; добавлено в v0.2X
CV2		ld a,(hl)	;следующий символ
		inc hl
		cp #09		;проверка табуляции - добавлено в v0.2X
		jr z,CV2A ; +9
		cp #20		;код символа меньше пробела?
		jr nc,CV2A
		ld b,1
		jp SkipStrC
CV2A		cp c
		jr z,CV1
		ld (de),a	;символ в буфер
		inc de
		inc b
		jr nz,CV2
		ld b,DBInstrEr	;"В DB, DW болше 255 байт"
		jp SkipStrC

CV1		ld a,(hl)
		inc hl
CV3		cp " "
		call z,SkipSpace
		cp #09
		call z,SkipSpace
		cp #0d
		jr z,SV4
		cp ":"
		jr z,SV4
		cp ";"
		jr z,SV4
		cp ","
		jr z,_db1
		ld a,c ; добавлено в v0.2X
		pop hl
		pop de
		pop bc
		jr _db0
SV4		ld sp,(SaveSP)
		ret
SaveSP		dw 0
;DW ...
_dw1		ld a,(hl)
		inc hl
_dw		cp " "		;пропуск начальных пробелов
		call z,SkipSpace
		cp #09		;и табуляции
		call z,SkipSpace

		push de
		call GetVar
		ex af,af' ;'
		ld c,d
		ld a,e		;значение после калькулятора
		pop de
		ld (de),a	;в буфер
		inc de
		inc b
		jr nz,_dw2
		ex af,af' ;'
		ld b,DBInstrEr	;"В DB, DW болше 255 байт"
		jp SkipStrC

_dw2		ld a,c
		ld (de),a	;в буфер
		inc de
		inc b
		ex af,af' ;'

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
		cp ","
		jr z,_dw1

		ld b,SyntaxEr	;"Синтаксическая ошибка"
		jp SkipStrC	;выход с ошибкой
;DS ...
_ds ; нижеследующее закомменчено для v0.2X
;		push hl
;		ld hl,WordBuf	;спрятать метку из буфера
;		 ld de,DataBuf
;		ld bc,255
;		ldir
;		pop hl
		call GetVar2

		push de
		push hl
;		ld hl,DataBuf	;востановить метку из буфера
;		ld de,WordBuf
;		ld bc,255
;		ldir
		ld de,DataBuf
		ex af,af' ;'
		xor a
		ld (de),a	;зануляем 1-ый байт буф.(конст.по умолчанию)
		ex af,af' ;'
		pop hl
		ld b,1

		cp " "		;пропуск пробелов
		call z,SkipSpace
		cp #09		;и табуляции
		call z,SkipSpace
		cp ","		;есть второй операнд?
		jr nz,_ds1

		dec b
		ld a,(hl)
		inc hl
		call _db	;повторяемые байты

_ds1		pop de
		ld a,d
		or e
		jr z,_ds2	;если кол-во повторов 0, то выход
		push hl
_ds3		push bc
		push de
		ld de,DataBuf
		call ObjCopy
		pop de
		pop bc
		dec de
		ld a,d
		or e
		jr nz,_ds3

		pop hl
_ds2		dec hl
		ld a,(hl)
		inc hl
		ld b,0
		ret
;INCLUDE...
_include	push hl
		call SpecFile
		cp #2C ; добавлено в v0.2X
		jp z,SkipStrC
		call AddExtAsm

		ld a,(CurrentFile)
		call GoSpec
;		 ld de,#0005
;		 add hl,de
		inc hl
		inc hl
		inc hl
		pop de
		ld a,(TextPage) ;текущий лог.N банки с текстом
		ld (FileNamePage),a
		ld (FileNameAdr),de
		ld (hl),a
		inc hl
		ld (hl),e	;запоминаем начало имени файла в исходнике
		inc hl
		ld (hl),d
		inc hl
		ld de,(NumString)
		ld (hl),e	;запоминаем номер строки компиляции
		inc hl
		ld (hl),d
		ld de,#0000	;и обнуляем его
		ld (NumString),de

		ld hl,Including
		ld c,PChars
		call DSS

		call SaveCurPath
		ld hl,DataBuf
		call LoadFile
		push hl
		call RestoreCurPath
		pop hl

		ld b,#00
		ld a,#0d
		ret
;INCBIN...
_incbin		call SpecFile ;добавлено целиком в v0.2X
		ld de,0
		cp #2C
		push af
		push de
		jr nz,IB2A
		pop de
		pop af
		ld a,(hl)
		inc hl
		call GetVar2
		cp #2C
		push af
		push de
		jr nz,IB1
		ld a,(hl)
		inc hl
		call GetVar2
		ex de,hl
		ex (sp),hl
		ex de,hl
IB1		ld b,1
		cp #20
		call z,SkipSpace
		cp #09
		call z,SkipSpace
		cp #3b
		jr z,IB2
		cp #0d
		jp nz,SkipStrC
IB2		call SStrC2
IB2A		push hl
		push de
		ld hl,IncludingBin
		ld c,PChars
		call DSS
		ld hl,DataBuf
		push hl
		call PrString
		pop hl
		ld a,1
		ld c,Open
		rst #10
		jp c,ErrorDSS
		ld (OpenFile),a
		ld ix,0
		ld hl,0
		ld b,2
		ld c,Move_FP
		rst #10
		jp c,ErrorDSS
		ld b,h
		ld c,l
		push ix
		pop hl
		pop de
		or a
		sbc hl,de
		jr nc,IB3
		ld a,b
		or c
		jr nz,IB3A
		ld h,b
		ld l,c
		inc bc
IB3A		dec bc
IB3		db #DD,#62
		db #DD,#6B
		pop iy
		pop de
		pop af
		push iy
		jr nz,IB4
		or a
		push hl
		sbc hl,de
		pop hl
		jr nc,IB5
		ld a,b
		or c
		jr z,IB4
IB5		ld bc,0
		ex de,hl
IB4		push bc
		push hl
		ld hl,0
		ld b,0
		ld a,(OpenFile)
		ld c,Move_FP
		rst #10
		jp c,ErrorDSS
		pop de
		pop bc
		ld a,e
		or d
		jr nz,IB7
		ld a,c
		or b
		jp z,IB14
IB7		inc bc
		ld hl,(PCAddres)
		add hl,de
		ld (PCAddres),hl
IB13		ld a,(Pass)
		or a
		jr z,IB0
		push bc
		in a,(Page3)
		push af
		push de
		ld de,(SaveObjAdr)
		set 6,d
		ld bc,(OutFileID)
		dec b
IB12		ld a,c
		push de
		ld c,SetWin3
		rst #10
		jp c,ErrorDSS
		ld hl,0
		or a
		pop bc
		sbc hl,bc
		pop de
		ex  de,hl
		push hl
		ld a,h
		or l
		jr nz,IB9
		sbc hl,de
		jr IB10
IB9		sbc hl,de
		jr c,IB11
IB10		pop ix
		push hl
		ld h,b
		ld l,c
		ld a,(OpenFile)
		ld c,Read_
		rst #10
		jp c,ErrorDSS
		ld bc,(OutFileID)
		push bc
		inc b
		ld (OutFileID),bc
		ld a,c
		ld c,SetMem
		rst #10
		jp c,ErrorDSS
		pop bc
		ld  de,#C000
		jr IB12
IB11		res 6,h
		ld (SaveObjAdr),hl
		pop de
		ld h,b
		ld l,c
		ld a,(OpenFile)
		ld c,Read_
		rst #10
		jp c,ErrorDSS
		pop af
		out (Page3),a
		pop bc
IB0		ld de,0
		dec bc
		ld a,b
		or c
		jr nz,IB13
IB14		ld a,(OpenFile)
		ld c,Close
		rst #10
		jp c,ErrorDSS
		xor a
		ld (OpenFile),a
		pop hl
		ld b,0
		ld a,#0D
		ret
