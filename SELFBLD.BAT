@echo off
rem Self-build: ассемблируем сами себя через cmdline -D defines, без
rem отдельных wrapper-файлов. Шаг 1 даёт OUT\CORE.BIN и OUT\OVERLAY.BIN,
rem шаг 2 собирает из них unpacked OUT\ORGASM.EXE.
..\ORGASM.EXE orgasm.asm /N /L=ORGSELF.ERR -DORGASM_WITH_OVERLAY -DORGASM_SELF_BUILD
..\ORGASM.EXE orgload.asm /N /L=ORGLDUP.ERR -DORGASM_UNPACKED -DORGASM_SELF_BUILD
