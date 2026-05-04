;                  ┌╦═══╦┐              ┌╦═══╦┐
;                  │║   ║│┌╦═══╦┐┌╦═══╦┐│║   ║│┌╦═══╦┐┌╦═╦═╦┐
;                  │║   ║│├╬══╦╩┤│║  ─╦┬├╬═══╬┤└╩═══╦┐│║ ║ ║│
;                  └╩═══╩┘└╩  ╚═┘└╩═══╩┘└╩   ╩┘└╩═══╩┘└╩   ╩┘
;
; OrgAsm v0.29 is 2-pass assembler for Sprinter computer that was created
; by Igor Zhadinets in late 2002 - early 2003. Source code of historical v0.28 was
; reverse-engineered back from binary v0.28beta and based on availavle
; source code of older version 0.15 (newer source codes were lost).
; Recreation work was done by Shaos <me@shaos.net> in December 2020.
; Most actual source code for OrgAsm will be always available on GitLab:
;
; https://gitlab.com/sprinter-computer/apps/-/tree/master/OrgAsm
;
; to build use this command: zmac orgasm.asm

;Deb             equ 1           ;1 - асемблить отладочный код
                                ;0 - не асемблить

Start           equ #4200
                org #4000

                db "EXE"        ;EXE ID
                db #01          ;EXE VERSION
                dw #0200        ;CODE OFFSET LOW
                dw #0000        ;CODE OFFSET HIGH
                dw #0000        ;PRIMARY LOADER
                dw #0000        ;
                dw #0000        ;RESERVED
                dw #0000        ;
                dw Start        ;LOAD ADDRESS
                dw Start        ;START ADDRESS
                dw #bfff        ;STACK ADDRESS
                ds 490

;
;Функции DSS Estex
;
CurDisk         equ #02
ChDisk          equ #01
Create          equ #0a
Delete          equ #0e
Open            equ #11
Close           equ #12
Read_           equ #13
Write           equ #14
Move_FP         equ #15
CurDir          equ #1e
ChDir           equ #1d
SysTime         equ #21
WaitKey         equ #30
ScanKey         equ #31
SetWin          equ #38
SetWin1         equ #39
SetWin2         equ #3a
SetWin3         equ #3b
InfoMem         equ #3c
GetMem          equ #3d
FreeMem         equ #3e
SetMem          equ #3f
Exit            equ #41
GSwitch         equ #43
ExCmdLn         equ #45
Locate          equ #52
Cursor          equ #53
Clear           equ #56
WrChar          equ #58
PutChar         equ #5b
PChars          equ #5c
;
;Функции BIOS
;
LP_Print_Atr    equ #83
EMM_Fn4         equ #c4
EMM_Fn5         equ #c5
EMM_Fn6         equ #c6
;
;Номера портов
;
Page0           equ #82
Page1           equ #a2
Page2           equ #c2
Page3           equ #e2

Main
                push ix         ;адрес параметров командной строки

                ld c,SysTime
                rst #10         ;время начала компиляции
                ld (TimeComp+1),hl
                ld a,b
                ld (TimeComp),a

;                ld hl,Hello     ;приветствие программы
;                ld c,PChars
;                rst #10

                pop hl
                ld a,(hl)       ;длина параметров командной строки
                or a
                jp z,PrintHelp  ;печать краткой справки по программе

                inc hl          ;пропускаем длину параметров
                ld de,ComBuffer-1
                ld b,a
                dec b
ComStr2         inc hl
                inc de
                ld a,(hl)       ;очередной байт из ком.строки
                ld (de),a
                cp #20          ;пробел - разделитель параметров
                jr z,ComStr1
                djnz ComStr2
                inc de

ComStr1         call AddExtAsm  ;проверка наличия расширения
                xor a
                ld (de),a       ;0 - окончание первого параметра
                inc de
                ld (OutFAdr),de ;адрес имени выходного файла
                inc b
ComStr5         dec b
                jp z,ComStr4    ;больше нет параметров
                ld a,(hl)
                inc hl
                cp #20
                jr z,ComStr5    ;пропускаем пробелы

                ld ix,ComStr4
                push ix         ;на стек адрес возврата после обработки параметров
                cp "/"          ;установочные параметры
                jp z,ComStr10
                cp "-"
                jp z,ComStr10
                pop ix          ;востанавливаем стек

                dec de
                dec hl
                dec hl
ComStr6         inc hl          ;считываем имя выходного файла из ком.строки
                inc de
                ld a,(hl)       ;очередной байт из ком.строки
                ld (de),a
                cp #20          ;пробел - разделитель параметров
                jr z,ComStr7
                djnz ComStr6
                inc de

ComStr7         xor a
                ld (de),a       ;0 - окончание второго параметра
                inc de
                ld (RepFAdr),de ;адрес имени выходного файла
                inc b
ComStr8         dec b
                jp z,ComStr9    ;больше нет параметров
                ld a,(hl)
                inc hl
                cp #20
                jr z,ComStr8    ;пропускаем пробелы

                ld ix,ComStr9
                push ix         ;продолжение после обработки параметров

ComStr10        ld c,#ff
                cp "/"
                jr z,$+5
                cp "-"
                ret nz
                ld a,(hl)
                inc hl
                and #df
                cp "R"
                jr z,ComStr11
                cp "C"
                jr z,ComStr12
                cp "S" ; добавлено в v0.2X
                jp z,ComStr14
                cp "M" ; добавлено в v0.2X
                jr z,ComStr15
                cp "L"
                jr z,ComStr16
                cp "N"
                jr z,ComStr23
                cp "E"
                ret nz
                ld a,c
                ld (GlBufer),a

ComStr13        ld a,(hl)
                inc hl
                cp #20
                ret nz
                ld a,(hl)
                inc hl
                cp #20
                jr z,$-4
                jr ComStr10+2

ComStr11        ld a,c
                ld (RepFile),a
                jr ComStr13

ComStr12        ld a,c
                ld (CapsLabel),a
                jr ComStr13

ComStr15        ld a,c ; новое в v0.2X
                ld (SymFlag),a
                jr ComStr13

ComStr16        ld a,c
                ld (ErrFile),a
                ld a,(hl)
                or a
                jr z,ComStr13
                cp #20
                jr z,ComStr13
                cp ':'
                jr z,ComStr17
                cp '='
                jr nz,ComStr18
ComStr17        inc hl
                ld a,(hl)
                or a
                jr z,ComStr13
                cp #20
                jr z,ComStr13
ComStr18        ld de,ErrNameBuf
                xor a
                ld (ErrNameExt),a
ComStr19        ld a,(hl)
                or a
                jr z,ComStr21
                cp #20
                jr z,ComStr21
                cp '.'
                jr nz,ComStr20
                push af
                ld a,c
                ld (ErrNameExt),a
                pop af
ComStr20        ld (de),a
                inc de
                inc hl
                jr ComStr19
ComStr21        ld a,(ErrNameExt)
                or a
                jr nz,ComStr22
                ld a,'.'
                ld (de),a
                inc de
                ld a,'e'
                ld (de),a
                inc de
                ld a,'r'
                ld (de),a
                inc de
                ld (de),a
                inc de
ComStr22        xor a
                ld (de),a
                dec a
                ld (ErrNameFlag),a
                jr ComStr13

