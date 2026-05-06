;-----------------------------------------------------------------------------
;--			     Разбор мнемоник Z80			    --
;-----------------------------------------------------------------------------
;
;JR ...
_jr		inc h
		jr z,_jr1	;2-ой операнд выражение
		dec h
		jp nz,CmndError
		inc l
		jp nz,CmndError
		ld a,1
		ld (RelExprIndex),a
		ld a,#18	;JR NN
		jr _jr2+1

_jr1		ld a,2
		ld (RelExprIndex),a
		ld a,l
		ld hl,Tbl_jr
		cp #03		;JR C,NN
		jr z,_jr2
		inc hl
		cp #0c		;JR Z,NN
		jr z,_jr2
		inc hl
		cp #14		;JR NZ,NN
		jr z,_jr2
		inc hl
		cp #16		;JR NC,NN
		jp nz,CmndError

_jr2		ld a,(hl)	;код команды
		ld (de),a
		call _jrdjnz
		inc de
		ld b,#02	;длина obj-кода команды
		ld (de),a
		ret
;DJNZ ...
_djnz		inc h		;2-ой операнд <>0   - ошибка
		dec h
		jp nz,CmndError
		inc l		;1-ый операнд - выражение?
		jp nz,CmndError
		ld a,1
		ld (RelExprIndex),a
		ld a,#10	;код команды DJNZ
		jr _jr2+1
		   
_jrdjnz		ld a,(Pass)	;диапазон JR/DJNZ проверяем только
		inc a		;на втором проходе, когда метки стабильны
		jr z,_jrdjnz1
		xor a
		ret
_jrdjnz1	ld a,(RelExprIndex)
		cp 2
		jr z,_jrdjnzOp2
		ld a,(PCExpr1First)
		cp "$"
		jr nz,_jrdjnz2
		ld hl,(PCExpr1Adr)
		call _jrdollar
		jr _jrdjnz3
_jrdjnzOp2	ld a,(PCExpr2First)
		cp "$"
		jr nz,_jrdjnz2
		ld hl,(PCExpr2Adr)
		call _jrdollar
		jr _jrdjnz3
_jrdjnz2	ld hl,(Var1)	;значение переменной
		ld bc,(PCAddres);текущее значение счетчика
		inc bc
		inc bc
		or a
		sbc hl,bc
_jrdjnz3
		ld a,h
		or a
		jr nz,JumpDown	;отрицательное число?
		ld a,l
		cp #80		;0...#7f
		jr nc,JumpError
		ret
JumpDown	inc a
		jr nz,JumpError
		ld a,l
		cp #80		;#80...#ff
		ret nc

JumpError	exx
		ld a,b		;следующий символ в строке
		ld b,JumpEr	;"Слишком длинный относительный переход"
		jp SkipStrC

_jrdollar	inc hl
		ld a,(hl)
		cp #20
		jr z,_jrdollar0
		cp #09
		jr z,_jrdollar0
		cp #0d
		jr z,_jrdollar0
		cp ":"
		jr z,_jrdollar0
		cp ";"
		jr z,_jrdollar0
		cp ","
		jr z,_jrdollar0
		ld c,0
		cp "+"
		jr z,_jrdollar2
		dec c
		cp "-"
		jr z,_jrdollar2
		dec hl
		ld hl,(Var1)
		ld de,(PCAddres)
		or a
		sbc hl,de
		jr _jrdollar1
_jrdollar2	inc hl
		push bc
		call _jrnum
		ex de,hl
		pop bc
		ld a,c
		or a
		jr z,_jrdollar1
		ld de,0
		ex de,hl
		or a
		sbc hl,de
		jr _jrdollar1
_jrdollar0	ld hl,0
_jrdollar1	ld de,-2
		add hl,de
		ret

