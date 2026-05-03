ASM = ..\..\ORGASM.EXE
SRC = MAIN.ASM
OUT = COND.BIN

.PHONY: all clean

all: $(OUT)

$(OUT): $(SRC)
	$(ASM) $(SRC) /N /L=COND.ERR

clean:
	-DEL $(OUT)
	-DEL COND.ERR