ComStr23        ld a,c
                ld (NoOutFlag),a
                jr ComStr13

ComStr14        push bc ; новое в v0.2X
                push hl
                ld c,Clear
                ld de,0
                ld hl,#2050
                ld b,7
                ld a,#20
                rst #10
                ld c,Locate
                ld de,#1F00
                rst #10
                pop hl
                pop bc
                jp ComStr13

ComStr4         ld hl,(OutFAdr)
                call CurSpec    ;создаем имя выходного файла
                ld a,"e"
                ld (hl),a
                inc hl
                ld a,"x"
                ld (hl),a
                inc hl
                ld a,"e"
                ld (hl),a
                inc hl
                xor a
                ld (hl),a
                inc hl
                ld (RepFAdr),hl ;адрес начала имени файла-репорта в буфере

ComStr9         ld hl,(RepFAdr) ;создаем имя файла-репорта
                call CurSpec
                ; новое в v0.2X
                ld (SomeAdr),hl
                ld a,' '
;                ld a,"r"
                ld (hl),a
                inc hl
;                ld a,"e"
                ld (hl),a
                inc hl
;                ld a,"p"
                ld (hl),a
                inc hl
                xor a
                ld (hl),a

                ld hl,Hello
                ld c,PChars
                rst #10

;                if Deb
;                call PrintParam
;                endif
;
;Определение текущей конфигурации портов и включенных страниц ОЗУ
;
                ld c,EMM_Fn6
                xor a
                rst 8           ;параметры 0-го окна
;                ld hl,PageW0
                ld a,c
                cp Page0
                jp nz,ErrorDSS1
;                ld (hl),b       ;физ.номер страницы, включенной в 0-е окно
;                inc hl
;                push hl

                ld c,EMM_Fn6
                ld a,1
                rst 8           ;параметры 1-го окна
;                pop hl
                ld a,c
                cp Page1
                jp nz,ErrorDSS1
;                ld (hl),b       ;физ.номер страницы, включенной в 1-е окно
;                inc hl
;                push hl

                ld c,EMM_Fn6
                ld a,2
                rst 8           ;параметры 2-го окна
;                pop hl
                ld a,c
                cp Page2
                jp nz,ErrorDSS1
;                ld (hl),b       ;физ.номер страницы, включенной в 2-е окно
;                inc hl
;                push hl

                ld c,EMM_Fn6
                ld a,3
                rst 8           ;параметры 3-го окна
;                pop hl
                ld a,c
                cp Page3
                jp nz,ErrorDSS1
;                ld (hl),b       ;физ.номер страницы, включенной в 3-е окно

                ld sp,#7fff
                call MemInfoTotal
                call MemInfoFree

                ld b,2          ;выделение памяти под таблицу меток
                ld c,GetMem
                rst #10
                jp c,Error
                ld b,2
                ld c,a
                ld (MapLabelID),bc
                ld b,0
                ld c,SetWin2
                rst #10
                jp c,Error
                xor a
                ld (TabLabel),a ;инициализация таблицы меток

                ld b,1          ;выделение памяти под объектный код
                ld c,GetMem
                rst #10
                jp c,Error
                ld b,1
                ld c,a
                ld (OutFileID),bc

                ld c,GetMem     ;выделение памяти под загружаемые файлы
                rst #10
                jp c,Error
                ld b,1
                ld c,a
                ld (InFileID),bc

                ld hl,Loading
                ld c,PChars
                rst #10         ;печать сообщения о загрузке
                ld hl,ComBuffer
                ld (FileNameAdr),hl
                ld a,#ff
                ld (FileNamePage),a
                ld hl,ComBuffer
                call LoadFile   ;загрузка исходника в память
;
;Основной цикл компиляции исходника
;
AsmF2           ld hl,CRLF
                ld c,PChars
                rst #10
                ld hl,PassText  ;печать сообщения о номере прохода
                ld c,PChars
                rst #10

                ld hl,0         ;инициализация переменных
                ld (NumString),hl
                ld (ErrorPass),hl
                xor a
                ld (CondDepth),a
                ld (DupActive),a
                ld (DupPendingFlag),a
                ld (DupJumpFlag),a
                dec a
                ld (CondActive),a
                ld hl,#8100
                ld (PCAddres),hl
                ld (RetAddres),sp
                ld hl,(RetAddres)
                dec hl
                dec hl
                ld (RetAddres),hl
                xor a
                ld (CurrentFile),a
                ld (SomeBuf),a ; новый буфер добавленный в v0.2X
                inc a
                ld (NumOpenFile),a
                ld hl,#8000
                xor a

NextOnPage      ld (TextPage),a ;лог.номер банки с исходником
                call SetBankAsm

AsemblFile      ld (BegString),hl
                push hl
                ld hl,(NumString)
                inc hl
                ld (NumString),hl
                ld de,Asembling+14
                call Hex2Dec    ;вычисление номера текущей строки
                ld hl,Asembling
                ld c,PChars
                rst #10         ;печать сообщения о текущей строке
                pop hl

                call ScanString ;компиляция строки
                ld a,(DupPendingFlag)
                or a
                jr z,AsmNoDupPending
                xor a
                ld (DupPendingFlag),a
                ld (DupStartAdr),hl
                ld a,(TextPage)
                ld (DupStartPage),a
                push hl
                ld hl,(NumString)
                ld (DupStartLine),hl
                pop hl
AsmNoDupPending
                ld a,(DupJumpFlag)
                or a
                jr z,AsmNoDupJump
                xor a
                ld (DupJumpFlag),a
                ld a,(DupJumpPage)
                ld (TextPage),a
                call SetBankAsm
                ld hl,(DupJumpLine)
                ld (NumString),hl
                ld hl,(DupJumpAdr)
                jp AsemblFile
AsmNoDupJump
                push af
                push hl
                ld c,ScanKey
                rst #10         ;сканирование клавиатуры
                jr z,AsmF7
                ld c,Cursor
                rst #10         ;положение курсора на экране
                ld e,25
                push de
                ld c,Locate
                rst #10         ;новые координаты курсора
                ld hl,PrPause
                ld c,PChars
                rst #10         ;печать сообщения о паузе
                ld c,WaitKey
                rst #10         ;ожидание нажатия клавиши
                cp #1b          ;нажата <Esc>?
                jp z,ExitDSS    ;принудительное завершение работы
                pop de
                ld c,Locate
                rst #10         ;текущие координаты
                ld b,50
                ld c,PutChar
AsmF8           push bc
                ld a,#20
                rst #10         ;печать пробела в текущей позиции
                pop bc
                djnz AsmF8
                ld a,#0d
                rst #10         ;в начало строки
AsmF7           pop hl
                pop af

AsmF5           ld a,(hl)
                or a
                jr z,AsmF1

                bit 6,h         ;проверка перехода адреса в 3-е окно
                jp z,AsemblFile
                res 6,h

                ld a,(TextPage)
                inc a           ;подключение очередных банок
                jp NextOnPage

