ASM = ..\..\ORGASM.EXE
SRC = MAIN.ASM
OUT = TASM.BIN

.PHONY: all clean

all: $(OUT)

$(OUT): $(SRC)
	$(ASM) $(SRC) /N /L=TASM.ERR

clean:
	-DEL $(OUT)
	-DEL TOUT.BIN
	-DEL TASM.ERR
