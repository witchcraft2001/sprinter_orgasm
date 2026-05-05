;-----------------------------------------------------------------------------
;--		       Разбор операторов компилятора			    --
;-----------------------------------------------------------------------------
;
;DEFINE name [value]
_define	cp #20
		jr z,DFN0
		cp #09
		jp nz,CondSyntax
DFN0		call SkipSpace
		call ScanLabel1
		ld (CondDelim),a
		push hl
		ld hl,WordBuf
		ld de,DataBuf
		ld bc,255
		ldir
		pop hl
		ld de,1
		ld a,(CondDelim)
		cp #20
		jr z,DFN1
		cp #09
		jr z,DFN1
		call CondEndOnly
		jr DFN2
DFN1		call SkipSpace
		call GetVar2
		ld (CondDelim),a
		call CondEndOnly
DFN2		push hl
		push de
		ld hl,DataBuf
		ld de,WordBuf
		ld bc,255
		ldir
		pop de
		pop hl
		ld a,(Pass)
		or a
		call z,CondNewLabel
		ld a,(CondDelim)
		ld b,0
		ret
;
;UNDEFINE name
_undefine	cp #20
		jr z,UDF0
		cp #09
		jp nz,CondSyntax
UDF0		call SkipSpace
		call ScanLabel1
		ld (CondDelim),a
		call CondEndOnly
		ld (CondDelim),a
		ld a,(Pass)
		or a
		call z,DeleteLabel
		ld a,(CondDelim)
		ld b,0
		ret
;
;IF expr / IFN expr
_if		call CondEval
		call CondPushA
		ld a,(CondDelim)
		ld b,0
		ret
_ifn		call CondEval
		or a
		jr z,IFN1
		xor a
		jr IFN2
IFN1		dec a
IFN2		call CondPushA
		ld a,(CondDelim)
		ld b,0
		ret
;
;IFDEF name / IFNDEF name
_ifdef		call CondLabelDefined
		call CondPushA
		ld a,(CondDelim)
		ld b,0
		ret
_ifndef	call CondLabelDefined
		or a
		jr z,IFND1
		xor a
		jr IFND2
IFND1		dec a
IFND2		call CondPushA
		ld a,(CondDelim)
		ld b,0
		ret
;
;ELSEIF expr / ELSE / ENDIF
_elseif	ld (CondDelim),a
		call CondElseIfNeed
		or a
		jr z,ELIF1
		ld a,(CondDelim)
		call CondEval
		call CondElseIfSet
		ld a,(CondDelim)
		ld b,0
		ret
ELIF1		ld a,(CondDelim)
		call CondSkipExpr
		ld (CondDelim),a
		xor a
		call CondElseIfSet
		ld a,(CondDelim)
		ld b,0
		ret
_else		call CondEndOnly
		ld (CondDelim),a
		call CondDoElse
		ld a,(CondDelim)
		ld b,0
		ret
_endif		call CondEndOnly
		ld (CondDelim),a
		call CondPop
		ld a,(CondDelim)
		ld b,0
		ret
;
;DUP expr / EDUP
_dup		ld c,a
		ld a,(DupActive)
		or a
		jp nz,CondSyntax
		ld a,c
		call CondEval
		ld a,d
		or e
		jp z,CondSyntax
		ld (DupCount),de
		ld a,(CondDelim)
		call DupEndLine
		ld (CondDelim),a
		ld a,#ff
		ld (DupActive),a
		ld (DupPendingFlag),a
		ld a,(CondDelim)
		ld b,0
		ret
_edup		ld c,a
		ld a,(DupActive)
		or a
		jp z,CondSyntax
		ld a,c
		call DupEndLine
		ld (CondDelim),a
		push hl
		ld hl,(DupCount)
		dec hl
		ld (DupCount),hl
		ld a,h
		or l
		jr z,EDUP1
		ld a,#ff
		ld (DupJumpFlag),a
		ld hl,(DupStartAdr)
		ld (DupJumpAdr),hl
		ld a,(DupStartPage)
		ld (DupJumpPage),a
		ld hl,(DupStartLine)
		ld (DupJumpLine),hl
		jr EDUP2
