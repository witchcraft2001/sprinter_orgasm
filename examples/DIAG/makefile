ASM = ..\..\ORGASM.EXE
SRC = MAIN.ASM
OUT = DIAG.BIN

.PHONY: all clean

all: $(OUT)

$(OUT): $(SRC)
	$(ASM) $(SRC) /N /L=DIAG.ERR

clean:
	-DEL $(OUT)
	-DEL DIAG.ERR