_jrnum		ld de,0
_jrnum1	ld a,(hl)
		call Numeric
		ret nc
		sub "0"
		push hl
		push af
		ex de,hl
		add hl,hl
		ld d,h
		ld e,l
		add hl,hl
		add hl,hl
		add hl,de
		pop af
		ld e,a
		ld d,0
		add hl,de
		ex de,hl
		pop hl
		inc hl
		jr _jrnum1

;XOR ...
_xor		ld c,#a8	;коррекция кода
		jp Logic
;SUB ...
_sub		ld c,#90	;коррекция кода
		jp Logic
;SBC ...
_sbc		ld a,l
		ld c,#98	;коррекция кода
		cp #01		;рег A
		jp z,_adc1
		ld c,#42	;коррекция кода
		cp #11		;рег HL
		jp z,_adc5
		jp CmndError
;OR ...
_or		ld c,#b0	;коррекция кода
		jp Logic
;CP ...
_cp		ld c,#b8	;коррекция кода
		jp Logic
;AND ...
_and		ld c,#a0	;коррекция кода
		jp Logic
;ADD ...
_add		ld a,l
		ld c,#80	;коррекция кода
		cp #01		;рег A
		jr z,_adc1
		ld c,#09	;коррекция кода
		push hl
		ld hl,OneCode
		ld (_adc3+1),hl
		pop hl
		cp #11		;ADD HL,..
		jr z,_adc4
		cp #17		;ADD IX,..
		jr z,_add1
		cp #1a		;ADD IY,..
		jp nz,CmndError
		push hl
		ld hl,PrFD_OneCode
		ld (_adc3+1),hl
		pop hl
		jr _add2
_add1		push hl
		ld hl,PrDD_OneCode
		ld (_adc3+1),hl
		pop hl
_add2		ld a,h
		cp #11		;ADD IX/IY,HL
		jp z,CmndError
		cp l		;ADD IX/IY,IX/IY
		jr nz,_adc4
		ld h,#11
		jr _adc4
;ADC ...
_adc		ld a,l
		ld c,#88	;коррекция кода
		cp #01		;ADC A,..
		jr z,_adc1
		ld c,#4a	;коррекция кода
		cp #11		;ADC HL,..
		jp nz,CmndError

_adc5		push hl
		ld hl,PrED_OneCode
		ld (_adc3+1),hl
		pop hl
_adc4		ld a,h
		ld hl,Tbl_adc+2
		cp #0f		;ADC HL,BC/DE/HL/SP
		jp c,CmndError
		cp #13
		jp nc,CmndError
		sub #0f
		push de
		ld d,0
		ld e,a
		add hl,de
		pop de
_adc3		jp PrED_OneCode

Logic		ld a,h
		or a
		jp nz,CmndError
		ld h,l
_adc1		ld a,h		;проверка 2-го операнда
		or a
		jp z,CmndError
		ld hl,Tbl_bit
		cp #08		;ADC A,A/B/C/D/E/H/L
		jr nc,_adc2
		push de
		ld d,0
		ld e,a
		add hl,de
		pop de
		jp OneCode

_adc2		ld hl,Tbl_bit+6
		cp #18		;ADC A,HX
		jp z,PrDD_OneCode
		cp #1b		;ADC A,HY
		jp z,PrFD_OneCode
		inc hl
		cp #19		;ADC A,LX
		jp z,PrDD_OneCode
		cp #1c		;ADC A,LY
		jp z,PrFD_OneCode
		inc hl
		sub #20		;ADC A,(HL)
		jp z,OneCode
		dec a		;ADC A,(IX)
		jp z,PrDD_RegS
		dec a		;ADC A,(IX+N)
		jp z,PrDD_RegS
		dec a		;ADC A,(IY)
		jp z,PrFD_RegS
		dec a		;ADC A,(IY+N)
		jp z,PrFD_RegS
		inc hl
		cp #ff-#24	;ADC A,N
		jp z,RegN
		jp CmndError
;RL ...
_rl		ld c,#10	;коррекция кода
		jr Rotation
