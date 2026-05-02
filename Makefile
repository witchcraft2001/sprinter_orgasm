SJASMPLUS ?= sjasmplus

OUT_DIR := out
DIST_DIR := distr
TARGET := $(OUT_DIR)/orgasm.exe
IMAGE := $(DIST_DIR)/orgasm.img
ZIP := $(DIST_DIR)/orgasm.zip
SRC := orgasm.asm
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

.PHONY: all image package dist clean distclean

all: $(TARGET)

$(TARGET): $(SRC) $(DEPS) | $(OUT_DIR)
	$(SJASMPLUS) --raw=$@ $(SRC)

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
