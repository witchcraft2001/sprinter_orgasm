# OrgAsm Manual

OrgAsm v0.29 is a two-pass Z80 assembler for the Sprinter computer under DSS. The historical author is Igor Zhadinets. The current version is maintained by Dmitry Mikhalchenkov.

## Requirements

Running `ORGASM.EXE` requires the target Sprinter environment with BIOS 3.xx and DSS Estex. Local source builds use `sjasmplus`:

```sh
make
make dist
```

`make` creates `out/orgasm.exe`. `make dist` creates the floppy image `distr/orgasm.img` and the zip distribution `distr/orgasm.zip`.

## Command Line

```text
OrgAsm [drv:\path\]inFile[.ext] [drv:\path\outFile.ext] [/options]
```

If the input file has no extension, `.asm` is appended. If no output file is specified, OrgAsm creates one next to the source with the `.exe` extension.

Options:

- `/E` or `-E` - create an EXE prefix. The load address comes from the first `ORG`, the entry point from `ENTRY`, and the stack from `STACK`.
- `/C` or `-C` - make letter case significant in label names.
- `/L`, `/L:name.err`, `/L=name.err` - create an error log only when errors are detected.
- `/M` - create a symbol table.
- `/N` - do not create the implicit output file; output is produced only by `SAVE`/`SAVEBIN` and explicitly requested service files.
- `/S` - clear the screen before running.

## Diagnostics

Compiler errors are printed on screen and prevent output generation. With `/L`, errors from the main source and all `INCLUDE` files are written to one log:

```text
file.asm:12: Syntax error
    source line
```

The `.ERR` file is created only after the first error.

## Source Line Format

```asm
Label           Instruction ; comment
```

A label must start in the first column. An instruction must not start in the first column. Multiple instructions can be written on one line with `:`, except lines containing `INCLUDE` and `INCBIN`:

```asm
Loop:           ld (hl),a: inc hl: djnz Loop
```

Label names may contain Latin letters, digits, and `_`, but cannot start with a digit.

## Local Labels

A local label starts with a dot and is visible until the next regular label:

```asm
Test1:          ld b,16
.loop:          inc hl
                djnz .loop

Test2:          ld b,32
.loop:          inc de
                djnz .loop
```

A local label can also be referenced by its full name, for example `Test1.loop`.

## Numbers and Expressions

Decimal, hexadecimal, and binary numbers are supported:

```asm
#a000
0C000h
0x8F12
%00110011
%0100'0000
10010110b
0b01010101
```

Binary numbers may use apostrophes as group separators.

`$` means the address of the current instruction. Characters in single or double quotes evaluate to their character code.

Supported operators:

- unary: `!`, `^`, `-`, `+`, `++`, `--`, `<`, `>`, `?Label`;
- shifts: `<<`, `>>`;
- arithmetic: `*`, `/`, `%`, `\`, `+`, `-`;
- comparisons: `<`, `=`, `>`, `<=`, `!=`, `<>`, `>=`;
- bitwise: `!`, `&`, `|`.

Expression results are 16-bit values; on overflow, the lower 16 bits are used.

## Supported Directives

### ORG

```asm
                org #8100
```

Sets the code placement address. If `ORG` is missing, `#8100` is used.

### ENTRY

```asm
                entry Start
```

Sets the entry point for the EXE prefix. Without `ENTRY`, the load address is used.

### STACK

```asm
                stack #bfff
```

Sets SP for the EXE prefix. The default value is `#bfff`.

### PHASE / DEPHASE / DISP / ENT

```asm
                phase #4000
Relocated:      ret
                dephase

                disp #7000
Virtual:        byte #01
                ent
```

Changes the assembly address without changing the physical object-code write address. `DISP` is a TASM-compatible alias for `PHASE`, and `ENT` is an alias for `DEPHASE`. Nested `PHASE`/`DISP` and `ORG` inside the block are not allowed.

### EQU

```asm
PChars          equ #5c
```

Assigns a constant value to a label. The expression must not use forward references.

### DB / DEFB / BYTE

