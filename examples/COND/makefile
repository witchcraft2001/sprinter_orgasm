ASM = ..\..\ORGASM.EXE
SRC = MAIN.ASM
OUT = COND.BIN
DELTOOL = MKDEL.EXE

.PHONY: all clean

all: $(OUT)

$(OUT): $(SRC)
	$(ASM) $(SRC) /N /L=COND.ERR

clean:
	-$(DELTOOL) $(OUT)
	-$(DELTOOL) COND.ERR
