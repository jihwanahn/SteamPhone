# SteamPhone - Galaxy S20 FE to SteamOS Conversion
# Top-level build orchestrator

SHELL := /bin/bash
.PHONY: all kernel rootfs gamescope steam image flash clean help

# Configuration
DEVICE       ?= exynos990
ARCH         := aarch64
CROSS_COMPILE ?= aarch64-linux-gnu-
KERNEL_VER   ?= 6.6
BUILD_DIR    := $(CURDIR)/build
IMAGE_DIR    := $(BUILD_DIR)/images
ROOTFS_DIR   := $(BUILD_DIR)/rootfs
KERNEL_DIR   := $(BUILD_DIR)/kernel

# Device-specific settings
ifeq ($(DEVICE),exynos990)
    KERNEL_DEFCONFIG := steamphone_exynos990_defconfig
    DTB_TARGET       := exynos990-s20fe.dtb
    GPU_DRIVER       := panfrost
    SOC_FAMILY       := samsung
else ifeq ($(DEVICE),sd865)
    KERNEL_DEFCONFIG := steamphone_sd865_defconfig
    DTB_TARGET       := sm8250-s20fe.dtb
    GPU_DRIVER       := freedreno
    SOC_FAMILY       := qualcomm
else
    $(error Unknown DEVICE: $(DEVICE). Use 'exynos990' or 'sd865')
endif

all: kernel rootfs gamescope steam image
	@echo "=== SteamPhone build complete for $(DEVICE) ==="
	@echo "Flash image: $(IMAGE_DIR)/steamphone-$(DEVICE).img"

# --- Kernel ---
kernel:
	@echo "=== Building kernel for $(DEVICE) ==="
	@mkdir -p $(KERNEL_DIR)
	./scripts/build/build-kernel.sh \
		--device $(DEVICE) \
		--cross-compile $(CROSS_COMPILE) \
		--defconfig $(KERNEL_DEFCONFIG) \
		--output $(KERNEL_DIR)

# --- Root Filesystem ---
rootfs: kernel
	@echo "=== Building rootfs ==="
	@mkdir -p $(ROOTFS_DIR)
	./scripts/build/build-rootfs.sh \
		--device $(DEVICE) \
		--kernel $(KERNEL_DIR) \
		--gpu-driver $(GPU_DRIVER) \
		--output $(ROOTFS_DIR)

# --- Gamescope ---
gamescope:
	@echo "=== Building Gamescope for ARM ==="
	./scripts/build/build-gamescope.sh \
		--cross-compile $(CROSS_COMPILE) \
		--output $(BUILD_DIR)/gamescope

# --- Steam Client (Box86/Box64) ---
steam:
	@echo "=== Setting up Steam via Box64/Box86 ==="
	./scripts/build/build-box64.sh \
		--cross-compile $(CROSS_COMPILE) \
		--output $(BUILD_DIR)/steam

# --- Flashable Image ---
image: rootfs
	@echo "=== Creating flashable image ==="
	@mkdir -p $(IMAGE_DIR)
	./scripts/build/create-image.sh \
		--rootfs $(ROOTFS_DIR) \
		--kernel $(KERNEL_DIR) \
		--device $(DEVICE) \
		--output $(IMAGE_DIR)/steamphone-$(DEVICE).img

# --- Flash to Device ---
flash:
	@echo "=== Flashing to device ==="
	@test -f $(IMAGE_DIR)/steamphone-$(DEVICE).img || \
		(echo "Error: Build image first with 'make image'" && exit 1)
	./scripts/install/flash.sh \
		--image $(IMAGE_DIR)/steamphone-$(DEVICE).img \
		--device $(DEVICE)

# --- Clean ---
clean:
	@echo "=== Cleaning build directory ==="
	rm -rf $(BUILD_DIR)

# --- Help ---
help:
	@echo "SteamPhone Build System"
	@echo ""
	@echo "Usage: make [target] [DEVICE=exynos990|sd865]"
	@echo ""
	@echo "Targets:"
	@echo "  all        - Build everything"
	@echo "  kernel     - Build Linux kernel"
	@echo "  rootfs     - Build root filesystem"
	@echo "  gamescope  - Build Gamescope compositor"
	@echo "  steam      - Build Box64/Box86 + Steam integration"
	@echo "  image      - Create flashable image"
	@echo "  flash      - Flash image to connected device"
	@echo "  clean      - Remove build artifacts"
	@echo "  help       - Show this message"
	@echo ""
	@echo "Variables:"
	@echo "  DEVICE         - Target device (exynos990 or sd865)"
	@echo "  CROSS_COMPILE  - Cross compiler prefix"
	@echo "  KERNEL_VER     - Kernel version to build"