;RLC ...
_rlc		ld c,#00	;коррекция кода
		jr Rotation
;RR ...
_rr		ld c,#18	;коррекция кода
		jr Rotation
;RRC ...
_rrc		ld c,#08	;коррекция кода
		jr Rotation
;SLA ...
_sla		ld c,#20	;коррекция кода
		jr Rotation
;SLL ...
_sll		ld c,#30	;коррекция кода
		jr Rotation
;SRA ...
_sra		ld c,#28	;коррекция кода
		jr Rotation
;SRL ...
_srl		ld c,#38	;коррекция кода
		jr Rotation
;SET ...
_set		ld c,#c0-#08	;корректировка кода
		jr BitResSet
;RES ...
_res		ld c,#80-#08	;корректировка кода
		jr BitResSet
;BIT ...
_bit		ld c,#40-#08	;корректировка кода
BitResSet	ld a,l
		inc a
		jp nz,CmndError ;ошибка, если не выражение
		ld a,(Var1)
		and #07		;обнуляем старшие 5 битов
		ld l,a
		inc l
		xor a
		add a,#08
		dec l
		jr nz,$-3
		add a,c
		ld c,a
		jr _bit1

Rotation	ld a,h
		or a
		jp nz,CmndError
		ld h,l
_bit1		ld a,h
		or a
		jp z,CmndError
		ld a,#cb	;префикс
		ld (de),a
		inc de
		inc b
		ld a,h		;проверка 2-го операнда
		ld hl,Tbl_bit
		cp #08		;рег A/B/C/D/E/H/L
		jp nc,_bit2
		push de
		ld d,0
		ld e,a
		add hl,de
		pop de
		jp OneCode

_bit2		sub #20		;рег (HL)
		jp z,OneCode
		dec a		;рег (IX)
		jr z,PrDD_Bit
		dec a		;рег (IX+N)
		jr z,PrDD_Bit
		dec a		;рег (IY)
		jr z,PrFD_Bit
		dec a		;рег (IY+N)
		jp nz,CmndError

PrFD_Bit	ld a,#fd
		jr $+4
PrDD_Bit	ld a,#dd
		dec de
		ld (de),a	;префикс индексных регистров
		inc de
		inc b
		ld a,#cb	;префикс команды
		ld (de),a
		inc de
		ld a,(Var2)
		ld (de),a	;смещение
		inc de
		inc b
		ld a,(hl)
		add a,c
		ld (de),a
		ret
;RET ...
_ret		ld a,h
		or a
		jp nz,CmndError
		ld c,#c0
		ld a,l
		or a
		jr z,_ret1
		dec b
		dec b
		jr _call1
_ret1		ld a,#c9	;RET
		ld (de),a
		ret
;JP ...
_jp		ld c,#c2	;коррекция кода
		ld a,l
		inc h
		jr z,_call1
		dec h
		jp nz,CmndError
		ld hl,Tbl_jp
		inc a		;JP NN
		jp z,RegNN
		inc hl
		sub #20+#01	;JP (HL)
		jp z,OneCode
		dec a		;JP (IX)
		jp z,PrDD_OneCode
		sub #23-#21	;JP (IY)
		jp z,PrFD_OneCode
		jp CmndError
;CALL ...
_call		ld c,#c4	;коррекция кода
		ld a,l
		inc h
		jr z,_call1
		dec h
		jp nz,CmndError
		ld hl,Tbl_call
		inc a		;CALL NN
		jp z,RegNN
		jp CmndError

_call1		ld hl,Tbl_call+1
		cp #03		;CALL C,NN
		jp z,RegNN
		inc hl
		sub #0a		;CALL M,NN
		jp z,RegNN
		inc hl
		dec a		;CALL P,NN
		jp z,RegNN
		inc hl
		dec a		;CALL Z,NN
		jp z,RegNN
		inc hl
		sub #13-#0c	;CALL PO,NN
		jp z,RegNN
		inc hl
		dec a		;CALL NZ,NN
		jp z,RegNN
		inc hl
		dec a		;CALL PE,NN
		jp z,RegNN
		inc hl
		dec a		;CALL NC,NN
		jp z,RegNN
		jp CmndError
