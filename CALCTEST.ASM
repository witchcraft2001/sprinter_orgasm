; Минимальный тест калькулятора OrgAsm.
; На host запускается sjasmplus -DORGASM_HOST_BUILD CALCTEST.ASM,
; на target — ORGASM.EXE CALCTEST.ASM /N.
; Сравниваем display-вывод.

        ifdef ORGASM_HOST_BUILD
        device zxspectrum128
        endif

        org #4100

A:      equ #1234
B:      equ #5678
C:      equ A + 1

Code:   nop
        nop
        nop
End:

        ; Печать значений известных меток
        display "A    = ", A
        display "B    = ", B
        display "C    = ", C
        display "Code = ", Code
        display "End  = ", End

        ; Сравнения, которые на target раньше падали ("bare label = literal")
        display "A = #1234     -> ", A = #1234
        display "B = #5678     -> ", B = #5678
        display "Code = #4100  -> ", Code = #4100

        ; Сравнения, которые на target проходили (label с операцией слева)
        display "A+0 = #1234   -> ", A+0 = #1234
        display "B-0 = #5678   -> ", B-0 = #5678
        display "Code+1-1=#4100-> ", Code+1-1 = #4100

        ; Сравнения литералов между собой (без меток)
        display "#4100=#4100   -> ", #4100 = #4100
        display "#0001=#0002   -> ", #0001 = #0002

        ifdef ORGASM_HOST_BUILD
        savebin "out/calctest.bin", #4100, End-#4100
        else
        ; на target пишем в текущий каталог чтобы не запутать диагностику
        savebin "CALCTEST.BIN", #4100, End-#4100
        endif