EDUP1		xor a
		ld (DupActive),a
EDUP2		pop hl
		ld a,(CondDelim)
		ld b,0
		ret
;DISPLAY "text"
_display	ld de,DataBuf
		call OutputSpec
		ld (CondDelim),a
		ld a,(Pass)
		inc a
		jr nz,DSP1
		push hl
		call DiagPrint
		pop hl
DSP1		ld a,(CondDelim)
		ld b,0
		ret
;ERROR "text"
_error		push af
		ld a,(CondActive)
		or a
		jr nz,ERR0
		pop af
		call CondSkipExpr
		ld b,0
		ret
ERR0		pop af
		ld de,DataBuf
		call OutputSpec
		ld (CondDelim),a
		push hl
		call DiagPrint
		pop hl
		ld b,UserError+#80
		jp SkipStrC
;ASSERT expr[, "text"]
_assert		ld c,a
		xor a
		ld (CondPage2),a
		push hl
		ld a,c
		call AssertHasEqual
		pop hl
		ld a,(Pass)
		inc a
		jr z,ASRT1
		ld a,c
		call GetVar
		ld (CondDelim),a
		call AssertMsg
		jr DSP1
ASRT1		ld a,c
		call GetVar2
		ld (CondDelim),a
		ld a,d
		or e
		ld (CondValue),a
		ld a,(CondDelim)
		call AssertMsg
		ld (CondDelim),a
		ld a,(CondValue)
		or a
		jr nz,DSP1
		ld a,(CondPage2)
		or a
		jr nz,DSP1
		ld a,(CondPage3)
		or a
		jr z,ASRT2
		push hl
		call DiagPrint
		pop hl
ASRT2		ld b,AssertionEr
		jp SkipStrC
AssertMsg	xor a
		ld (CondPage3),a
		ld a,(CondDelim)
		cp #20
		call z,SkipSpace
		cp #09
		call z,SkipSpace
		cp ","
		jr z,ASMSG1
		jp CondEndOnly
ASMSG1		ld a,(hl)
		ld de,DataBuf
		call OutputSpec
		ld (CondDelim),a
		ld a,#ff
		ld (CondPage3),a
		ld a,(CondDelim)
		ret
AssertHasEqual	cp #20
		call z,SkipSpace
		cp #09
		call z,SkipSpace
AHE1		cp #0d
		ret z
		cp ","
		ret z
		cp ":"
		ret z
		cp ";"
		ret z
		cp "="
		jr z,AHE3
		cp "'"
		jr z,AHE2
		cp '"'
		jr z,AHE2
		ld a,(hl)
		inc hl
		jr AHE1
AHE2		ld b,a
AHE2A		ld a,(hl)
		inc hl
		cp #0d
		ret z
		cp b
		jr nz,AHE2A
		ld a,(hl)
		inc hl
		jr AHE1
AHE3		ld a,#ff
		ld (CondPage2),a
		ret
DiagPrint	ex de,hl
		ld b,19
DP1		ld (hl),#20
		inc hl
		djnz DP1
		ld (hl),#0a
		inc hl
		ld (hl),#0d
		inc hl
		ld (hl),0
		ld hl,DataBuf
		ld c,PChars
		jp DSS
DupEndLine	cp #20
		call z,SkipSpace
		cp #09
		call z,SkipSpace
		cp #0d
		ret z
		cp ";"
		jr nz,DELERR
DEL1		ld a,(hl)
		inc hl
		cp #0d
		jr nz,DEL1
		ret
DELERR		ld b,SyntaxEr
		jp SkipStrC
;
;Общие процедуры условной компиляции.
CondEval	cp #20
		jr z,CEV1
		cp #09
		jr nz,CondSyntax
CEV1		call SkipSpace
		call GetVar2
		ld (CondDelim),a
CondBool	ld a,d
		or e
		ret z
		ld a,#ff
		ret
