ASM = ..\..\ORGASM.EXE
SRC = MAIN.ASM
OUT1 = CODE.BIN
OUT2 = COPY.BIN

.PHONY: all clean

all: $(OUT1) $(OUT2)

$(OUT1) $(OUT2): $(SRC)
	$(ASM) $(SRC) /N /L=SAVE.ERR

clean:
	-DEL $(OUT1)
	-DEL $(OUT2)
	-DEL SAVE.ERR
