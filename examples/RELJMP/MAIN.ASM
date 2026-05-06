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
                jr ForwardLabel+1
ForwardLabel    ld b,2
LoopLabel       djnz LoopLabel
RelEnd:

                assert RelEnd-Start = 22,"RELJMP size"
                savebin "RELJMP.BIN",Start,RelEnd-Start
