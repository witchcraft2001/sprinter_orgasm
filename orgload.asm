; OrgAsm EXE loader.
;
; The loader keeps help/startup text out of the resident assembler body.
; Packed mode allocates win1 for the OrgAsm core, reads the appended Hrust
; stream into win2, unpacks the core to #4100, copies the DSS command line to
; #4000, and jumps there. Unpacked mode reads the appended raw core directly to
; #4100 in the allocated win1 page and jumps there.

CoreStart       equ #4100
CoreCommandLine equ #4000
LoaderLoad      equ #8200
LoaderStart     equ #8280
PayloadBuffer   equ #8600
LoaderStack     equ #bfff
ExeHeaderSize   equ 22

Create          equ #0a
Open            equ #11
Close           equ #12
Read_           equ #13
SetWin1         equ #39
GetMem          equ #3d
Exit            equ #41
PChars          equ #5c

                org LoaderLoad-ExeHeaderSize

ExeHeader       db "EXE"
                db #01
                dw LoaderLoad-ExeHeader
                dw #0000
                dw LoaderImageSize
                dw #0000
                dw #0000
                dw #0000
                dw LoaderLoad
                dw LoaderStart
                dw LoaderStack
                assert $ == ExeHeader+ExeHeaderSize

                org LoaderLoad
                ds LoaderStart-$

                org LoaderStart

LoaderEntry
                ld (LoaderIX),ix
                ld a,(ix-#03)
                ld (FileHandle),a

                ld hl,Hello
                ld c,PChars
                rst #10

                ld ix,(LoaderIX)
                ld a,(ix+0)
                or a
                jr nz,HaveParams

                ld hl,Help
                ld c,PChars
                rst #10
                ld b,0
                ld c,Exit
                rst #10

HaveParams      ld b,1
                ld c,GetMem
                rst #10
                jr c,LoaderError

                ld b,0
                ld c,SetWin1
                rst #10
                jr c,LoaderError

                push ix
                pop hl
                ld de,CoreCommandLine
                ld b,(hl)
                inc b
CopyCmdLine     ld a,(hl)
                ld (de),a
                inc hl
                inc de
                djnz CopyCmdLine
                xor a
                ld (de),a

                ifdef ORGASM_UNPACKED
                ld hl,CoreStart
                else
                ld hl,PayloadBuffer
                endif
                ld de,PayloadSize
                ld a,(FileHandle)
                ld c,Read_
                rst #10
                jr c,LoaderError

                ld a,(FileHandle)
                ld c,Close
                rst #10
                jr c,LoaderError

                ifdef ORGASM_UNPACKED
                jp CoreStart
                else
                ld hl,PayloadBuffer
                ld de,CoreStart
                call DePACK
                endif

                jp CoreStart

LoaderError     ld hl,LoadError
                ld c,PChars
                rst #10
                ld b,1
                ld c,Exit
                rst #10

                ifndef ORGASM_UNPACKED
DePACK          include "depack.asm"
                endif

FileHandle      db 0
LoaderIX        dw 0

Hello           db 13,10
                db "OrgAsm v0.29",13,10,0
Help            db "by Igor Zhadinets <Alpha Studio> and Dmitry Mikhalchenkov",13,10,10
                db 'OrgAsm [drv:\path\]inFile[.ext] [drv:\path\outFile.ext] [/options]',13,10,10
                db '/E - create EXE-prefix  ',13,10
                db '/C - upper Case significant in symbols',13,10
                db '/L[:file] - create Error log on errors',13,10
                db '/M - create Symbol table   ',13,10
                db '/N - no implicit output file',13,10
                db '/S - clear Screen',13,10,0
LoadError       db 13,10,"Loader error",13,10,0

LoaderEnd
LoaderSize      equ LoaderEnd-LoaderEntry
LoaderImageSize equ LoaderEnd-LoaderLoad
                assert LoaderEnd <= PayloadBuffer

PayloadStart
                ifdef ORGASM_UNPACKED
                incbin "out/core.bin"
                else
                incbin "out/core.hst"
                endif
PayloadEnd
PayloadSize     equ PayloadEnd-PayloadStart

                ifndef ORGASM_UNPACKED
                assert PayloadSize <= #c000-PayloadBuffer
                endif