AsmF1           ld a,(CurrentFile)
                call GoSpec     ;спецификация текущего файла
                ld de,#0008
                add hl,de
                ld a,(hl)       ;файл-родитель
                inc a
                jr z,AsmF4      ;нет include-файлов

                dec a
                ld (CurrentFile),a
                call GoSpec     ;спецификация файла-родителя
                push hl
                push hl
                ld hl,CRLF
                ld c,PChars
                rst #10         ;переход на новую строку
                ld hl,Continue
                ld c,PChars
                rst #10         ;печать сообщения о возврате к файлу-родителю
                pop hl
                ld de,#0008
                add hl,de
                ld a,(hl)       ;файл-родитель
                inc a
                jr z,AsmF6
                dec a
                call GoSpec     ;родитель файла-родителя
                inc hl
                inc hl
                inc hl
                ld a,(hl)       ;лог.номер банки с исходником
                call SetBankAsm
                inc hl
                ld e,(hl)
                inc hl
                ld d,(hl)
                ex de,hl        ;в hl - адрес строки со специф. файла
                ld de,DataBuf
                push de
                ld a,#20        ;код пробела
                call SpecFile   ;имя файла в буфер
                pop hl
                jr $+5
AsmF6           ld hl,ComBuffer
                call PrString   ;печать имени файла

                pop hl
                inc hl
                inc hl
                inc hl
                ld a,(hl)       ;лог.N банки, в которой был встречен include
                ld (TextPage),a
                inc hl
                call SetBankAsm ;включаем исходник-родитель
                ld e,(hl)
                inc hl
                ld d,(hl)       ;адрес строки
                inc hl
                ld c,(hl)
                inc hl
                ld b,(hl)       ;номер строки компиляции
                ld (NumString),bc
                inc hl
                ld b,(hl)
                ex de,hl        ;в hl - адрес строки со специф. файла
                ld a,#20        ;код пробела
                call SStrC2     ;пропускаем строку
                jp AsmF5

AsmF4           ld a,(PhaseFlag);вначале проверяем все флаги
                ld hl,(BegString)
                ld b,DephaseEr  ;код ошибки "Отсутствует оператор DEPHASE"
                or a
                call nz,ErrorAsm;вывод сообщения об ошибке
                ld a,(CondDepth)
                ld hl,(BegString)
                ld b,SyntaxEr
                or a
                call nz,ErrorAsm;вывод сообщения об ошибке
                ld a,(DupActive)
                ld hl,(BegString)
                ld b,SyntaxEr
                or a
                call nz,ErrorAsm;вывод сообщения об ошибке

                ld hl,(ErrorPass)
                ld a,l
                or h            ;проверка наличия ошибок
                jr z,AsmF3
                push hl
                ld hl,CRLF
                ld c,PChars
                rst #10         ;перевод строки
                pop hl
                ld de,Errors+8
                call Hex2Dec    ;кол-во ошибок
                ld hl,Errors
                ld c,PChars
                rst #10         ;печать сообщения о кол-ве ошибок
                jp ExitDSS

AsmF3           ld c,Cursor
                rst #10         ;текущие координаты
                ld e,30
                ld c,Locate
                rst #10         ;установка координат
                ld hl,c0
                ld c,PChars
                rst #10         ;печать сообщения о успешном завершении
                ld a,(Pass)
                or a
                jr nz,SaveOutF
                dec a           ;установка 2-го прохода
                ld (Pass),a
                ld a,"2"
                ld (PassText+5),a
                jp AsmF2
;
;Запись выходного файла
;Запись производится страницами по 16к через 3-е окно
;
SaveOutF        call SaveDirectiveFiles
                ld a,(NoOutFlag)
                or a
                jr nz,SOF02
                ld hl,Saving
                ld c,PChars
                rst #10         ;сообшение о записи файла
                ld hl,(OutFAdr)
                call PrString   ;печать имени файла
;                ld hl,CRLF
;                ld c,PChars
;                rst #10         ;перевод строки

                ; новое в v0.2X

                ld hl,(OutFAdr)
                call CreateSub    ;вызов подпрограммы создания файла
                ld hl,(SomeAdr)
                ld a,'l'
                ld (hl),a
                inc hl
                ld a,'a'
                ld (hl),a
                inc hl
                ld a,'b'
                ld (hl),a
                xor a
                ld (GlBufer),a
                dec a
                ld (Operand1),a
                ld hl,Scanning
                ld c,PChars
                rst #10         ;сообшение о сканировании
                call NewSub
                ld a,(OutFileID+1) ; ???
                dec a
                jr nz,SOF01
                ld de,(SaveObjAdr)
                ld a,#80
                sub d
                or e
                jr z,SOF02
SOF01           ld hl,Saving+2  ;пропускаем CRLF
                ld c,PChars
                rst #10         ;сообщение о сохранении
                ld hl,(RepFAdr)
                call PrString
                ld hl,(RepFAdr)
                call CreateSub
SOF02           ld a,(SymFlag)
                or a
                jr z,TimeCalc
                ld hl,(SomeAdr)
                ld a,'m'
                ld (hl),a
                inc hl
                ld a,'a'
                ld (hl),a
                inc hl
                ld a,'p'
                ld (hl),a
                xor a
                ld (Operand1),a
                call NewSub
                ld a,(OutFileID+1) ; ???
                dec a
                jr nz,SOF04
                ld de,(SaveObjAdr)
                ld a,#80
                sub d
                or e
                jr z,TimeCalc
SOF04           ld hl,Saving+2 ;пропускаем CRLF
                ld c,PChars
                rst #10
                ld hl,(RepFAdr)
                call PrString
                ld hl,(RepFAdr)
                call CreateSub
;
;Расчет времени компиляции
;
TimeCalc        ld c,SysTime
                rst #10         ;время оконочания компиляции
                ld a,(TimeComp) ;секунды,
                ld de,(TimeComp+1);часы и минуты начала компиляции
                ld c,a
                ld a,b
                ld b,60
                sub c
                ld c,a          ;кол-во секунд компиляции
                jr nc,TC1
                add a,b
                ld c,a          ;корректировка секунд
                ld a,l          ;и минут
                sub 1
                ld l,a
                jr nc,TC1
                add a,b
                ld l,a          ;корректировка минут
TC1             ld a,l
                sub e
                jr nc,TC2
                add a,b
TC2             push bc
                ld h,0
                ld l,a
                ld de,PrTimeComp+16 ;место для минут
                ld bc,TC3
                push bc
                push de
                inc de
                jp Hex2Dec2     ;минуты в строку
TC3             pop bc
                ld h,0
                ld l,c
                ld de,PrTimeComp+19 ;место для секунд
                ld bc,TC4
                push bc
                push de
                inc de
                jp Hex2Dec2     ;секунды в строку
TC4             ld hl,PrTimeComp
                ld c,PChars
                rst #10         ;печать сообщения о времени компиляции

                jp ExitDSS

OpenErrLog      ld a,(ErrFile)
                or a
                ret z
                ld a,(ErrOpenFile)
                or a
                ret nz
                ld a,(ErrNameFlag)
                or a
                jr z,OpenErrLog1
                ld hl,ErrNameBuf
                jr OpenErrLog2
OpenErrLog1     ld hl,(SomeAdr)
                ld a,'e'
                ld (hl),a
                inc hl
                ld a,'r'
                ld (hl),a
                inc hl
                ld (hl),a
                ld hl,(RepFAdr)
OpenErrLog2     ld a,00100000b
                ld c,Create
                rst #10
                ret c
                ld (ErrOpenFile),a
                ret