;EX ...
_ex		ld c,h
		ld a,l
		ld hl,Tbl_in	;указатель на нулевой байт
		cp #25		;EX (SP),...
		jr z,_ex_sp_
		cp #0d		;EX AF,...
		jr z,_exaf
		cp #10		;EX DE,...
		jp nz,CmndError
		ld a,c
		ld c,#eb
		cp #11		;EX DE,HL
		jp z,OneCode
		jp CmndError

_exaf		ld a,c
		ld c,#08
		sub #0d		;EX AF,AF
		jp z,OneCode
		dec a		;EX AF,AF'
		jp z,OneCode
		jp CmndError

_ex_sp_		ld a,c
		ld c,#e3
		cp #11		;EX (SP),HL
		jp z,OneCode
		cp #17		;EX (SP),IX
		jp z,PrDD_OneCode
		cp #1A		;EX (SP),IY
		jp z,PrFD_OneCode
		jp CmndError
;INC ...
_inc		ld a,h
		or a
		jp nz,CmndError
		ld a,#03	;корректировочный байт для BC/DE/HL/IX/IY/SP
		ex af,af' ;'
		ld c,#04	;корректировочный байт для A/B/C...
		jr _dec2
;DEC ...
_dec		ld a,h
		or a
		jp nz,CmndError
		ld a,#0b	;корректировочный байт для BC/DE/HL/IX/IY/SP
		ex af,af' ;'
		ld c,#05	;корректировочный байт для A/B/C...
_dec2		ld a,l
		ld hl,Tbl_dec-1
		cp #08		;DEC A/B/C/D/E/H/L
		jr nc,_dec1
		push de
		ld d,0
		ld e,a
		add hl,de
		pop de
		jp OneCode

_dec1		ld hl,Tbl_dec+5
		cp #18		;DEC HX
		jp z,PrDD_OneCode
		cp #1b		;DEC HY
		jp z,PrFD_OneCode
		inc hl
		cp #19		;DEC LX
		jp z,PrDD_OneCode
		cp #1c		;DEC LY
		jp z,PrFD_OneCode
		inc hl
		sub #20		;DEC (HL)
		jp z,OneCode
		dec a		;DEC (IX)
		jp z,PrDD_RegS
		dec a		;DEC (IX+s)
		jp z,PrDD_RegS
		dec a		;DEC (IY)
		jp z,PrFD_RegS
		dec a		;DEC (IY+s)
		jp z,PrFD_RegS
		ex af,af' ;'
		ld c,a
		ex af,af' ;'
		inc hl
		add a,#24-#0f	;DEC BC
		jp z,OneCode
		inc hl
		dec a		;DEC DE
		jp z,OneCode
		inc hl
		dec a		;DEC HL
		jp z,OneCode
		inc hl
		dec a		;DEC SP
		jp z,OneCode
		dec hl
		cp #17-#12	;DEC IX
		jp z,PrDD_OneCode
		cp #1a-#12	;DEC IY
		jp z,PrFD_OneCode
		jp CmndError
;IM ...
_im		ld a,h
		or a
		jp nz,CmndError
		inc l
		jp nz,CmndError
		ld a,(Pass)
		or a
		jr z,_im2
		ld a,(Var1)
_im2		cp #03
		jp nc,CmndError
		inc a
		ld hl,Tbl_im-1
_im1		inc hl
		dec a		;IM 0/1/2
		jr nz,_im1
		jp PrED_OneCode
;RST ...
_rst		ld a,h
		or a
		jp nz,CmndError
		inc l
		jp nz,CmndError
		ld a,(Pass)
		or a
		jr z,_rst2
		ld a,(Var1)
