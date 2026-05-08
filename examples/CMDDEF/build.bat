@echo off
rem Test cmdline defines: -DNAME[=value] / /DNAME[=value].
rem Each pass prints display lines via /N (no implicit output) so we
rem only see the cmdline-define behaviour, not bytes.

echo === Pass 1: no defines (expect FOO/BAR/BAZ undef) ===
..\..\ORGASM.EXE MAIN.ASM /N /L=CMDDEF.ERR

echo.
echo === Pass 2: -DFOO -DBAR=42 -DBAZ=#ABCD (expect 0001 / 002A / ABCD) ===
..\..\ORGASM.EXE MAIN.ASM /N /L=CMDDEF.ERR -DFOO -DBAR=42 -DBAZ=#ABCD

echo.
echo === Pass 3: mixed /D and -D (expect 0001 / 1234 / undef) ===
..\..\ORGASM.EXE MAIN.ASM /N /L=CMDDEF.ERR /DFOO -DBAR=#1234

echo.
echo === Pass 4: duplicate -D (expect "Duplicate command-line define" and exit) ===
..\..\ORGASM.EXE MAIN.ASM /N -DFOO -DFOO
