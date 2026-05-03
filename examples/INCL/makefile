ASM = ..\..\ORGASM.EXE
SRC = MAIN.ASM
OUT = INCL.EXE
INC = INC\TEXT.ASM

.PHONY: all clean

all: $(OUT)

$(OUT): $(SRC) $(INC)
	$(ASM) $(SRC) $(OUT) /E /L=INCL.ERR

clean:
	-DEL $(OUT)
	-DEL INCL.ERR
