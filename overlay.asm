;-----------------------------------------------------------------------------
; Cold win2 overlay routines.
;-----------------------------------------------------------------------------

OverlayStart

OverlayMemInfoFree
                ld c,InfoMem    ;информация о памяти
                rst #10

                ld h,b
                ld l,c
                ld de,VarFMem
                call CalcMem

                ld hl,FreeMem1
                ld c,PChars
                rst #10         ;печать сообщения
                ret

OverlayMemInfoTotal
                ld c,InfoMem    ;информация о памяти
                rst #10

                ld de,VarTMem
                call CalcMem

                ld hl,TotalMem
                ld c,PChars
                rst #10         ;печать сообщения
                ret

OverlayExitDSS
;                ld a,(PageW2)
;                out (#c2),a
;                ld sp,#bfff
                call CloseErrLog
                ld a,(OpenFile) ;проверка, есть ли не закрытый файл
                or a
                jr z,OverlayEDSS1

                ld a,(OpenFile) ;закрываем открытый файл
                ld c,Close
                rst #10

OverlayEDSS1
                ld hl,InFileID
                ld b,4
OverlayFrMem2   ld c,(hl)
                inc hl
                ld a,(hl)
                inc hl
                or a
                jr z,OverlayFrMem1
                push hl
                push bc
                ld a,c
                ld c,FreeMem
                rst #10         ;освобождение блока памяти
                jp c,Error

                pop bc
                pop hl
OverlayFrMem1   djnz OverlayFrMem2

                ld hl,(ErrorPass)
                ld a,h
                or l
                ld b,0
                jr z,OverlayEDSS3
                inc b
OverlayEDSS3    ld c,Exit       ;выход из программы
                rst #10
                ret

OverlayErrorDSS1
                ld hl,1
                ld (ErrorPass),hl
                ld hl,ErrorPort
                ld c,PChars
                rst #10
                jp OverlayExitDSS

OverlayError
                push af
                ld hl,1
                ld (ErrorPass),hl
                pop af
                cp #21
                jr c,OverlayError0 ;код ошибки < 20h ?
                ld a,#20
OverlayError0
                add a,a
                ld hl,OverlayErrorTabl
                ld d,0
                ld e,a
                add hl,de
                ld a,(hl)
                inc hl
                ld h,(hl)
                ld l,a

                ld c,PChars     ;вывод сообщения об ошибке
                rst #10
                jp OverlayExitDSS

Overlay_c0      db "O'Key!",13,10,0
Overlay_c1      db "Invalid function",0
Overlay_c2      db "Invalid drive number",0
Overlay_c3      db "File not found",0
Overlay_c4      db "Path not found",0
Overlay_c5      db "Invalid handle",0
Overlay_c6      db "Too many open files",0
Overlay_c7      db "File exist",0
Overlay_c8      db "File read only",0
Overlay_c9      db "Root overflow",0
Overlay_ca      db "No free space",0
Overlay_cb      db "Directory not empty",0
Overlay_cc      db "Attempt to remove current directory",0
Overlay_cd      db "Invalid media",0
Overlay_ce      db "Invalid operation",0
Overlay_cf      db "Directory exist",0
Overlay_c10     db "Invalid filename",0
Overlay_c11     db "Invalid EXE-file",0
Overlay_c12     db "Not supported EXE-file",0
Overlay_c13     db "Permission denied",0
Overlay_c14     db "Not ready",0
Overlay_c15     db "Seek error",0
Overlay_c16     db "Sector not found",0
Overlay_c17     db "CRC error",0
Overlay_c18     db "Write protect",0
Overlay_c19     db "Read error",0
Overlay_c1a     db "Write error",0
Overlay_c1b     db "Drive failure",0
Overlay_c1c     db "Unknown error : 28",0
Overlay_c1d     db "Unknown error : 29",0
Overlay_c1e     db "No free memory",0
Overlay_c1f     db "Invalid memory block",0
Overlay_c20     db "Unknown error : 32...",0
OverlayErrorTabl
                dw Overlay_c0,Overlay_c1,Overlay_c2,Overlay_c3
                dw Overlay_c4,Overlay_c5,Overlay_c6,Overlay_c7
                dw Overlay_c8,Overlay_c9,Overlay_ca,Overlay_cb
                dw Overlay_cc,Overlay_cd,Overlay_ce,Overlay_cf
                dw Overlay_c10,Overlay_c11,Overlay_c12,Overlay_c13
                dw Overlay_c14,Overlay_c15,Overlay_c16,Overlay_c17
                dw Overlay_c18,Overlay_c19,Overlay_c1a,Overlay_c1b
                dw Overlay_c1c,Overlay_c1d,Overlay_c1e,Overlay_c1f
                dw Overlay_c20

OverlayEnd
                ifdef ORGASM_HOST_BUILD
                savebin "out/overlay.bin",OverlayStart,OverlayEnd-OverlayStart
                endif