CloseErrLog     ld a,(ErrOpenFile)
                or a
                ret z
                ld c,Close
                rst #10
                xor a
                ld (ErrOpenFile),a
                ret

WriteErrLog     ld a,(ErrOpenFile)
                or a
                jr nz,WriteErrLog1
                ld a,(ErrFile)
                or a
                ret z
WriteErrLog1
                push af
                push bc
                push de
                push hl
                call OpenErrLog
                ld a,(ErrOpenFile)
                or a
                jr z,WriteErrLog2
                call ErrWriteLocation
                ld hl,(ErrMsgPtr)
                call ErrWriteZ
                ld hl,ErrCRLF
                call ErrWriteZ
                ld hl,(BegString)
                call ErrWriteLine
                ld hl,ErrCRLF
                call ErrWriteZ
WriteErrLog2
                pop hl
                pop de
                pop bc
                pop af
                ret

ErrWriteLocation
                ld hl,(NumString)
                ld de,ErrLineBuf
                call Hex2Dec
                call ErrGetFileName
                call ErrWriteZ
                ld hl,ErrColon
                call ErrWriteZ
                call ErrLineStart
                call ErrWriteZ
                ld hl,ErrColonSpace
                call ErrWriteZ
                ret

PrintErrLocation
                push af
                push bc
                push de
                push hl
                ld hl,(NumString)
                ld de,ErrLineBuf
                call Hex2Dec
                call ErrGetFileName
                call ErrPrintZ
                ld a,':'
                ld c,PutChar
                rst #10
                call ErrLineStart
                call ErrPrintZ
                ld a,':'
                ld c,PutChar
                rst #10
                ld hl,CRLF
                ld c,PChars
                rst #10
                pop hl
                pop de
                pop bc
                pop af
                ret

ErrGetFileName  ld a,(CurrentFile)
                call GoSpec
                ld de,#0009
                add hl,de
                ld a,(hl)
                inc hl
                ld e,(hl)
                inc hl
                ld d,(hl)
                cp #ff
                jr z,ErrGetFileName1
                push de
                call SetBankAsm
                pop hl
                ld de,DataBuf
                call ErrCopySpecName
                ld a,(TextPage)
                call SetBankAsm
                ld hl,DataBuf
                ret
ErrGetFileName1 ex de,hl
                ret

ErrCopySpecName
                ld a,(hl)
                inc hl
                cp #09
                jr z,ErrCopySpecName
                cp #20
                jr z,ErrCopySpecName
                cp '"'
                jr z,ErrCopyQuoted
                cp "'"
                jr z,ErrCopyQuoted
ErrCopyPlain    or a
                jr z,ErrCopyDone
                cp #09
                jr z,ErrCopyDone
                cp #20
                jr z,ErrCopyDone
                cp #0d
                jr z,ErrCopyDone
                cp #0a
                jr z,ErrCopyDone
                cp ','
                jr z,ErrCopyDone
                cp ';'
                jr z,ErrCopyDone
                ld (de),a
                inc de
                ld a,(hl)
                inc hl
                jr ErrCopyPlain
ErrCopyQuoted   ld c,a
ErrCopyQuoted1  ld a,(hl)
                inc hl
                or a
                jr z,ErrCopyDone
                cp c
                jr z,ErrCopyDone
                cp #0d
                jr z,ErrCopyDone
                cp #0a
                jr z,ErrCopyDone
                ld (de),a
                inc de
                jr ErrCopyQuoted1
ErrCopyDone     xor a
                ld (de),a
                ret

ErrLineStart    ld hl,ErrLineBuf
ErrLineStart1   ld a,(hl)
                cp #20
                ret nz
                inc hl
                jr ErrLineStart1

ErrPrintZ       ld a,(hl)
                or a
                ret z
                inc hl
                push hl
                ld c,PutChar
                rst #10
                pop hl
                jr ErrPrintZ

ErrWriteZ       push hl
                ld de,0
ErrWriteZ1      ld a,(hl)
                or a
                jr z,ErrWriteZ2
                inc hl
                inc de
                jr ErrWriteZ1
ErrWriteZ2      pop hl
                ld a,d
                or e
                ret z
                ld a,(ErrOpenFile)
                ld c,Write
                rst #10
                ret

ErrWriteLine    push hl
                ld de,0
ErrWriteLine1   ld a,(hl)
                or a
                jr z,ErrWriteLine2
                cp #0d
                jr z,ErrWriteLine2
                cp #0a
                jr z,ErrWriteLine2
                inc hl
                inc de
                jr ErrWriteLine1
ErrWriteLine2   pop hl
                ld a,d
                or e
                ret z
                ld a,(ErrOpenFile)
                ld c,Write
                rst #10
                ret

CreateSub ;в v0.2X это теперь подпрограмма
                ld a,00100000b  ;атрибут файла
                ld c,Create
                rst #10         ;создание выходного файла
                jp c,Error      ;открываем файл для записи
                ld (OpenFile),a ;файловый манипулятор
                ld bc,(OutFileID)
                ld (SaveOutID),bc
                ld hl,(PCAddres)
                ld bc,(New1)
                or a
                sbc hl,bc
                ld (SaveOutLen),hl
                ld a,(GlBufer)  ;добавлено в v0.2X
                ld (SaveExeFlag),a
                or a
                jr z,SOF1A
                ld hl,DataBuf
                ld bc,#0200
                ld d,h
                ld e,l
                inc de
                xor a
                ld (hl),a
                push hl
                push bc
                push hl
                ldir
                pop hl
                ld a,"E"
                ld (hl),a
                inc hl
                ld (hl),"X"
                inc hl
                ld (hl),a
                inc hl
                ld (hl),#01
                inc hl
                inc hl
                ld (hl),#02
                ld hl,DataBuf+16 ; ???
                ld de,(New1)
                ld (hl),e
                inc hl
                ld (hl),d
                ld de,(New2)
                inc hl
                ld (hl),e
                inc hl
                ld (hl),d
                ld de,(New3)
                inc hl
                ld (hl),e
                inc hl
                ld (hl),d
                pop de
                pop hl

                ld a,(OpenFile) ;файловый манипулятор
                ld c,Write
                rst #10         ;запись блока в память
                jp c,Error

SOF1A           ld bc,(SaveOutID)
                ld a,c          ;ID блока памяти с выходным кодом
                ld c,b          ;кол-во записываемых банок
                ld b,0

SOF1            push af
                push bc
                ld c,SetWin3
                rst #10         ;банку в 3-тье окно
                jp c,Error

                pop bc
                push bc
                dec c           ;проверка на наличие еще не записанных банок
                jr z,SOF100

                ld de,16384     ;объем записываемого кода
                ld hl,#c000     ;начало в памяти
                ld a,(OpenFile) ;файловый манипулятор
                ld c,Write
                rst #10         ;запись блока в память
                jp c,Error

                pop bc
                pop af
                inc b
                dec c
                jr SOF1

SOF100          pop bc
                pop af
                ld a,(SaveExeFlag) ;для /E длина тела = текущий PC - адрес загрузки
                or a
                jr z,SOF102
                ld hl,(SaveOutLen)
                jr SOF101
SOF102
                or a
                ld bc,#8000
                ld hl,(SaveObjAdr)
                sbc hl,bc       ;вычисление объема хвоста файла
