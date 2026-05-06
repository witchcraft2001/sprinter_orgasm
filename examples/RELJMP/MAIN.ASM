; Relative jump regression test.

                org #8100

Start           jr $+3
                nop
StorePcExpr     ld ($+5),a
AfterDollarPlus jr z,$+5
                nop
                nop
AfterCondPlus   jr $-4
BackwardLabel   nop
                jr nz,ForwardLabel
                nop
ForwardLabel    ld b,2
LoopLabel       djnz LoopLabel
End

                assert End-Start = 20,"RELJMP size"
                savebin "RELJMP.BIN",Start,End-Start
