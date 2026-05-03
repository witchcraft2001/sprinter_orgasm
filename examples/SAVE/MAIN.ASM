        org #4000

Start:  byte #3E,#2A        ; ld a,#2a
        byte #32
        word Value
        block 4,#00
Value:  byte #00
Last:

        savebin "CODE.BIN",#4000,Last-#4000
        save "COPY.BIN",#4000,Last-#4000
