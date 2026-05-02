ASM = ..\..\ORGASM.EXE
SRC = LOCAL.ASM
OUT = LOCAL.EXE

.PHONY: all clean

all: $(OUT)

$(OUT): $(SRC)
	$(ASM) $(SRC) $(OUT) /E

clean:
	-DEL $(OUT)
