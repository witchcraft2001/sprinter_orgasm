SJASMPLUS ?= sjasmplus

OUT_DIR := out
DIST_DIR := distr
TARGET := $(OUT_DIR)/orgasm.exe
CORE := $(OUT_DIR)/core.bin
PACKED_CORE := $(OUT_DIR)/core.hst
UNPACKED_TARGET := $(OUT_DIR)/orgunpk.exe
IMAGE := $(DIST_DIR)/orgasm.img
ZIP := $(DIST_DIR)/orgasm.zip
SRC := orgasm.asm
LOADER_SRC := orgload.asm
MHMT := tools/mhmt
DEPS := \
	scanstr.asm \
	scancmnd.asm \
	d_mnem.asm \
	d_cmnd.asm \
	d_oprnd.asm \
	d_label.asm \
	calc.asm \
	util.asm \
	error.asm

.PHONY: all unpacked image package dist clean distclean

all: $(TARGET)

$(CORE): $(SRC) $(DEPS) | $(OUT_DIR)
	$(SJASMPLUS) --raw=$@ $(SRC)

$(PACKED_CORE): $(CORE) $(MHMT) | $(OUT_DIR)
	$(MHMT) -hst -zxh $(CORE) $(PACKED_CORE)

$(TARGET): $(LOADER_SRC) depack.asm $(PACKED_CORE) | $(OUT_DIR)
	$(SJASMPLUS) --raw=$@ $(LOADER_SRC)

$(UNPACKED_TARGET): $(LOADER_SRC) $(CORE) | $(OUT_DIR)
	$(SJASMPLUS) -DORGASM_UNPACKED --raw=$@ $(LOADER_SRC)

unpacked: $(UNPACKED_TARGET)

$(OUT_DIR):
	mkdir -p $@

image: $(TARGET)
	tools/image.sh $(TARGET) $(IMAGE)

package: $(TARGET)
	tools/package.sh $(TARGET) $(ZIP)

dist: image package

clean:
	rm -rf $(OUT_DIR)

distclean: clean
	rm -rf $(DIST_DIR)