SOF101
                ex de,hl
                ld hl,#c000     ;начало кода
                ld a,(OpenFile) ;файловый манипулятор
                ld c,Write
                rst #10         ;запись остатка файла
                jp c,Error

                ;новое в v0.2X
                ld a,(OpenFile)
                ld c,Close
                rst #10
                jp c,Error

                xor a
                ld (OpenFile),a
                ret

SaveDirectiveFiles
                ld hl,SaveReqTable
                ld (SaveReqCur),hl
SDF0            ld hl,(SaveReqCur)
                ld de,(SaveReqPtr)
                or a
                sbc hl,de
                ret z
                ld hl,(SaveReqCur)
                ld e,(hl)
                inc hl
                ld d,(hl)
                inc hl
                ld (SaveStartTmp),de
                ld e,(hl)
                inc hl
                ld d,(hl)
                inc hl
                ld (SaveLenTmp),de
                push hl
                ld hl,Saving
                ld c,PChars
                rst #10
                pop hl
                push hl
                call PrString
                pop hl
                call SaveRangeFile
                ld hl,(SaveReqCur)
                ld de,SaveReqSize
                add hl,de
                ld (SaveReqCur),hl
                jr SDF0

SaveRangeFile  push hl
                ld c,Delete
                rst #10
                pop hl
                ld a,00100000b
                ld c,Create
                rst #10
                jp c,Error
                ld (OpenFile),a
                ld hl,(SaveStartTmp)
                ld de,(New1)
                or a
                sbc hl,de
                ld a,h
                and #c0
                rlca
                rlca
                ld (SaveCurPage),a
                ld a,h
                and #3f
                or #c0
                ld h,a
                ld (SaveOff),hl
SRF1            ld hl,(SaveLenTmp)
                ld a,h
                or l
                jr z,SRF4
                ld a,(SaveCurPage)
                ld b,a
                ld a,(OutFileID)
                ld c,SetWin3
                rst #10
                jp c,Error
                ld hl,0
                ld de,(SaveOff)
                or a
                sbc hl,de
                ld de,(SaveLenTmp)
                push hl
                or a
                sbc hl,de
                pop hl
                jr c,SRF2
                jr SRF3
SRF2            ex de,hl
SRF3            push de
                ld hl,(SaveOff)
                ld a,(OpenFile)
                ld c,Write
                rst #10
                jp c,Error
                pop de
                ld hl,(SaveLenTmp)
                or a
                sbc hl,de
                ld (SaveLenTmp),hl
                ld hl,(SaveOff)
                add hl,de
                ld a,h
                or l
                jr nz,SRF5
                ld hl,#c000
                ld a,(SaveCurPage)
                inc a
                ld (SaveCurPage),a
SRF5            ld (SaveOff),hl
                jr SRF1
SRF4            ld a,(OpenFile)
                ld c,Close
                rst #10
                jp c,Error
                xor a
                ld (OpenFile),a
                ret
;
;Создание строки: текущий диск, текущий путь, имя основного файла
;Вход: HL - буфер под выходную строку
;
CurSpec         push hl
                ld c,CurDisk
                rst #10         ;текущий диск
                jp c,Error
                add a,#61       ;имя текущего диска
                ld (hl),a
                inc hl
                ld a,":"
                ld (hl),a
                inc hl

                ld c,CurDir
                rst #10         ;текущий каталог
                jp c,Error
                dec de
                dec de
                ld a,(de)
                inc de
                cp '\'
                jr z,CurSpec1
                ld a,'\'
                ld (de),a
                inc de
CurSpec1        ld hl,ComBuffer
                ld bc,#0345
                rst #10         ;имя файлаOD
                jp c,Error
                pop hl
                ld a,"."
                ld bc,#0100
                cpir
                ld a,#10
                jp nz,Error
                ret
;
;Сохранение и восстановление текущего каталога вокруг INCLUDE
;
SaveCurPath     ld c,CurDisk
                rst #10
                jp c,Error
                ld (SaveCurDisk),a
                ld hl,SaveCurDir
                ld c,CurDir
                rst #10
                jp c,Error
                ret

RestoreCurPath  ld a,(SaveCurDisk)
                ld c,ChDisk
                rst #10
                jp c,Error
                ld hl,SaveCurDir
                ld c,ChDir
                rst #10
                jp c,Error
                ret

SetBankMap      ld de,(MapLabelID)
                jr SetBankAsm1
;
;Включение банок с исходниками во 2-е и 3-е окна
;Вход: A - лог.номер банки
;
SetBankAsm
;                push hl
                ld de,(InFileID);id блока памяти с исходниками и размер блока
SetBankAsm1     ld b,a
                ld a,d
                sub b
                ld c,a          ;оставшееся кол-во страниц
                ld a,e          ;ID блока памяти
                push hl ;добавлено в v0.2X
                push af
                push bc

                ld c,SetWin2
                rst #10         ;включили страницу во второе окно
                jp c,Error

                pop bc
                pop af
                pop hl
                dec c
                ret z
                inc b
                push hl

                ld c,SetWin3
                rst #10         ;включили страницу в третье окно
                jp c,Error

                pop hl
                ret
;
;Расчет адреса начала спецификации файла
;Вход: A - номер файла
;Выход: HL - адрес начала спецификации
;
GoSpec          ld h,0
                ld l,a
                add hl,hl       ;*2
                add hl,hl       ;*4
                ld d,h
                ld e,l
                add hl,hl       ;*8
                add hl,de       ;*12
                ld de,TblLoadFile
                add hl,de       ;начало описателя файла в таблице
                ret
;
;Загрузка файла в память
;Вход:HL - строка с именем файла
;Выход: HL - адрес загрузки файла
;Загрузка производится блоками по 16к через 3-е окно
;
LoadFile
                push hl
                call PrString   ;имя загружаемого файла на экран
                pop hl

                ld a,(Pass)     ;номер прохода
                or a
                jr z,LF5        ;переход на загрузку файла в память

                ld a,(NumOpenFile);номер загружаемого файла
                inc a           ;номер для слдующего файла
                ld (NumOpenFile),a
                dec a
                ld (CurrentFile),a
                call GoSpec     ;спецификация включаемого файла
                ld a,(hl)
                ld (TextPage),a ;1-ая лог.банка с исходником
                inc hl
                ld e,(hl)       ;адрес загрузки в страницу
                inc hl
                ld d,(hl)
                ex de,hl
                push hl
                jp LF6

LF5             ld a,1
                ld c,Open
                rst #10         ;открываем файл на чтение
                jp c,Error
                ld (OpenFile),a ;файловый манипулятор
                xor a
                ld (LastLineCR),a

                ld bc,(InFileID);ID блока с исходниками
                ld hl,(AdrOpenFile);адрес начала загрузки файла
                inc hl
                dec b           ;номер последней лог.страницы в блоке
                call ExtMemLF   ;расширить блок, если нужно

                push hl         ;адрес загрузки файла в 3 окно
                push hl
                push hl
                ld a,(NumOpenFile)
                inc a
                cp MaxLoadFile+1
                jr c,LF1

                ld hl,(BegString)
                ld b,IncludeEr  ;ошибка "Слишком много include файлов"
                call ErrorAsm   ;печать сообщения об ошибке
                jp ExitDSS      ;выход из программы

