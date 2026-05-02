;
;Вывод на экран значения всех регистровых пар
;
Debug		ld (Debug2),sp
		ex af,af' ;'
		exx
		push hl
		push de
		push bc
		push af
		ex af,af' ;'
		exx
		push iy
		push ix
		push hl
		push de
		push bc
		push af

		push iy
		push ix
		push hl
		push de
		push bc
		push af

		pop hl
		ld de,Debug1+4
		call ExHex

		pop hl
		ld de,Debug1+16
		call ExHex

		pop hl
		ld de,Debug1+26
		call ExHex

		pop hl
		ld de,Debug1+38
		call ExHex

		pop hl
		ld de,Debug1+48
		call ExHex

		pop hl
		ld de,Debug1+60
		call ExHex

		ld hl,(Debug2)
		ld de,Debug1+70
		call ExHex

		ld hl,Debug0
		ld c,PChars
;		 rst #10
		call DSS

		ld c,WaitKey
;		 rst #10
		call DSS
		ld a,e
		cp #1b
		jp z,ExitDSS

		pop af
		pop bc
		pop de
		pop hl
		pop ix
		pop iy
		ex af,af' ;'
		exx
		pop af
		pop bc
		pop de
		pop hl
		ex af,af' ;'
		exx
		ret

ExHex		ld a,h
		or a
		rra
		rra
		rra
		rra
		and #0f
		add a,#30
		cp #3a
		jr c,$+4
		add a,7
		ld (de),a
		inc de
		ld a,h
		and #0f
		add a,#30
		cp #3a
		jr c,$+4
		add a,7
		ld (de),a
		inc de
		ld a,l
		or a
		rra
		rra
		rra
		rra
		and #0f
		add a,#30
		cp #3a
		jr c,$+4
		add a,7
		ld (de),a
		inc de
		ld a,l
		and #0f
		add a,#30
		cp #3a
		jr c,$+4
		add a,7
		ld (de),a
		ret

Debug2		dw 0
Debug0		db 13,10,"Значение регистров процессора:",13,10
		db "------------------------------",13,10
Debug1		db "AF:#",32,32,32,32,32,32,32,32,"BC:#",32,32,32,32,13,10
		db "DE:#",32,32,32,32,32,32,32,32,"HL:#",32,32,32,32,13,10
		db "IX:#",32,32,32,32,32,32,32,32,"IY:#",32,32,32,32,13,10
		db "SP:#",32,32,32,32,13,10,0


PrintParam	ld hl,ComBufer
		ld c,PChars
		rst #10
		ld hl,CRLF
		ld c,PChars
		rst #10
		ld hl,(OutFAdr)
		ld c,PChars
		rst #10
		ld hl,CRLF
		ld c,PChars
		rst #10
		ld hl,(RepFAdr)
		ld c,PChars
		rst #10
		ld hl,CRLF
		ld c,PChars
		rst #10
		ld a,(RepFile)
		or a
		jr z,$+9
		ld a,"R"
		ld c,PutChar
		rst #10
		jr $+7
		ld a,"r"
		ld c,PutChar
		rst #10
		ld a,(CapsLabel)
		or a
		jr z,$+9
		ld a,"C"
		ld c,PutChar
		rst #10
		jr $+7
		ld a,"c"
		ld c,PutChar
		rst #10
		ld a,(GlBufer)
		or a
		jr z,$+9
		ld a,"G"
		ld c,PutChar
		rst #10
		jr $+7
		ld a,"g"
		ld c,PutChar
		rst #10
		ld hl,CRLF
		ld c,PChars
		rst #10
		ret

