ASM = ..\..\ORGASM.EXE
SRC = MAIN.ASM
OUT = DIAG.BIN
DELTOOL = MKDEL.EXE

.PHONY: all clean

all: $(OUT)

$(OUT): $(SRC)
	$(ASM) $(SRC) /N /L=DIAG.ERR

clean:
	-$(DELTOOL) $(OUT)
	-$(DELTOOL) DIAG.ERR
