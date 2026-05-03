ASM = ..\..\ORGASM.EXE
SRC = MAIN.ASM
OUT = MIXED.EXE
ROOT = ROOT.ASM
INCA = DIRA\A.ASM
INCB = DIRB\B.ASM

.PHONY: all clean

all: $(OUT)

$(OUT): $(SRC) $(ROOT) $(INCA) $(INCB)
	$(ASM) $(SRC) $(OUT) /E

clean:
	-DEL $(OUT)
