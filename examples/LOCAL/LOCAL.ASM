; Local label and counted loop example.

DSS             equ #10
PChars          equ #5c
Exit            equ #41

                org #8100
                entry Start
                stack #bfff

Start           ld b,3
.Again          push bc
                ld hl,Line
                ld c,PChars
                rst DSS
                pop bc
                djnz .Again
                ld c,Exit
                rst DSS

Line            db "Local label loop",13,10,0