_rst2		cp #39
		jp nc,CmndError
		add a,#08
		ld hl,Tbl_rst-1
_rst1		inc hl
		sub #08		   ;RST #00/#08/#10/#18/#20/#28/#30/#38
		jp c,CmndError
		jr nz,_rst1
		jp OneCode
;OUT ..
_out		ld a,l
		sub #1d		;IN ..,(C)
		jr z,_out1
		dec a		;IN ..,(BC)
		jr z,_out1
		sub #fe-#1e	;IN ..,(N)
		jp nz,CmndError
		ld c,#d3
		ld a,h
		jr _in2
_out1		ld c,#41
		ld a,h
		ld hl,Tbl_in+1
		jr _in3
;IN ..
_in		ld a,h
		sub #1d		;IN ..,(C)
		jr z,_in1
		dec a		;IN ..,(BC)
		jr z,_in1
		sub #fe-#1e	;IN ..,(N)
		jp nz,CmndError
		ld c,#db
		ld a,l
_in2		ld hl,Tbl_in
		dec a		;... A,(N)
		jp z,RegN
		jp CmndError

_in1		ld c,#40
		ld a,l
		ld hl,Tbl_in+1
		cp #20		;IN (HL),(C)/(BC)
		jp z,PrED_OneCode

_in3		cp #08		;... A/B/C/D/E/H/L,(C)/(BC)
		jp nc,CmndError
		push de
		ld d,0
		ld e,a
		add hl,de
		pop de
		jp PrED_OneCode
;PUSH ..
_push		ld c,#c5	;корректировочный байт
		jr _pop1
;POP ..
_pop		ld c,#c1	;корректировочный байт
_pop1		ld a,h
		or a
		jp nz,CmndError
		ld a,l
		ld hl,Tbl_pop
		sub #0d		;POP AF/BC/DE/HL
		jp z,OneCode
		inc hl
		sub #0f-#0d	;POP BC
		jp z,OneCode
		inc hl
		dec a		;POP DE
		jp z,OneCode
		inc hl
		dec a		;POP HL
		jp z,OneCode
		sub #17-#11	;POP IX
		jp z,PrDD_OneCode
		sub #1a-#17	;POP IY
		jp z,PrFD_OneCode
		jp CmndError
;LD ..
_ld		ld a,h
		or a
		jp z,CmndError
		ld a,l
		dec a		;LD A,..
		jp z,_lda
		cp #06-#01	;LD B/C/D/E,..
		jp c,_ldbcde
		cp #08-#01	;LD H/L,..
		jp c,_ldhl
		cp #0a-#01	;LD I/R,..
		jp c,_ldir_bc_de_
		sub #0f-#01	;LD BC,..
		jp z,_ldbc_
		dec a		;LD DE,..
		jp z,_ldde_
		dec a		;LD HL,..
		jp z,_ldhl_
		dec a		;LD SP,..
		jp z,_ldsp_
		sub #17-#12	;LD IX,..
		jp z,_ldix_
		dec a		;LD HX,..
		jp z,_ldhx
		dec a		;LD LX,..
		jp z,_ldlx
		dec a		;LD IY,..
		jp z,_ldiy_
		dec a		;LD HY,..
		jp z,_ldhy
		dec a		;LD LY,..
		jp z,_ldly
		cp #20-#1c	;LD (BC)/(DE),..
		jp c,_ldir_bc_de_
		sub #20-#1c	;LD (HL),..
		jp z,_ld_hl_
		cp #23-#20	;LD (IX)/(IX+s),..
		jp c,_ld_ix_
		cp #25-#20	;LD (IY)/(IY+s),..
		jp c,_ld_iy_
		sub #fe-#20	;LD (NN),..
		jp nz,CmndError
		ld a,h
		ld hl,Tbl_ld4
		dec a		;LD (NN),A
		jp z,RegNN
		inc hl
		sub #0f-#01	;LD (NN),BC
		jp z,PrED_RegNN
		inc hl
		dec a		;LD (NN),DE
		jp z,PrED_RegNN
		inc hl
		dec a		;LD (NN),HL
		jp z,RegNN
		cp #17-#11	;LD (NN),IX
		jp z,PrDD_RegNN
		cp #1A-#11	;LD (NN),IY
		jp z,PrFD_RegNN
		inc hl
		dec a		;LD (NN),SP
		jp z,PrED_RegNN
		jp CmndError

