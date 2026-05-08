; Test of sjasmplus-style command-line defines: -DNAME[=value] / /DNAME[=value]
;
; Build runs four scenarios via build.bat — see expected output there.

        org #4100

        ifdef FOO
        display "FOO=", FOO
        else
        display "FOO undef"
        endif

        ifdef BAR
        display "BAR=", BAR
        else
        display "BAR undef"
        endif

        ifdef BAZ
        display "BAZ=", BAZ
        else
        display "BAZ undef"
        endif

End:
        savebin "CMDDEF.BIN",#4100,End-#4100
