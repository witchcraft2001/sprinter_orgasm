; Example with an include file in a nested directory.

DSS             equ #10
PChars          equ #5c
Exit            equ #41

                org #8100
                entry Start
                stack #bfff

Start           ld hl,Text
                ld c,PChars
                rst DSS
                ld c,Exit
                rst DSS

                include "INC\TEXT.ASM"
