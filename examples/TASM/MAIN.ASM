        org #6200

Start:  byte #01

        disp #7000
Virt:   byte #02
        ent

        word Virt
        dd #5678
        defd Virt
        dword #1234
        byte %0100'0000
        dup 3
        byte #11
        edup

End:
        savebin "TASM.BIN",#6200,End-#6200