LF1             ld (NumOpenFile),a
                dec a
                call GoSpec     ;начало спецификации файла
                pop de
                push af
                ld a,b
                dec a
                ld (hl),a       ;лог.номер банки в блоке -1
                ld (TextPage),a ;лог.банка с началом загруженного файла -1
                inc hl
                ld (hl),e       ;адрес загрузки файла, мл.байт
                inc hl
                ld (hl),d       ;адрес загрузки файла, ст.байт
                ld de,#0006
                add hl,de
                ld a,(CurrentFile)
                ld (hl),a       ;файл-родитель
                inc hl
                ld a,(FileNamePage)
                ld (hl),a       ;банк строки с именем файла или #ff
                inc hl
                ld de,(FileNameAdr)
                ld (hl),e       ;адрес строки с именем файла
                inc hl
                ld (hl),d
                pop af
                ld (CurrentFile),a

LF4             push bc
                ld a,c
                ld c,SetWin3
                rst #10         ;банку в 3-е окно
                jp c,Error
                pop bc
                pop de
                ld hl,#0000
                or a
                sbc hl,de
                ex de,hl        ;DE - кол-во загружаемых байт
                push bc
                push hl
                ld a,(OpenFile) ;файловый манипулятор
                ld c,Read_
                rst #10         ;читаем файл в память
                jp c,Error

                ;конвертация LF в CR для исходников с unix line endings
                ex (sp),hl      ;HL=начало прочитанного блока
                push hl
                push de
                push af
                ld b,d
                ld c,e
LFconv1         ld a,b
                or c
                jr z,LFconv2
                ld a,(hl)
                cp #0d
                jr z,LFconv4
                cp #0a
                jr nz,LFconv5
                ld a,(LastLineCR)
                or a
                jr nz,LFconv6
                ld (hl),#0d
                jr LFconv6
LFconv4         ld a,1
                ld (LastLineCR),a
                jr LFconv3
LFconv5         xor a
                ld (LastLineCR),a
                jr LFconv3
LFconv6         xor a
                ld (LastLineCR),a
LFconv3         inc hl
                dec bc
                jr LFconv1
LFconv2         pop af
                pop de
                pop hl
                ex (sp),hl

                or a            ;прочитаны все байты?
                jr nz,LF3

                pop hl
                pop bc
                call ExtMemLF1  ;расширяем блок памяти
                push hl
                jr LF4

LF3             pop hl          ;адрес начала загрузки
                pop bc          ;номер последней лог.страницы и id-блока
                add hl,de       ;первый байт после загруженного файла
                push hl
                ld a,#0d        ;символ окончания строки
                dec hl
                cp (hl)         ;есть символы окончания строки?
                jr z,LF7
                dec hl
                cp (hl)
                jr z,LF7
                pop hl
                ld (hl),a       ;записываем код окончания строки
                inc hl
                call ExtMemLF   ;расширяем, если нужно блок
                push hl
LF7             pop hl
                xor a           ;ноль в конец файла
                ld (hl),a
                ld (AdrOpenFile),hl;адрес загрузки следующего файла
                inc b
                ld a,b
                ld (InFileID+1),a;новый размер блока памяти
                ld a,(OpenFile) ;файловый манипулятор
                ld c,Close
                rst #10         ;закрываем файл
                jp c,Error

                xor a
                ld (OpenFile),a ;обнуляем файловый манипулятор
                call MemInfoFree;сообщение об оставшейся свободной памяти
LF6             ld a,(TextPage)
                ld b,a
                inc b           ;номер банки с началом файла
                ld a,(InFileID) ;id блока с исходниками
                ld c,SetWin3
                rst #10         ;включаем в 3-е окно
                jp c,Error

                pop hl
                ret
;
;Расширение блока памяти для загружаемых листингов
;HL - адрес загрузки; BC - лог.номер последней страницы и id блока
;
ExtMemLF        xor a
                cp h            ;нужна ли новая банка?
                ret nz

ExtMemLF1       inc b
                inc b
                ld a,c
                push bc         ;размер блока и его id
                ld c,SetMem
                rst #10         ;расширить блок
                jp c,Error

                pop bc
                dec b
                ld hl,#c000     ;корректируем адрес загрузки
                ret

;Вывод на экран строки с информацией о свободной памяти
;
MemInfoFree     ld c,InfoMem    ;информация о памяти
                rst #10

                ld h,b
                ld l,c
                ld de,VarFMem
                call CalcMem

                ld hl,FreeMem1
                ld c,PChars
                rst #10         ;печать сообщения
                ret
;
;Выводит на экран строку с информацией об общей памяти
;
MemInfoTotal    ld c,InfoMem    ;информация о памяти
                rst #10

                ld de,VarTMem
                call CalcMem

                ld hl,TotalMem
                ld c,PChars
                rst #10         ;печать сообщения
                ret
;
;Производит перевод кол-ва банок в кБ с преобразованием в строку символов
;
CalcMem         add hl,hl       ;вычисление размера памяти в кБ
                add hl,hl       ;x4
                add hl,hl       ;x8
                add hl,hl       ;x16

Hex2Dec         push de
                ld bc,-10000
                ld a,#ff
                inc a
                add hl,bc
                jr c,$-2
                sbc hl,bc
                add a,#30
                ld (de),a
                inc de

                ld bc,-1000
                ld a,#ff
                inc a
                add hl,bc
                jr c,$-2
                sbc hl,bc
                add a,#30
                ld (de),a
                inc de

                ld bc,-100
                ld a,#ff
                inc a
                add hl,bc
                jr c,$-2
                sbc hl,bc
                add a,#30
                ld (de),a
                inc de

Hex2Dec2        ld bc,-10
                ld a,#ff
                inc a
                add hl,bc
                jr c,$-2
                sbc hl,bc

                add a,#30
                ld (de),a
                inc de

                ld a,l
                add a,#30
                ld (de),a

                pop hl
                ld a,#30
                ld bc,#0420
H2D1            cp (hl)
                ret nz
                ld (hl),c
                inc hl
                djnz H2D1
                ret
