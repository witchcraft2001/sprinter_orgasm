        org #6000

        define BUILD 1

        ifdef BUILD
Start:  byte #3e,#42
        else
Skipped bad source line
        endif

        ifn 0
        byte #32
        word Value
        endif

        if 0
Broken: db ?
        elseif BUILD
Value:  byte #24
        else
Other:  byte #00
        endif

        ifndef MISSING
        block 2,#55
        endif

        define TEMP 1
        undefine TEMP
        ifndef TEMP
        byte #11
        endif

        ifndef ONEDEF : define ONEDEF 1 : endif
        ifdef ONEDEF : byte #22 : endif

        if 0
        if 1
Nested bad source line
        endif
        else
        byte #33
        endif

        ifdef ONEDEF : byte #44 : endif

        ifndef NEWFLAG : define NEWFLAG 7 : endif
        ifdef NEWFLAG : byte NEWFLAG : endif

End:
        savebin "COND.BIN",#6000,End-#6000