CondLabelDefined cp #20
		jr z,CLD1
		cp #09
		jr nz,CondSyntax
CLD1		call SkipSpace
		call ScanLabel1
		ld (CondDelim),a
		push hl
		call SearchLabel
		pop hl
		jp m,CLD1A
		ld a,#ff
		jr CLD2
CLD1A		xor a
CLD2		ld (CondValue),a
		ld a,(CondDelim)
		call CondEndOnly
		ld (CondDelim),a
		ld a,(CondValue)
		ret
CondEndOnly	cp #20
		call z,SkipSpace
		cp #09
		call z,SkipSpace
		cp #0d
		ret z
		cp ":"
		ret z
		cp ";"
		ret z
CondSyntax	ld b,SyntaxEr
		jp SkipStrC
CondSkipExpr	cp #20
		call z,SkipSpace
		cp #09
		call z,SkipSpace
CSE1		cp #0d
		ret z
		cp ":"
		ret z
		cp ";"
		ret z
		cp "'"
		jr z,CSE2
		cp '"'
		jr z,CSE2
		ld a,(hl)
		inc hl
		jr CSE1
CSE2		ld c,a
CSE3		ld a,(hl)
		inc hl
		cp #0d
		ret z
		cp c
		jr nz,CSE3
		ld a,(hl)
		inc hl
		jr CSE1
CondPushInactive xor a
CondPushA	push hl
		push bc
		push de
		ld c,a
		ld a,(CondDepth)
		cp MaxCond
		jr nc,CondStackErr
		ld e,a
		ld d,0
		inc a
		ld (CondDepth),a
		ld hl,CondParent
		add hl,de
		ld a,(CondActive)
		ld (hl),a
		ld a,c
		or a
		jr z,CPA1
		ld a,#ff
CPA1		ld hl,CondSeen
		add hl,de
		ld (hl),a
		ld a,(CondActive)
		or a
		jr z,CPA2
		ld a,c
		or a
		jr z,CPA2
		ld a,#ff
		jr CPA3
CPA2		xor a
CPA3		ld hl,CondAct
		add hl,de
		ld (hl),a
		ld (CondActive),a
		pop de
		pop bc
		pop hl
		ret
CondStackErr	pop de
		pop bc
		pop hl
		ld b,SyntaxEr
		jp SkipStrC
CondNewLabel	exx
		push bc
		push de
		push hl
		exx
		ex af,af' ;'
		push af
		ex af,af' ;'
		call NL6
		ex af,af' ;'
		pop af
		ex af,af' ;'
		exx
		pop hl
		pop de
		pop bc
		exx
		ret
DeleteLabel	push hl
		in a,(Page2)
		ld (CondPage2),a
		in a,(Page3)
		ld (CondPage3),a
		ld a,(MapLabelID)
		ld b,0
		ld c,a
		push bc
		ld c,SetWin2
		call DSS
		pop bc
		ld a,c
		inc b
		ld c,SetWin3
		call DSS
		ld hl,TabLabel
DLF1		ld a,(hl)
		dec a
		jp m,DL6
		push hl
		ld b,a
		inc b
		dec a
		dec a
		ld c,a
		inc hl
		ld de,WordBuf
DLF2		push bc
		ld b,(hl)
		res 7,b
		ld a,(CapsLabel)
		inc a
		ld a,(de)
		res 7,a
		jr nz,DLF3
		ld c,a
		ld a,b
		call CapsLetter
		ld b,a
		ld a,c
		call CapsLetter
DLF3		cp b
		pop bc
		jr nz,DLF5
		inc de
		inc hl
		dec c
		jr nz,DLF2
		ld a,(de)
		or a
		jr z,DLF4
DLF5		pop hl
		ld c,b
		ld b,0
		add hl,bc
		jr DLF1
DLF4		pop hl
		ld a,(hl)
		ld e,a
		ld d,0
		push hl
		add hl,de
		push hl
DLD1		ld a,(hl)
		or a
		jr z,DLD2
		ld e,a
		ld d,0
		add hl,de
		jr DLD1