_lda		ld a,h
		ld hl,Tbl_ld2+9
		cp #fe		;LD A,(NN)
		jp z,RegNN
		inc hl
		cp #1e		;LD A,(BC)
		jp z,OneCode
		inc hl
		cp #1f		;LD A,(DE)
		jp z,OneCode
		inc hl
		cp #08		;LD A,I
		jp z,PrED_OneCode
		inc hl
		cp #09		;LD A,R
		jp z,PrED_OneCode
		ld c,#3e	;корректирующий байт
		jr _ldbcde3

_ldbcde		ld a,l
		ld c,#06
		sub #02		;LD B,..
		jr z,_ldbcde1
		ld c,#0e
		dec a		;LD C,..
		jr z,_ldbcde1
		ld c,#16
		dec a		;LD D,..
		jr z,_ldbcde1
		ld c,#1e	;LD E,..
_ldbcde1	ld a,h		;2-ой операнд
_ldbcde3	ld hl,Tbl_ld2
		cp #08		;LD ..,A/B/C/D/E/H/L
		jr nc,_ldbcde2
		push de
		ld d,0
		ld e,a
		add hl,de
		pop de
		jp OneCode

_ldbcde2	inc a		;LD ..,N
		jp z,RegN
		ld hl,Tbl_ld2+6
		cp #18+#01	;LD ..,HX
		jp z,PrDD_OneCode
		cp #1b+#01	;LD ..,HY
		jp z,PrFD_OneCode
		inc hl
		cp #19+#01	;LD ..,LX
		jp z,PrDD_OneCode
		cp #1c+#01	;LD ..,LY
		jp z,PrFD_OneCode
		inc hl
		sub #20+#01	;LD ..,(HL)
		jp z,OneCode
		dec a		;LD ..,(IX)
		jp z,PrDD_RegS
		dec a		;LD ..,(IX+s)
		jp z,PrDD_RegS
		dec a		;LD ..,(IY)
		jp z,PrFD_RegS
		dec a		;LD ..,(IY+s)
		jp z,PrFD_RegS
		jp CmndError

_ldhl		ld a,l
		ld c,#26
		sub #06		;LD H,..
		jr z,_ldhl1
		ld c,#2e	;LD L,..
_ldhl1		ld a,h		;2-ой операнд
		ld hl,Tbl_ld2
		cp #08		;LD ..,A/B/C/D/E/H/L
		jr nc,_ldhl2
		push de
		ld d,0
		ld e,a
		add hl,de
		pop de
		jp OneCode

_ldhl2		inc a		;LD ..,N
		jp z,RegN
		ld hl,Tbl_ld2+8
		sub #20+#01	;LD ..,(HL)
		jp z,OneCode
		dec a		;LD ..,(IX)
		jp z,PrDD_RegS
		dec a		;LD ..,(IX+s)
		jp z,PrDD_RegS
		dec a		;LD ..,(IY)
		jp z,PrFD_RegS
		dec a		;LD ..,(IY+s)
		jp z,PrFD_RegS
		jp CmndError

_ldbc_		ld c,#01
		jr _ldde_1
_ldde_		ld c,#11
_ldde_1		ld a,h
		ld hl,Tbl_ld3
		inc a		;LD ..,NN
		jp z,RegNN
		inc hl
		inc a		;LD ..,(NN)
		jp z,PrED_RegNN
		jp CmndError

