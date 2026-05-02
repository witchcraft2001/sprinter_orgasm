;-----------------------------------------------------------------------------
;--                              Калькулятор                                --
;--                    Расчет 16-ти битных выражений                        --
;--      с использованием метода трансляции в обратную польскую запись      --
;-----------------------------------------------------------------------------
;Поддерживаются следующие операции (от высшего приоритета к низшему):
;  одноместные операции (наивысший приоритет):
; "!"  - логическое отрицание a=0 -> a=1; a<>0 -> a=0
; "^"  - побитное инвертирование
; "-"  - унарный минус
; "+"  - унарный плюс
; "++" - инкремент a=a+1
; "--" - декремент a=a-1
; "<"  - младший байт числа
; ">"  - старший байт числа
; "?"  - метка определена -> 1 ; не определена -> 0
;  двуместные операции
; "<<" - циклический сдвиг влево
; ">>" - циклический сдвиг вправо
;
; "*"  - умножение
; "/"  - деление
; "\"  - остаток от деления
;
; "+"  - сложение
; "-"  - вычитание
;
; "<"  - меньше
; "="  - равно
; ">"  - больше
; "<=" - меньше или равно
; "<>" - не равно
; ">=" - больше или равно
;
; "!"  - побитный XOR
; "&"  - побитный AND
; "|"  - побитный OR
;
;Для изменения порядка расчета выражения используются скобки ()
;
;Вход  A  - первый символ выражения
;      HL - адрес следующего символа выражения
;Выход DE - значение выражения
;      A  - символ, на котором закончилось выражение
;      HL - адрес следующего символа строки
;
GetVar          push bc
                ld b,a
                ld a,(Pass)     ;номер прохода компилятора
                inc a
                jr z,GV2        ;на 2-ом проходе производим расчет выражений,
                ld c,0
                ld a,b          ;иначе пропускаем выражение
GV3             cp #27          ;'   ;'
                jr z,GV5
                cp #22          ;"   ;"
                jr z,GV5
                cp ","
                jr z,GV6
                cp ":"
                jr z,GV6
                cp ";"
                jr z,GV6
                cp #0d
                jr z,GV4
GV7             ld a,(hl)       ;следующий символ
                inc hl
                jr GV3

GV6             inc c
                dec c
                jr nz,GV7
GV4             ld de,(PCAddres);текущий программный адрес
;                ld e,0
                pop bc
                ret

GV5             inc c
                dec c
                jr nz,GV8
                ld c,a
                jr GV7
GV8             cp c
                jr nz,GV7
                ld c,0
                jr GV7
;
;Принудительный вызов калькулятора на первом проходе
;
GetVar2         push bc
                ld b,a
;
;Собственно сам калькулятор
;
GV2             xor a
                ld (SPOp),a     ;инициализация стеков операций
                ld (SPNum),a    ;и переменных
                ld a,b

