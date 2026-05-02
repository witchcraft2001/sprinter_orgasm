ASM = ..\..\ORGASM.EXE
SRC = MAIN.ASM
OUT = INCL.EXE
INC = INC\TEXT.ASM

.PHONY: all clean

all: $(OUT)

$(OUT): $(SRC) $(INC)
	$(ASM) $(SRC) $(OUT) /E

clean:
	-DEL $(OUT)