_ldhl_		ld a,h
		ld hl,Tbl_ld5
		inc a		;LD HL,NN
		jp z,RegNN
		inc hl
		inc a		;LD HL,(NN)
		jp z,RegNN
		jp CmndError

_ldsp_		ld a,h
		ld hl,Tbl_ld6
		cp #11		;LD SP,HL
		jp z,OneCode
		cp #17		;LD SP,IX
		jp z,PrDD_OneCode
		cp #1a		;LD SP,IY
		jp z,PrFD_OneCode
		inc hl
		inc a		;LD SP,NN
		jp z,RegNN
		inc hl
		inc a		;LD SP,(NN)
		jp z,PrED_RegNN
		jp CmndError

_ldix_		ld a,h
		ld hl,Tbl_ld5
		inc a		;LD IX,NN
		jp z,PrDD_RegNN
		inc hl
		inc a		;LD IX,(NN)
		jp z,PrDD_RegNN
		jp CmndError

_ldhx		ld c,#26	;LD HX,..
		jr z,_ldhlx1
_ldlx		ld c,#2e	;LD LX,..
_ldhlx1		ld a,h		;2-ой операнд
		ld hl,Tbl_ld2
		cp #06		;LD ..,A/B/C/D/E
		jr nc,_ldhlx2
		push de
		ld d,0
		ld e,a
		add hl,de
		pop de
		jp PrDD_OneCode

_ldhlx2		inc a		;LD ..,N
		jp z,PrDD_RegN
		ld hl,Tbl_ld2+6
		sub #18+#01	;LD ..,HX
		jp z,PrDD_OneCode
		inc hl
		dec a		;LD ..,LX
		jp z,PrDD_OneCode
		jp CmndError

_ldiy_		ld a,h
		ld hl,Tbl_ld5
		inc a		;LD IY,NN
		jp z,PrFD_RegNN
		inc hl
		inc a		;LD IY,(NN)
		jp z,PrFD_RegNN
		jp CmndError

_ldhy		ld c,#26	;LD HY,..
		jr z,_ldhly1
_ldly		ld c,#2e	;LD LX,..
_ldhly1		ld a,h		;2-ой операнд
		ld hl,Tbl_ld2
		cp #06		;LD ..,A/B/C/D/E
		jr nc,_ldhly2
		push de
		ld d,0
		ld e,a
		add hl,de
		pop de
		jp PrFD_OneCode

_ldhly2		inc a		;LD ..,N
		jp z,PrFD_RegN
		ld hl,Tbl_ld2+6
		sub #1b+#01	;LD ..,HY
		jp z,PrFD_OneCode
		inc hl
		dec a		;LD ..,LY
		jp z,PrFD_OneCode
		jp CmndError

_ld_hl_		ld c,#36	;корректировочный байт
		ld a,h		;2-ой операнд
		ld hl,Tbl_ld2
		cp #08		;LD ..,A/B/C/D/E/H/L
		jr nc,_ld_hl_1
		push de
		ld d,0
		ld e,a
		add hl,de
		pop de
		jp OneCode

_ld_hl_1	inc a		;LD ..,N
		jp z,RegN
		jp CmndError

_ld_ix_		ld c,#36	;корректировочный байт
		ld a,h		;2-ой операнд
		ld hl,Tbl_ld2
		cp #08		;LD ..,A/B/C/D/E/H/L
		jr nc,_ld_ix_1
		push de
		ld d,0
		ld e,a
		add hl,de
		pop de
		jp PrDD_RegS

_ld_ix_1	inc a		;LD ..,N
		jp z,PrDD_RegNS
		jp CmndError

_ld_iy_		ld c,#36	;корректировочный байт
		ld a,h		;2-ой операнд
		ld hl,Tbl_ld2
		cp #08		;LD ..,A/B/C/D/E/H/L
		jr nc,_ld_iy_1
		push de
		ld d,0
		ld e,a
		add hl,de
		pop de
		jp PrFD_RegS