GV1             ld de,GV1       ;адрес возврата после вычислений
                push de         ;на стек
                cp " "          ;закончили на пробеле?
                call z,SkipSpace
                cp #09          ;.. табуляции?
                call z,SkipSpace
                ld b,1          ;приоритет (
                cp "("          ;открывающаяся скобка
                jp z,PushOp     ;в стек операций
                pop de          ;восстанавливаем вершину стека

                cp "?"          ;операция определения наличия метки в таблице
                jp z,WheLabel
                cp "_"          ;поиск метки
                jp z,SearchLab
                cp "."          ;поиск метки (заменено на точку в v0.2X)
                jp z,SearchLab
                call Letter     ;символ - буква?
                jp c,SearchLab   ;поиск метки
                call Numeric    ;символ - цифра?
                jp c,NumDec     ;dec число
                cp "#"          ;hex число?
                jp z,NumHex
                cp "%"          ;bin число?
                jp z,NumBin
                cp "'"          ;строка?
                jp z,Char
                cp '"'          ;строка?
                jp z,Char
                cp "$"          ;значение программного счетчика
                jp z,PCVar
                jp OneOperation

;Получение значения программного счетчика
PCVar           ex de,hl
                ld hl,(PCAddres)
                jp NextVar

;Получение значения метки
SearchLab       call ScanLabel1
                push hl
                call SearchLabel
                pop hl
                jp m,CalcEr5
                dec hl
                ex de,hl
                jp NextVar

;Операция "?Label"
WheLabel        ld a,(hl)       ;следующий символ
                inc hl
                cp " "          ;пробел?
                call z,SkipSpace
                cp #09          ;табуляция?
                call z,SkipSpace
                call ScanLabel1
                push hl
                call SearchLabel
                pop hl
                dec hl
                ex de,hl
                ld hl,#0000
                jp m,$+4
                inc hl
                jp NextVar

;Получение CHAR числа
Char            ld b,a          ; ' или "
                ex de,hl
                ld hl,#0000
Ch1             ld a,(de)
                cp #0d          ;обнаружен конец строки без конечных ковычек
                jp z,Ch2
                cp b
                jp z,NextVarInc
                ld h,l
                ld l,a
                inc de
                jr Ch1
Ch2             ex de,hl
                jp CalcEr

;Получение DEC числа
;Сначала определяется возможность записи:
;HEX числа - 0h...0FFFFh
;BIN числа - 0b...1111111111111111b
NumDec          ld d,h
                ld e,l
                dec de

                cp "0"
                jr nz,ND5
                ld a,(hl)
                call CapsLetter
                cp "X"
                jr z,NumHex1
                cp "B"
                jr nz,ND7
ND2             inc hl
                ld a,(hl)       ;следующий символ
                call Numeric    ;цифра?
                jr c,ND2
                call CapsLetter ;лат.буквы в верхний регистр
                cp "H"          ;HEX число
                jr z,NumHex+1
                cp "A"
                jp c,NumBin1
                cp "G"
                jp nc,NumBin1
                ld h,d
                ld l,e
ND5             ld a,(hl)
ND7             inc hl
                call Numeric
                jr c,ND5
                call CapsLetter
                cp "H"
                jr z,NumHex+1 ;HEX число
                cp "A"
                jr c,NumDec1
                cp "G"
                jr nc,NumDec1
                cp "B"
                jr nz,ND5
                ld a,(hl)
                call Numeric
                jr c,ND5
                call CapsLetter
                cp "H"          ;HEX число?
                jr z,NumHex+1
                cp "G"
                jr nc,NumBin+1  ;BIN число!
                cp "A"
                jr c,NumBin+1   ;BIN число!
                jr ND5

NumDec1         ld hl,#0000     ;получение DEC - числа
ND1             ld a,(de)
                call Numeric    ;цифра?
                jr nc,NextVar   ;выход если нет
                ld c,l
                ld b,h
                add hl,hl       ;*10
                add hl,hl
                add hl,bc
                add hl,hl
                ld b,0
                sub #30
                ld c,a
                add hl,bc
                inc de
                jr ND1

;Получение HEX числа
NumHex1         ld a,"#" ;добавлено в v0.2X
                inc hl   ;добавлено в v0.2X
NumHex          ex de,hl
                ld b,a          ;символ, на котором попали в процедуру
                ld hl,#0000
NH2             ld a,(de)
                call Numeric    ;цифра?
                jr c,NH1
                call CapsLetter ;лат.буквы в верхний регистр
                cp "G"
                jr nc,ExNumHex  ;выход
                cp "A"
                jr c,ExNumHex   ;выход

                sub #07
NH1             sub #30
                add hl,hl       ;*16
                add hl,hl
                add hl,hl
                add hl,hl
                or l
                ld l,a
                inc de
;                inc c
                jr NH2

ExNumHex        cp "H"
                jr nz,NextVar
                ld a,b
                cp "#"
                jr nz,NextVarInc
                ex de,hl
                jp CalcEr

;Получение BIN числа
NumBin1         ld a,"%" ;добавлено в v0.2X
                ex de,hl
                inc hl
                inc hl
NumBin          ex de,hl
                ld b,a          ;символ, на котором попали в процедуру
                ld hl,#00000
NB1             ld a,(de)
                sub #30
                srl a
                jr nz,ExNumBin
                rl l
                rl h
                inc de
;                inc c
                jr NB1

ExNumBin        ld a,(de)       ;символ, на котором вышли из процеуры
                call CapsLetter ;лат.буквы в верхний регистр
                cp "B"
                jr nz,NextVar
                ld a,b
                ex de,hl
                cp "%"
                jp z,CalcEr
                ex de,hl

NextVarInc      inc de
NextVar         ld a,(SPNum)    ;вершина стека
                add a,2
                jp z,CalcEr1    ;переполнение стека переменных
                ld (SPNum),a
                push de
                push hl
                ld hl,StackNum
                ld d,0
                sub 2
                ld e,a
                add hl,de
                pop de          ;полученное число
                ld (hl),e
                inc hl
                ld (hl),d
                pop hl

NV1             ld a,(hl)
                inc hl
;                inc c
                ld de,NV1       ;возврат после вычисления в ()
                push de         ;на стек
                cp " "          ;закончили на пробеле?
                call z,SkipSpace
                cp #09          ;.. табуляции?
                call z,SkipSpace
                cp ")"
                jp z,PopOp1     ;вычисление выражения в ()
                pop de          ;восстанавливаем стек
                cp #0d
                jp z,ExitVar
                cp ":"          ;закончили на разделителе команд?
                jp z,ExitVar
                cp ","          ;.. разделителе операндов?
                jp z,ExitVar
                cp ";"          ;.. комментарии?
                jp z,ExitVar
;                jp TwoOperation
;
;Поиск двуместной операции и занесение ее в стек опреаций
;Вход:          A - символ операции
;
TwoOperation    ld c,a
                ld a,(hl)       ;следующий символ
                cp "="          ;проверка возможных двухсимвольных
                jr z,TO1        ;операций сравнения и сдвигов
                cp "<"
                jr z,TO2
                cp ">"
                jr nz,TO3

                ld a,c
                ld b,#04
                cp "<"          ;не равно
                jr z,TO01
                ld b,#07
                cp ">"          ;сдвиг вправо
                jr nz,TO3
TO01            add a,#BE ; #80+">" ;второй символ двойной операции
                inc hl
;                inc c
                jr TO5

TO1             ld a,c
                cp "<"          ;меньше или равно
                jr z,TO11
                cp ">"          ;больше или равно
                jr z,TO11
                cp "!"          ;добавлено в v0.2X
                jr nz,TO3
TO11            add a,#BD       ;изменено в v0.2X
                ld b,#04        ;приоритет
                inc hl
;                inc c
                jr TO5

TO2             cp c            ;сдвиг влево
                jr nz,TO3
                add a,#BC       ;изменено в v0.2X
                ld b,#07        ;приоритет
                inc hl
;                inc c
                jr TO5

TO3             push hl
;                ld a,c
                ld hl,TblTwoOp-1;таблица двуместных односимвольных операций
TO4             inc hl
                ld a,(hl)       ;символ операции
                inc hl
                or a
                jr z,TO6
                cp c
                jr nz,TO4
                ld b,(hl)       ;приоритет операции
                pop hl

TO5             push af
                call PopOp      ;проверить стек операций
                pop af
                call PushOp     ;затолкнуть ее в стек
                jp GV1          ;продолжить разбор строки

TO6             pop hl
                ld b,InvalidExp ;"Ошибка в выражении"
                jp SkipStrC
;
;Поиск одноместной операции и занесение ее в стек опреаций
;Вход:          A - символ операции
;
OneOperation    ld c,a
                ld a,(hl)       ;следующий символ
                cp "+"          ;проверка возможных двухсимвольных
                jr z,OO3        ;операций сравнения и сдвигов
                cp "-"
                jr nz,OO5

OO3             cp c            ;декремент / инкремент
                jr nz,OO5
                add a,a         ;второй символ двойной операции
                add a,#80       ;добавлено в v0.2X
                inc hl
                jr OO4

OO5             push hl
                ld hl,TblOneOp-1;таблица одноместных операций
;                ld b,a
OO1             inc hl
                ld a,(hl)       ;очередная операция из таблицы
                or a            ;проверка на достижение конца таблицы
                jr z,OO2
                cp c
                jr nz,OO1
                pop hl
OO4             ld b,#ff        ;приоритет одноместной опреации
                call PushOp     ;поместить операцию на стек
                jp GV1          ;продолжить разбор строки

OO2             pop hl
                jp CalcEr
;
;Занесение на стек операции и ее приоритета
;Вход:          A - символ операции
;               B - приоритет
;
PushOp          ;ex af,af'
                ld c,a
                ld a,(SPOp)     ;вершина стека операций
                add a,2
                jp z,CalcEr1    ;переполнение стека
                ld (SPOp),a
                push hl
                ld hl,StackOp
                ld d,0
                sub 2
                ld e,a
                add hl,de
;                ex af,af'
                ld (hl),c
                inc hl
                ld (hl),b
                pop hl
                ld a,(hl)
                inc hl
                inc c
                ret
;
;Выталкивание из стека операций и вычисление полученных выражений
;Вход:          B - приоритет операции
;
PopOp1          ld b,#01        ;приоритет )
PopOp           ld a,(SPOp)     ;вершина стека операций
                or a            ;на стеке нет операций
                jr nz,PpOp8     ;нечего выталкивать
                dec b
                jp z,CalcEr2    ;ошибка в выражении, нет (
                inc b
                ret

PpOp8           push hl
                ld hl,StackOp
                ld d,0
                ld e,a
                add hl,de       ;адрес вершины стека
                pop de
                ex de,hl
PpOp3           ;ex af,af'
                ld c,a
                dec de
                ld a,(de)       ;приоритет предыдущей операции
                dec de
                cp b            ;сравнить приоритеты
                jr nc,PpOp4     ;вытолкнуть операцию и произвести вычисление
                cp #01          ;встретили (
                ret z           ;выход
                ;ex af,af'
                ld a,c
                sub 2
                jr nz,PpOp3     ;стек еще не пуст

;                ld a,b
;                dec b           ;1-ый приоритет, искали (
;                jp z,CalcEr2    ;и не нашли!
                ret

PpOp4           push hl         ;адрес следующего символа в строке
                push bc         ;B - приоритет, C - кол-во операций на стеке
                push de         ;адрес текущей операции в стеке операций
                ex de,hl
                ld e,(hl)       ;операция
                ld d,a          ;приоритет
                push de         ;операция и приоритет вычисляемой операции
                ld d,h
                ld e,l
                ld a,(SPOp)
                sub #02
                ld (SPOp),a
                cpl
                sub #03
                ld c,a
                ld b,#00
                inc hl
                inc hl
                ldir            ;выталкиваем операцию из стека

                pop de
                ld a,d          ;приоритет
                dec a
                jr nz,PpOp7

                pop de          ;выход, если вычислили выражение в ()
                pop bc
                pop hl
                ret

PpOp7           ld a,(SPNum)
                or a
                jp z,CalcEr     ;ошибка, если стек операндов пуст
                ld c,a
                ld b,#00
                ld hl,StackNum
                add hl,bc

                ld bc,PpOp5     ;адрес возврата после вычислений
                push bc         ;на стек его, возврат производим по RET

                ld a,e          ;восстанавили в A символ операции
                ld b,d          ;и в B приоритет
                dec hl
                ld d,(hl)
                dec hl
                ld e,(hl)       ;в DE операнд
                inc b           ;операция одноместная?
                jp z,OneValue

                dec hl          ;к следующему операнду
                ld c,a
                ld a,(SPNum)
                sub 2
                jp z,CalcEr     ;ошибка, если стек операндов пуст
                ld (SPNum),a
                ld a,c
                ld c,(hl)
                dec hl
                ld l,(hl)
                ld h,c          ;в HL первый операнд
                jp TwoValue

PpOp5           ld a,(SPNum)    ;возврат после вычислений
                sub 2
                ld c,a          ;результат заносим в стек операндов
                ld b,#00
                ex de,hl
                ld hl,StackNum
                add hl,bc
                ld (hl),e       ;мл.байт результата
                inc hl
                ld (hl),d       ;ст.байт результата
                pop de
                pop bc
                pop hl
;                ex af,af'       ;указатель вершины стека операций
;                sub 2
;                ld (SPOp),a
                ld a,c
                sub 2
;                ld a,(SPOp)
;                or a
                jp nz,PpOp3     ;продолжить просмотр стека операций
                dec b           ;1-ый приоритет, искали (
                jp z,CalcEr2    ;и не нашли!
                ret
;
;Вычисление двуместных операций
;Вход:          HL - первый операнд
;               DE - второй операнд
;               A  - операция
;Выход: HL - результат
;
TwoValue        cp "+"          ;сложение
                jr nz,TV1
                add hl,de
                ret

TV1             cp "-"          ;вычитание
                jr nz,TV2
                or a
                sbc hl,de
                ret

TV2             cp "*"          ;умножение
                jr nz,TV3
                push bc
                ld b,h
                ld c,l
                ld hl,#0000
                ld a,#10
MultLp          rr b
                rr c
                jr nc,$+3
                add hl,de
                sla e
                rl d
                dec a
                jr nz,MultLp
                pop bc
                ret

TV3             cp '/'          ;деление
                jp z,Divide

                cp '\'          ;остаток от деление
                jr z,TV4
                cp "%"          ;добавлено в v0.2X
                jr nz,TV5
TV4             call Divide
                ex de,hl
                ret

TV5             cp "!"          ;XOR
                jr nz,TV6
                ld a,l
                xor e
                ld l,a
                ld a,h
                xor d
                ld h,a
                ret

TV6             cp "&"          ;AND
                jr nz,TV7
                ld a,l
                and e
                ld l,a
                ld a,h
                and d
                ld h,a
                ret

TV7             cp "|"          ;OR
                jr nz,TV8
                ld a,l
                or e
                ld l,a
                ld a,h
                or d
                ld h,a
                ret

TV8             cp "<"          ;меньше
                jr nz,TV9
                ld a,d
                cp h
                jr c,Falsh
                jr nz,True
                ld a,l
                cp e
                jr nc,Falsh
True            ld hl,#0001
                ret
Falsh           ld hl,#0000
                ret

TV9             cp "="          ;равно
                jr nz,TV10
                ld a,d
                cp h
                jr nz,Falsh
                ld a,l
                cp e
                jr nz,Falsh
                jr True

TV10            cp ">"          ;больше
                jr nz,TV11
                ld a,h
                cp d
                jr c,Falsh
                jr nz,True
                ld a,e
                cp l
                jr nc,Falsh
                jr True

TV11            cp #F9 ; #80+"<"+"="      ;меньше или равно
                jr nz,TV12
                ld a,d
                cp h
                jr c,Falsh
                jr nz,True
                ld a,e
                cp l
                jr c,Falsh
                jr True

TV12            cp #FA ; #80+"<"+">"      ;не равно
                jr z,TV12A          ;добавлено в v0.2X
                cp #DE ; #80+"!"+"=";добавлено в v0.2X
                jr nz,TV13
TV12A           ld a,d
                cp h
                jr nz,True
                ld a,l
                cp e
                jr z,Falsh
                jr True

TV13            cp #FB ; #80+">"+"="      ;больше или равно
                jr nz,TV14
                ld a,h
                cp d
                jr c,Falsh
                jr nz,True
                ld a,l
                cp e
                jr c,Falsh
                jr True

; в v0.2X метка RLeft была переставлена на 2 инструкции вверх
TV14            cp #F8 ; #80+"<"+"<"      ;сдвиг влево
                jr nz,TV15
RLeft           ld a,h
                rla             ;7-ой бит H во флаг CY
                rl l
                rl h            ;сдвиг HL влево
                dec de ; исправлено в v0.2X
                ld a,e
                or d
                jr nz,RLeft
                ret

; в v0.2X метка RReft была переставлена на 2 инструкции вверх
TV15            cp #FC ; #80+">"+">"      ;сдвиг вправо
                jp nz,CalcEr
RRight          ld a,l
                rra             ;0-ой бит L во флаг CY
                rr h
                rr l            ;сдвиг HL вправо
                dec de ; исправлено в v0.2X
                ld a,e
                or d
                jr nz,RRight
                ret
;
;Деление HL=HL/DE (остаток в DE)
;
Divide          ld a,e
                or d
                jr nz,Div1
                pop bc          ;ошибка "Деление на ноль"
                pop bc
                pop de
;                pop bc
                pop hl
                jp CalcEr4
Div1            push bc
                ld b,h
                ld c,l
                ld hl,0
                ld a,16
                sla c
                rl b
Div             adc hl,hl
                sbc hl,de
                jr nc,$+3
                add hl,de
                rl c
                rl b
                dec a
                jp nz,Div
                ex de,hl
                ld a,c
                cpl
                ld l,a
                ld a,b
                cpl
                ld h,a
                pop bc
                ret
;
;Вычисление одноместных операций
;Вход:          DE - операнд
;               A  - операция
;Выход: HL - результат
;
OneValue        ex de,hl

                cp "!"          ;отрицание
                jr nz,OV1
                ld a,h
                cp l
                jr z,OV11
                ld hl,#0000
                ret

OV1             cp "^"          ;инвертирование
                jr nz,OV2
                ld a,h
                cpl
                ld h,a
                ld a,l
                cpl
                ld l,a
                ret

OV2             cp #D6 ; #80+"+"+"+"      ;инкремент
                jr nz,OV3
OV11            inc hl
                ret

OV3             cp #DA ; #80+"-"+"-"      ;декремент
                jr nz,OV4
                dec hl
                ret

OV4             cp ">"          ;старший байт
                jr nz,OV5
                ld l,h
                ld h,0
                ret

OV5             cp "<"          ;младший байт
                jr nz,OV6
                ld h,0
                ret

OV6             cp "?"          ;определенность метки
                jr nz,OV7

OV7             cp "+"          ;унарный плюс
                jr nz,OV8
                ret

OV8             cp "-"          ;унарный минус
                jp nz,CalcEr
                ld de,#0000
                ex de,hl
                or a
                sbc hl,de
                ret
;
;Выход с получением конечного результата
;
ExitVar         push af
;                push bc
                push hl
                ld b,#02        ;приоритет, выталкивание всего стека
;                ld a,(SPOp)
;                or a
;                jr z,EV1
;                add a,2
;                ld (SPOp),a
                call PopOp
                ld a,(SPOp)
                or a            ;если стек операций не пуст,
                jr nz,CalcEr3   ;то наткнулись на '(' без ')'
EV1             ld a,(SPNum)
                sub 2           ;если стек операндов содержит более 1
                jr nz,CalcEr    ;операнда, то в выражении ошибка
                ld hl,StackNum
                ld e,(hl)
                inc hl
                ld d,(hl)       ;в DE результат
                pop hl
;                pop bc
                pop af
                pop bc
                ret
;
;Выход по ошибке
;
CalcEr5         ld b,NoLabel    ;ошибка "Метка не определена"
                jr $+12
CalcEr          ld b,InvalidExp ;"Ошибка в выражении"
                jr $+16
CalcEr1         ld b,StackOpEr  ;ошибка "Переполнение стека операций"
                jr $+12
CalcEr2         ld b,MissingEr1 ;ошибка ") без ("
                jr $+8
CalcEr3         ld b,MissingEr2 ;ошибка "( без )"
                jr $+4
CalcEr4         ld b,DivZeroEr  ;ошибка "Деление на ноль"
                dec hl
                ld a,(hl)
                inc hl
                ld sp,(RetAddres)
                jp SkipStrC


;SPOp            db #00          ;вершина стека операций
;StackOp         ds 254          ;стек операций
;SPNum           db #00          ;вершина стека чисел
;StackNum        ds 254          ;стек чисел


;
;-- Таблица операций --
;
TblOneOp        db "!"          ;лог.отрицание a=0 -> a=1; a<>0 -> a=0
                db "^"          ;побитное инвертирование
                db "+"          ;инкремент a=a+1
                db "-"          ;декремент a=a-1
                db "<"          ;младший байт числа
                db ">"          ;старший байт числа
;                db "?"          ;=1 -> метка определена; =0 -> не определена;
;                db "~"          ;вычитание из нуля 0-a

                db 0

TblTwoOp        db "+",5        ;сложение
                db "-",5        ;вычитание
                db "*",6        ;умножение
                db '/',6        ;деление
                db '\',6        ;остаток от деления
                db "%",6        ;остаток от деления
                db "!",3        ;побитный XOR
                db "&",3        ;побитный AND
                db "|",3        ;побитный OR
                db "<",4        ;меньше
                db "=",4        ;равно
                db ">",4        ;больше

                db 0

;TblTwoOp2       db "<<",6       ;циклический сдвиг влево
;                db "<=",3       ;меньше или равно
;                db "<>",3       ;не равно
;                db ">>",6       ;циклический сдвиг вправо
;                db ">=",3       ;больше или равно
