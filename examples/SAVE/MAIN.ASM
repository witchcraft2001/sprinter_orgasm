        org #4000

Start:  byte #3E,#2A        ; ld a,#2a
        byte #32
        word Value
        block 4,#00
Value:  byte #00
Last:

        org #8000
High:   byte #C9              ; ret
HighEnd:

        savebin "OUT\CODE.BIN",#4000,Last-#4000
        save "OUT\COPY.BIN",#4000,Last-#4000
        savebin "OUT\HIGH.BIN",High,HighEnd-High