_ld_iy_1	inc a		;LD ..,N
		jp z,PrFD_RegNS
		jp CmndError

_ldir_bc_de_	ld a,h
		dec a
		jp nz,CmndError
		ld a,l
		ld hl,Tbl_ld1
		sub #08		;LD I,A
		jp z,PrED_OneCode
		inc hl
		dec a		;LD R,A
		jp z,PrED_OneCode
		inc hl
		sub #1e-#09	;LD (BC),A
		jp z,OneCode
		inc hl		;LD (DE),A
		jp OneCode
;
;Вычисление кодов мнемоник
;
PrED_OneCode	ld a,#ed
		jr $+8
PrDD_OneCode	ld a,#dd
		jr $+4
PrFD_OneCode	ld a,#fd
		ld (de),a
		inc de
		inc b
OneCode		ld a,(hl)
		add a,c
		ld (de),a
		ret

;PrED_RegN	 ld a,#ed
;		 jr $+8
PrDD_RegN	ld a,#dd
		jr $+4
PrFD_RegN	ld a,#fd
		ld (de),a
		inc de
		inc b
RegN		ld a,(hl)
		add a,c
		ld (de),a
		inc de
		inc b
		ld a,(Var1)
		ld (de),a
		ret

;PrED_RegS	 ld a,#ed
;		 jr $+8
PrDD_RegS	ld a,#dd
		jr $+4
PrFD_RegS	ld a,#fd
		ld (de),a
		inc de
		inc b
RegS		ld a,(hl)
		add a,c
		ld (de),a
		inc de
		inc b
		ld a,(Var2)
		ld (de),a
		ret

PrED_RegNN	ld a,#ed
		jr $+8
PrDD_RegNN	ld a,#dd
		jr $+4
PrFD_RegNN	ld a,#fd
		ld (de),a
		inc de
		inc b
RegNN		ld a,(hl)
		add a,c
		ld (de),a
		inc de
		inc b
		ld a,(Var1)
		ld (de),a
		inc de
		inc b
		ld a,(Var1+1)
		ld (de),a
		ret

;PrED_RegNS	 ld a,#ed
;		 jr $+8
PrDD_RegNS	ld a,#dd
		jr $+4
PrFD_RegNS	ld a,#fd
		ld (de),a
		inc de
		inc b
RegNS		ld a,(hl)
		add a,c
		ld (de),a
		inc de
		inc b
		ld a,(Var2)
		ld (de),a
		inc de
		inc b
		ld a,(Var1)
		ld (de),a
		ret

CmndError	exx
		ld a,b		;следующий символ в строке
		ld b,SyntaxEr	;"Синтаксическая ошибка"
		jp SkipStrC	;выход с ошибкой

Tbl_ld1		db #47,#4f,#02,#12
Tbl_ld2		db #00,#41,#3a,#3b,#3c,#3d,#3e,#3f,#40,#3a,#0a,#1a,#57,#5f
Tbl_ld3		db #00,#4a
Tbl_ld4		db #32,#43,#53,#22,#73
Tbl_ld5		db #21,#2a
Tbl_ld6		db #f9,#31,#7b
Tbl_pop		db #30,#00,#10,#20
Tbl_in		db #00,#30,#38,#00,#08,#10,#18,#20,#28
Tbl_rst		db #c7,#cf,#d7,#df,#e7,#ef,#f7,#ff
Tbl_im		db #46,#56,#5e
Tbl_dec		db #38,#00,#08,#10,#18,#20,#28,#30
		db #00,#10,#20,#30
Tbl_call	db #09,#18,#38,#30,#08,#20,#00,#28,#10
Tbl_jp		db #01,#27
Tbl_bit		db #06,#07,#00,#01,#02,#03,#04,#05
Tbl_adc		db #06,#46,#00,#10,#20,#30
Tbl_jr		db #38,#28,#20,#30
