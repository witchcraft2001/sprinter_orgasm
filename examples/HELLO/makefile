ASM = ..\..\ORGASM.EXE
SRC = HELLO.ASM
OUT = HELLO.EXE

.PHONY: all clean

all: $(OUT)

$(OUT): $(SRC)
	$(ASM) $(SRC) $(OUT) /E

clean:
	-DEL $(OUT)
