; This example intentionally contains compiler errors.
; Build it to verify /L creates ERRORS.ERR.

DSS     equ #10
PChars  equ #5c

	        org #8100
	        entry Start
	        stack #bfff
	        error "Explicit diagnostic error"

Start   ld hl,Message
        ld a,(MissingLabel)
        db (1+2
1BAD    db 0
        jr VeryFarLabel
        call UnknownProc

Message db "This file must not compile",13,10,0

        ds 200
VeryFarLabel
        ret