```asm
Text:           db "Hello",13,10,0
                byte #3e,#2a
```

Generates bytes and strings.

### DW / DEFW / WORD

```asm
Table:          dw Start,Exit
                word #4000
```

Generates 16-bit little-endian words.

### DD / DEFD

```asm
Longs:          dd #5678
Ptr32:          defd Start
```

Generates 32-bit little-endian values. Expressions are evaluated as 16-bit values and padded with a zero high word.

### DS / DEFS / BLOCK

```asm
Buffer:         ds 256
Spaces:         ds 10," "
Padding:        block 16,#ff
```

Reserves and fills memory. Without the second parameter, zero is used.

### INCLUDE

```asm
                include "inc/text.asm"
```

Includes another source file. If the extension is missing, `.asm` is appended. Nested `INCLUDE` files are supported, up to 64 source files per build.

### INCBIN

```asm
Sprite:         incbin "sprite.bin"
Part:           incbin "data.bin",16,32
```

Inserts a whole binary file or a range selected by offset and length.

### SAVE / SAVEBIN

```asm
                org #4000
Start:          byte #3e,#2a
End:
                savebin "CODE.BIN",#4000,End-#4000
                save "COPY.BIN",#4000,End-#4000
```

Saves a range of compiled code to a binary file after the second pass succeeds. Writes are deferred until the end of compilation, so failed builds do not create partial files. Use `/N` when the source should produce files only through explicit `SAVE`/`SAVEBIN` directives.

One build can use up to 8 `SAVE`/`SAVEBIN` directives; the output file name in the directive is limited to 63 characters.

### Conditional Compilation

```asm
                define BUILD 1

                ifdef BUILD
Start:          byte #3e,#42
                else
Skipped bad source line
                endif

                ifn 0
                byte #32
                word Value
                endif

                if 0
Broken:         db ?
                elseif BUILD
Value:          byte #24
                endif

                ifndef NEWFLAG : define NEWFLAG 7 : endif
                ifdef NEWFLAG : byte NEWFLAG : endif
```

`DEFINE name value` adds a numeric name that can be used in expressions and `IFDEF` checks; `UNDEFINE name` removes a previously defined name. OrgAsm supports `IF expr`, `IFN expr`, `IFDEF name`, `IFNDEF name`, `ELSEIF expr`, `ELSE`, and `ENDIF`. Condition expressions must be resolvable at the directive location. Inactive branches are skipped to the end of the line without parsing labels, mnemonics, or invalid code. Conditional directives can be chained with other directives through `:`, for example `IFNDEF X : DEFINE X 1 : ENDIF`.

## Z80 Syntax Notes

OrgAsm supports documented Z80 instructions and several common extensions:

- `in a,(bc)` and `out (bc),e` are accepted as variants of `(c)`;
- `(ix)` and `(iy)` are accepted as `(ix+0)` and `(iy+0)`;
- `EX AF,AF'` can be written as `EX AF,AF` or `EXA`;
- `SLI` and `SLL` are synonyms;
- index register halves `XH`, `XL`, `YH`, `YL` are supported, as are `HX`, `LX`, `HY`, `LY`.

## Examples

Examples are stored in `examples/`:

- `HELLO` - minimal program;
- `LOCAL` - local labels;
- `INCL` - `INCLUDE` from a subdirectory;
- `MIXED` - several include files from different directories;
- `SAVE` - `SAVE`/`SAVEBIN`, `/N`, `BYTE`, `WORD`, `BLOCK`;
- `COND` - conditional compilation and inactive branch skipping;
- `TASM` - TASM-compatible `DISP`/`ENT` and `DD`/`DEFD`;
- `ERRORS` - intentionally invalid example for checking `/L`.

Each example directory contains a Sprinter make `makefile` and a `make.bat` file for users without make.

## Distribution

The zip distribution contains `ORGASM.EXE`, `README`, `README.ENG`, `HISTORY`, `EXAMPLES/`, and `DOCS/`. Text files in the distribution are converted to CP866. The floppy image contains the executable, README/HISTORY, and examples; `DOCS/` is not included in the floppy image.
