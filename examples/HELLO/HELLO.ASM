; Simple DSS text output example.

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

Text            db "Hello from OrgAsm!",13,10,0