;
;Вызов функций DSS с установкой стека и страницы.
;
DSS;             ld (StackPr),sp ;запоминаем текущий стек программы
;                push af
;                in a,(#c2)      ;номер страницы, включенной во 2-е окно
;                ld (PageN),a    ;запоминаем в переменной
;                ld a,(PageW2)   ;востанавливаем системную страницу
;                out (#c2),a     ;установили страницу
;                pop af
;                ld sp,#bfff     ;установили стек
                ex af,af' ;'
                exx
                push af
                push bc
                push de
                push hl
                ex af,af' ;'
                exx
                rst #10         ;выполнение функции DSS
                jp c,Error      ;выход, если произошла ошибка
                ex af,af' ;'
                exx
                pop hl
                pop de
                pop bc
                pop af
                ex af,af' ;'
                exx
;                ld sp,(StackPr) ;установили стек программы
;                push af
;                ld a,(PageN)    ;востановили страницу программы
;                out (#c2),a
;                pop af
                ret
;
;Вызов функций BIOS с установкой стека и страницы.
;
;BIOS            ld (StackPr),sp ;запоминаем текущий стек программы
;                push af
;                in a,(#c2)      ;номер страницы, включенной во 2-е окно
;                ld (PageN),a    ;запоминаем в переменной
;                ld a,(PageW2)   ;востанавливаем системную страницу
;                out (#c2),a     ;установили страницу
;                pop af
;                ld sp,#bfff     ;установили стек
;                ex af,af' ;'
;                exx
;                push af
;                push bc
;                push de
;                push hl
;                ex af,af' ;'
;                exx
;                rst #08         ;выполнение функции DSS
;                jp c,Error      ;выход, если произошла ошибка
;                ex af,af' ;'
;                exx
;                pop hl
;                pop de
;                pop bc
;                pop af
;                ex af,af' ;'
;                exx
;                ld sp,(StackPr) ;установили стек программы
;                push af
;                ld a,(PageN)    ;востановили страницу программы
;                out (#c2),a
;                pop af
;                ret

;
;Выход в DSS с освобождением занятой памяти и закрытием файла
;
ExitDSS
;                ld a,(PageW2)
;                out (#c2),a
;                ld sp,#bfff
                call CloseErrLog
                ld a,(OpenFile) ;проверка, есть ли не закрытый файл
                or a
                jr z,EDSS1

                ld a,(OpenFile) ;закрываем открытый файл
                ld c,Close
                rst #10

EDSS1
                ld hl,InFileID
                ld b,4
FrMem2          ld c,(hl)
                inc hl
                ld a,(hl)
                inc hl
                or a
                jr z,FrMem1
                push hl
                push bc
                ld a,c
                ld c,FreeMem
                rst #10         ;освобождение блока памяти
                jp c,Error

                pop bc
                pop hl
FrMem1          djnz FrMem2

EDSS3           ld c,Exit       ;выход из программы
                rst #10
                ret
;
;Выход из программы с ошибкой
;
ErrorDSS1
                ld hl,ErrorPort
                ld c,PChars
                rst #10
                jp ExitDSS
ErrorDSS
;                push af
;                ld a,(PageW2)
;                out (#c2),a     ;установили страницу
;                pop af
;                ld sp,#bfff     ;установили стек
;
Error
                cp #21
                jr c,Error0     ;код ошибки < 20h ?
                ld a,#20
Error0
                add a,a
                ld hl,ErrorTabl
                ld d,0
                ld e,a
                add hl,de
                ld a,(hl)
                inc hl
                ld h,(hl)
                ld l,a

                ld c,PChars     ;вывод сообщения об ошибке
                rst #10
                ld hl,CRLF
                ld c,PChars
                rst #10
                jp ExitDSS

;При отсутствии параметров в командной строке
;на экран выводится краткий HELP
;
PrintHelp
                ld hl,Hello
                ld c,PChars
                rst #10         ;печать приветствия
                ld hl,Help
                ld c,PChars
                rst #10         ;печать подсказки
                ld c,Exit
                rst #10         ;выход из программы
                ret

;                include scanstr
;                include scancmnd
;                include d_mnem
;                include d_cmnd
;                include d_oprnd
;                include d_label
;                include calc
;                include util
;                include error

                include "scanstr.asm"
                include "scancmnd.asm"
                include "d_mnem.asm"
                include "d_cmnd.asm"
                include "d_oprnd.asm"
                include "d_label.asm"
                include "calc.asm"
                include "util.asm"
                include "error.asm"

;                include "debug.asm"
;
;
ErrorPort       db "Invalid RAM-port",13,10,0
TotalMem        db "Total memory: "
VarTMem         db "     " ; для zmac переделано - было ds 5," " (Shaos)
                db "kB",13,10,0
FreeMem1        db "Free memory:  "
VarFMem         db "     " ; для zmac переделано - было ds 5," " (Shaos)
                db "kB",13,10,0
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
PassText        db "Pass 1",13,10,0
Scanning        db 13,10,"Scanning Symbol table...     ",13,10,0 ; новое в v0.2X
Loading         db 13,10,"Load file: ",0
Saving          db 13,10,"Save file: ",0
Including       db 13,10,10,"Include file: ",0
IncludingBin    db 13,10,10,"Incbin file: ",0 ; новое в v0.2X
Continue        db 13,10,"Return to file: ",0
Asembling       db "Current line: 00000",13,0
;PrPCAddres      db "(00000)",13,0
Errors          db "Errors: 00000",32,32,32,"No code generated...",13,10,0
ErrLineBuf      db "00000",0
ErrColon        db ":",0
ErrColonSpace   db ": ",0
ErrCRLF         db 13,10,0
PrPause         db "Pause...  <Esc> to Exit or <AnyKey> to Continue",0
PrTimeComp      db 13,10,"Compile time - 00:00",13,10,10,0
CRLF            db 10,13,0
;
;------ Коды ошибок DOS ------
;
c0              db "O'Key!",13,10,0
c1              db "Invalid function",0
c2              db "Invalid drive number",0
c3              db "File not found",0
c4              db "Path not found",0
c5              db "Invalid handle",0
c6              db "Too many open files",0
c7              db "File exist",0
c8              db "File read only",0
c9              db "Root overflow",0
ca              db "No free space",0
cb              db "Directory not empty",0
cc              db "Attempt to remove current directory",0
cd              db "Invalid media",0
ce              db "Invalid operation",0
cf              db "Directory exist",0
c10             db "Invalid filename",0
c11             db "Invalid EXE-file",0
c12             db "Not supported EXE-file",0
c13             db "Permission denied",0
c14             db "Not ready",0
c15             db "Seek error",0
c16             db "Sector not found",0
c17             db "CRC error",0
c18             db "Write protect",0
c19             db "Read error",0
c1a             db "Write error",0
c1b             db "Drive failure",0
c1c             db "Unknown error : 28",0
c1d             db "Unknown error : 29",0
c1e             db "No free memory",0
c1f             db "Invalid memory block",0
c20             db "Unknown error : 32...",0
;---таблица с адресами кодов ошибок---
ErrorTabl       dw c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,ca,cb,cc,cd,ce,cf
                dw c10,c11,c12,c13,c14,c15,c16,c17,c18,c19,c1a,c1b
                dw c1c,c1d,c1e,c1f,c20

OpenFile        db 0            ;признак откр.файла (<>0 - есть откр.файл)
;OpenMem         db 0            ;кол-во занятых блоков памяти
Pass            db 0            ;номер прохода компилятора
InFileID        dw 0            ;ID и размер блока памяти под исходники (2)
OutFileID       dw 0            ; -"- под выходной код (2)
MapLabelID      dw 0            ; -"- под таблицу меток (2)
RepFileID       dw 0            ; -"- под файл репорта (2)
CapsLabel       db 0            ;#ff - все символы метки переводятся в
                                ;верхний регистр; #00 - нет
GlBufer         db 0            ;#ff - единый буфер для всех меток
                                ;#00 - локальный буфер для каждого листинга
RepFile         db 0            ;#ff - создавать файл репорт
                                ;#00 - не создавать
SymFlag         db 0            ;#ff - создавать таблицу символов (новое в v0.28)
                                ;#00 - не создавать
ErrFile         db 0            ;#ff - создавать файл ошибок
ErrOpenFile     db 0            ;манипулятор файла ошибок
ErrNameFlag     db 0            ;#ff - имя файла ошибок задано явно
ErrNameExt      db 0            ;#ff - в имени файла ошибок есть расширение
ErrMsgPtr       dw 0            ;адрес текста последней ошибки
ErrNameBuf      ds 128          ;явное имя файла ошибок
NoOutFlag       db 0            ;#ff - не создавать неявный выходной файл
FileNamePage    db 0            ;банк строки с именем загружаемого файла
FileNameAdr     dw 0            ;адрес строки с именем загружаемого файла
PhaseFlag       db 0            ;#00 - не было PHASE
                                ;#ff - установлен PHASE
New1            dw #8100        ; появилось в v0.2X
New2            dw #8100        ; появилось в v0.2X
New3            dw #bfff        ; появилось в v0.2X

EndLabel        db #00          ;старший байт конца таблицы меток

SaveObjAdr      dw #8000        ;адрес записи байта obj-кода в память
SaveOutID       dw 0            ;сохраненный ID/размер выходного кода
SaveOutLen      dw 0            ;сохраненная длина EXE-кода
SaveExeFlag     db 0            ;сохраненный признак генерации EXE-префикса
SaveReqCount    db 0            ;количество директив SAVE/SAVEBIN
SaveReqPtr      dw SaveReqTable ;следующая запись SAVE/SAVEBIN
SaveReqCur      dw 0            ;текущая запись при сохранении
SaveStartTmp    dw 0            ;рабочий адрес SAVE/SAVEBIN
SaveLenTmp      dw 0            ;рабочая длина SAVE/SAVEBIN
SaveOff         dw 0            ;рабочее смещение в окне #c000
SaveCurPage     db 0            ;рабочая страница выходного блока
SaveCurDisk     db 0            ;диск перед загрузкой INCLUDE
SaveCurDir      ds 128          ;каталог перед загрузкой INCLUDE
LastLineCR      db 0            ;предыдущий прочитанный байт был CR
CondActive      db #ff          ;#ff - текущий блок активен, #00 - пропуск
CondDepth       db 0            ;глубина условной компиляции
CondDelim       db 0            ;текущий разделитель условной директивы
CondValue       db 0            ;рабочее значение условия
CondPage2       db 0            ;рабочее сохранение окна Page2
CondPage3       db 0            ;рабочее сохранение окна Page3
DupActive       db 0            ;#ff - идет блок DUP
DupPendingFlag  db 0            ;#ff - сохранить начало DUP-блока после строки
DupJumpFlag     db 0            ;#ff - вернуться к началу DUP-блока
DupCount        dw 0            ;оставшееся количество повторов
DupStartAdr     dw 0            ;адрес первой строки DUP-блока
DupStartLine    dw 0            ;номер строки перед первой строкой блока
DupStartPage    db 0            ;страница первой строки DUP-блока
DupJumpAdr      dw 0            ;адрес перехода к началу блока
DupJumpLine     dw 0            ;номер строки для перехода
DupJumpPage     db 0            ;страница перехода
NumOpenFile     db #00          ;порядковый номер открываемого файла
CurrentFile     db #ff          ;номер текущего ассемблируемого файла
AdrOpenFile     dw #bfff        ;адрес начала загрузки очередного файла -1
MaxLoadFile     equ 64          ;максимальное количество исходных файлов
LoadFileRecSize equ 12          ;размер записи TblLoadFile
                ;+0 - номер банки загрузки файла -1 (1)
                ;+1 - адрес загрузки файла в 3-е окно (2)
                ;+3 - номер банки с include-строкой (1)
                ;+4 - адрес строки с именем подключаемого файла (2)
                ;+6 - номер include-строки (2)
                ;+8 - номер файла возврата (1)
                ;+9 - банк строки с именем файла или #ff для основного файла (1)
                ;+10 - адрес строки с именем файла (2)
TabLabel        equ #8000       ;начало таблицы меток
MaxSaveReq      equ 8
SaveReqNameLen  equ 64
SaveReqSize     equ SaveReqNameLen+4
SaveReqTable    ds SaveReqSize*MaxSaveReq
TblLoadFile     ds LoadFileRecSize*MaxLoadFile
MaxCond         equ 16
CondParent      ds MaxCond      ;активность родительского блока
CondSeen        ds MaxCond      ;истинная ветка текущего IF уже была
CondAct         ds MaxCond      ;активность текущего уровня
;FileID          equ $           ;id открытого файла (1)
;MemID           equ FileID+1    ;адрес таблицы выделенной памяти (2)
;MemID           equ $           ;адрес таблицы выделенной памяти (2)

RepFAdr         equ $          ;адрес начала имени файла репорта (2)
SomeAdr         equ RepFAdr+2  ;новый адрес в v0.28 (2)
OutFAdr         equ SomeAdr+2  ;адрес начала имени выходного файла (2)
Operand1        equ OutFAdr+2   ;код первого операнда (1)
Operand2        equ Operand1+1  ;код второго операнда (1)
Var1            equ Operand2+1  ;2-х байтное значение переменной (2)
Var2            equ Var1+2      ;значение смещения в командах с инд.рег. (1)
SPOp            equ Var2+1      ;вершина стека операций (1)
SPNum           equ SPOp+1      ;вершина стека значений (1)
TextPage        equ SPNum+3     ;оставшееся кол-во банок с текстом (1)
RetAddres       equ TextPage+1  ;адрес возврата при возникновении ошибки (2)
NumString       equ RetAddres+2 ;номер обрабатываемой строки (2)
BegString       equ NumString+2 ;адрес начала текущей строки в памяти (2)
LabelVar        equ BegString+2 ;значение метки (2)
ErrorPass       equ LabelVar+2  ;кол-во ошибок компиляции (2)
PCAddres        equ ErrorPass+2 ;адрес компиляции (2)
OrgAddres       equ PCAddres+2  ;адрес ассемб. при переходе на PHASE (2)
PhaseAddres     equ OrgAddres+2 ;значение PHASE адреса (2)
TimeComp        equ PhaseAddres+2;время начала компиляции (3)
CmndBuf         equ TimeComp+3  ;буфер команды или мнемоники (10)
WordBuf         equ CmndBuf+10  ;буфер калькулятора, буфер под мету и др.(255)
SomeBuf         equ WordBuf+255 ;добавлено для совместимости с v0.2X (255)
DataBuf         equ SomeBuf+255 ;буфер под объектный код (255)
StackOp         equ DataBuf+255 ;стек операций калькулятора (254)
StackNum        equ StackOp+254 ;стек членов выражения (254)
ComBuffer       equ StackNum+254;начало буфера параметров ком.строки
                ;данные распологаются следующим образом:
                ;диск, путь ,имя и расширение входного файла
                ;#00 - признак окончания 1-го параметра
                ;диск, путь ,имя и расширение выходного файла
                ;#00 - признак окончания 2-го параметра
                ;диск, путь ,имя и расширение файла-репорта
                ;#00 - признак окончания 3-го параметра
;Далее размещается таблица выделенных блоков памяти (2 байта на каждый блок,
;1-ый ббайт - idблока памяти, 2-ой - размер блока в банках)
;
; 1 блок - таблица меток
; 2 блок - объектный код
; 3 блок - исходный листинг
; 4 блок - репорт о процессе компиляции (?)

;                END