DLD2		inc hl
		pop de
		or a
		sbc hl,de
		ld b,h
		ld c,l
		pop hl
		ex de,hl
		ldir
DL6		ld a,(CondPage2)
		out (Page2),a
		ld a,(CondPage3)
		out (Page3),a
		pop hl
		ret
CondNeedTop	ld a,(CondDepth)
		or a
		jp z,CondSyntax
		dec a
		ld e,a
		ld d,0
		ret
CondElseIfNeed	push hl
		push bc
		push de
		call CondNeedTop
		ld hl,CondParent
		add hl,de
		ld a,(hl)
		or a
		jr z,CEIN0
		ld hl,CondSeen
		add hl,de
		ld a,(hl)
		or a
		jr nz,CEIN0
		dec a
		jr CEIN1
CEIN0		xor a
CEIN1		pop de
		pop bc
		pop hl
		ret
CondElseIfSet	push hl
		push bc
		push de
		ld c,a
		call CondNeedTop
		ld a,c
		or a
		jr z,CEIS0
		ld hl,CondSeen
		add hl,de
		ld a,#ff
		ld (hl),a
		ld hl,CondAct
		add hl,de
		ld (hl),a
		ld (CondActive),a
		jr CEIS1
CEIS0		ld hl,CondAct
		add hl,de
		xor a
		ld (hl),a
		ld (CondActive),a
CEIS1		pop de
		pop bc
		pop hl
		ret
CondDoElse	push hl
		push bc
		push de
		call CondNeedTop
		ld hl,CondParent
		add hl,de
		ld a,(hl)
		or a
		jr z,CDE0
		ld hl,CondSeen
		add hl,de
		ld a,(hl)
		or a
		jr nz,CDE0
		dec a
		ld (hl),a
		ld hl,CondAct
		add hl,de
		ld (hl),a
		ld (CondActive),a
		jr CDE1
CDE0		ld hl,CondSeen
		add hl,de
		ld a,#ff
		ld (hl),a
		ld hl,CondAct
		add hl,de
		xor a
		ld (hl),a
		ld (CondActive),a
CDE1		pop de
		pop bc
		pop hl
		ret
CondPop	push hl
		push bc
		push de
		ld a,(CondDepth)
		or a
		jp z,CondStackErr
		dec a
		ld (CondDepth),a
		jr z,CPOP1
		dec a
		ld e,a
		ld d,0
		ld hl,CondAct
		add hl,de
		ld a,(hl)
		jr CPOP2
CPOP1		dec a
CPOP2		ld (CondActive),a
		pop de
		pop bc
		pop hl
		ret
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
;DD/DEFD ...
_dd1		ld a,(hl)
		inc hl
_dd		cp " "		;пропуск начальных пробелов
		call z,SkipSpace
		cp #09		;и табуляции
		call z,SkipSpace

		push de
		call GetVar
		ex af,af' ;'
		ld c,d
		ld a,e		;младшее слово после калькулятора
		pop de
		call _ddput
		ld a,c
		call _ddput
		xor a		;старшее слово равно 0 для 16-битных выражений
		call _ddput
		xor a
		call _ddput
		ex af,af' ;'
_ddend		cp " "
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
		jp z,_dd1
		ld b,SyntaxEr	;"Синтаксическая ошибка"
		jp SkipStrC

_ddput		ld (de),a
		inc de
		inc b
		ret nz
		ld b,DBInstrEr	;"В DB, DW болше 255 байт"
		jp SkipStrC
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
;SAVE/SAVEBIN "file",start,size
_savebin	call SpecFile
		cp #2C
		jp nz,SkipStrC
		ld a,(hl)
		inc hl
		call GetVar
		ld (SaveStartTmp),de
		cp #20
		call z,SkipSpace
		cp #09
		call z,SkipSpace
		cp #2C
		jp nz,SkipStrC
		ld a,(hl)
		inc hl
		call GetVar
		ld (SaveLenTmp),de
		cp #20
		call z,SkipSpace
		cp #09
		call z,SkipSpace
		cp #0D
		jr z,SVB1
		cp ":"
		jr z,SVB1
		cp ";"
		jp nz,SkipStrC
