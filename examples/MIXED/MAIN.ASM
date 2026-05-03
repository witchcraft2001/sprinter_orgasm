; Mixed include order across root and subdirectories.

DSS             equ #10
PChars          equ #5c
Exit            equ #41

                org #8100
                entry Start
                stack #bfff

Start           ld hl,Title
                ld c,PChars
                rst DSS
                ld hl,MsgA
                ld c,PChars
                rst DSS
                ld hl,MsgRoot
                ld c,PChars
                rst DSS
                ld hl,MsgB
                ld c,PChars
                rst DSS
                ld c,Exit
                rst DSS

Title           db "Mixed include order",13,10,0

                include "DIRA\A.ASM"
                include "ROOT.ASM"
                include "DIRB\B.ASM"
