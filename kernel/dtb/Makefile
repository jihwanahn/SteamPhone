# Device Tree Build Makefile for SteamPhone
# Builds .dtb files from .dts sources

DTC = dtc
DTSTREE = arch/arm64/boot/dts
FDT_PATH = $(DTSTREE)

# Target device trees
DTBS := \
	sm8250-s20fe.dtb

# Default rule
all: dtbs

# Build individual .dtb from .dts
%.dtb: %.dts
	$(DTC) -I dts -O dtb -o $@ $<

# Clean
clean:
	rm -f $(DTBS)

# Install
install: dtbs
	mkdir -p $(FDT_PATH)
	cp $(DTBS) $(FDT_PATH)/

.PHONY: all clean install
