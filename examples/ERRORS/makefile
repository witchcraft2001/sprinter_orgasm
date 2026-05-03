ASM = ..\..\ORGASM.EXE
SRC = ERRORS.ASM
OUT = ERRORS.EXE

.PHONY: all clean

all: $(OUT)

$(OUT): $(SRC)
	$(ASM) $(SRC) $(OUT) /E /L=ERRORS.ERR

clean:
	-DEL $(OUT)
	-DEL ERRORS.ERR