SVB1		ld c,a
		ld a,(Pass)
		inc a
		jr nz,SVB5
		ld a,(SaveReqCount)
		cp MaxSaveReq
		jr c,SVB2
		ld a,c
		ld b,SyntaxEr
		jp SkipStrC
SVB2		inc a
		ld (SaveReqCount),a
		push hl
		ld hl,(SaveReqPtr)
		push hl
		ld de,(SaveStartTmp)
		ld (hl),e
		inc hl
		ld (hl),d
		inc hl
		ld de,(SaveLenTmp)
		ld (hl),e
		inc hl
		ld (hl),d
		inc hl
		ld de,DataBuf
		ld b,SaveReqNameLen
SVB3		ld a,(de)
		ld (hl),a
		inc hl
		inc de
		or a
		jr z,SVB4
		djnz SVB3
		dec hl
		xor a
		ld (hl),a
SVB4		pop hl
		ld de,SaveReqSize
		add hl,de
		ld (SaveReqPtr),hl
		pop hl
SVB5		ld a,c
		ld b,0
		ret
;OUTPUT "file" / OUTEND
_output		ld de,DataBuf
		call OutputSpec
		ld (CondDelim),a
		ld a,(OutputActive)
		or a
		jp nz,CondSyntax
		push hl
		ld hl,(PCAddres)
		ld (OutputStart),hl
		ld a,#ff
		ld (OutputActive),a
		ld a,(Pass)
		inc a
		jr nz,OUT4
		ld a,(SaveReqCount)
		cp MaxSaveReq
		jr c,OUT1
		pop hl
		ld a,(CondDelim)
		ld b,SyntaxEr
		jp SkipStrC
OUT1		ld hl,(SaveReqPtr)
		ld (OutputReqPtr),hl
		ld de,(OutputStart)
		ld (hl),e
		inc hl
		ld (hl),d
		inc hl
		ld (OutputReqLenPtr),hl
		xor a
		ld (hl),a
		inc hl
		ld (hl),a
		inc hl
		ld de,DataBuf
		ld b,SaveReqNameLen
OUT2		ld a,(de)
		ld (hl),a
		inc hl
		inc de
		or a
		jr z,OUT3
		djnz OUT2
		dec hl
		xor a
		ld (hl),a
OUT3
OUT4		pop hl
		ld a,(CondDelim)
		ld b,0
		ret
_outend	call CondEndOnly
		ld (CondDelim),a
		ld a,(OutputActive)
		or a
		jp z,CondSyntax
		push hl
		ld hl,(PCAddres)
		ld de,(OutputStart)
		or a
		sbc hl,de
		ld a,(Pass)
		inc a
		jr nz,OUTE1
		ld de,(OutputReqLenPtr)
		ex de,hl
		ld (hl),e
		inc hl
		ld (hl),d
		ld a,(SaveReqCount)
		inc a
		ld (SaveReqCount),a
		ld hl,(OutputReqPtr)
		ld de,SaveReqSize
		add hl,de
		ld (SaveReqPtr),hl
OUTE1		xor a
		ld (OutputActive),a
		pop hl
		ld a,(CondDelim)
		ld b,0
		ret
OutputSpec	call SkipSpace
		ld b,SyntaxEr
		ld c,a
		cp "'"
		jr z,OSPC1
		cp '"'
		jp nz,SkipStrC
OSPC1		ld a,(hl)
		inc hl
		cp #20
		jp c,SkipStrC
		ld (de),a
		inc de
		cp c
		jr nz,OSPC1
		ld a,(hl)
		inc hl
		cp #20
		call z,SkipSpace
		cp #09
		call z,SkipSpace
		ld c,a
		cp #0d
		jr z,OSPC2
		cp ":"
		jr z,OSPC2
		cp ";"
		jp nz,SkipStrC
OSPC2		dec de
		xor a
		ld (de),a
		ld a,c
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
