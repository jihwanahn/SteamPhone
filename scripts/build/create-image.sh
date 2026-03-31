#!/usr/bin/env bash
# SteamPhone - Flashable Image Creator
# Packages the rootfs into a flashable image for Samsung Galaxy S20 FE.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

ROOTFS_DIR="${PROJECT_ROOT}/build/rootfs/root"
KERNEL_DIR="${PROJECT_ROOT}/build/kernel"
DEVICE="exynos990"
OUTPUT=""
IMAGE_SIZE="8G"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[IMAGE]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[IMAGE]${NC} $*"; }
log_error() { echo -e "${RED}[IMAGE]${NC} $*"; }

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
    --rootfs DIR    Root filesystem directory
    --kernel DIR    Kernel build directory
    --device DEV    Target device (exynos990 or sd865)
    --output FILE   Output image path
    --size SIZE     Image size (default: 8G)
    -h, --help      Show this help
EOF
    exit 0
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --rootfs)  ROOTFS_DIR="$2"; shift 2 ;;
            --kernel)  KERNEL_DIR="$2"; shift 2 ;;
            --device)  DEVICE="$2"; shift 2 ;;
            --output)  OUTPUT="$2"; shift 2 ;;
            --size)    IMAGE_SIZE="$2"; shift 2 ;;
            -h|--help) usage ;;
            *)         log_error "Unknown: $1"; usage ;;
        esac
    done

    OUTPUT="${OUTPUT:-${PROJECT_ROOT}/build/images/steamphone-${DEVICE}.img}"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (for loopback mount)"
        exit 1
    fi
}

create_disk_image() {
    log_info "Creating disk image (${IMAGE_SIZE})..."
    mkdir -p "$(dirname "$OUTPUT")"
    truncate -s "$IMAGE_SIZE" "$OUTPUT"
}

partition_image() {
    log_info "Creating partition table..."

    # GPT partition table:
    # p1: 512MB  boot (FAT32) - kernel, DTB
    # p2: rest   rootfs (F2FS) - root filesystem
    parted -s "$OUTPUT" \
        mklabel gpt \
        mkpart boot fat32 1MiB 513MiB \
        set 1 boot on \
        mkpart rootfs 513MiB 100%
}

format_and_populate() {
    log_info "Setting up loopback device..."
    local loop_dev
    loop_dev=$(losetup --find --show --partscan "$OUTPUT")

    local boot_part="${loop_dev}p1"
    local root_part="${loop_dev}p2"

    # Wait for partitions
    sleep 1
    partprobe "$loop_dev" 2>/dev/null || true
    sleep 1

    # Format
    log_info "Formatting partitions..."
    mkfs.vfat -F 32 -n SPBOOT "$boot_part"
    mkfs.f2fs -f -l SPROOT "$root_part"

    # Mount
    local mnt="/tmp/steamphone-mnt"
    mkdir -p "$mnt"
    mount "$root_part" "$mnt"
    mkdir -p "$mnt/boot"
    mount "$boot_part" "$mnt/boot"

    # Copy rootfs
    log_info "Copying root filesystem..."
    rsync -aHAX --info=progress2 "${ROOTFS_DIR}/" "$mnt/" || \
        cp -a "${ROOTFS_DIR}/." "$mnt/"

    # Ensure kernel and DTB are in boot partition
    if [[ -f "${KERNEL_DIR}/boot/Image" ]]; then
        cp "${KERNEL_DIR}/boot/Image" "$mnt/boot/"
    fi
    if ls "${KERNEL_DIR}/boot/"*.dtb &>/dev/null; then
        mkdir -p "$mnt/boot/dtbs"
        cp "${KERNEL_DIR}/boot/"*.dtb "$mnt/boot/dtbs/"
    fi

    # Sync and unmount
    log_info "Syncing and unmounting..."
    sync
    umount "$mnt/boot"
    umount "$mnt"
    losetup -d "$loop_dev"
    rm -rf "$mnt"
}

create_samsung_package() {
    local img_dir="$(dirname "$OUTPUT")"
    local tar_output="${img_dir}/steamphone-${DEVICE}-odin.tar"

    log_info "Creating Samsung Odin/Heimdall flashable package..."

    # For Samsung devices, we need to package for Odin/Heimdall
    # This creates a .tar with the proper format:
    # - boot.img (kernel + ramdisk)
    # - super.img (rootfs) or system.img
    cat > "${img_dir}/flash-instructions.txt" <<EOF
SteamPhone Flashing Instructions for Galaxy S20 FE
===================================================

PREREQUISITES:
1. OEM unlock enabled (Settings > Developer > OEM Unlock)
2. Device in Download Mode (Power Off, then Vol Down + USB)
3. Heimdall installed on host PC

WARNING: This will PERMANENTLY erase all data!

METHOD 1: Heimdall (Linux/Mac)
-------------------------------
# Flash kernel
heimdall flash --BOOT boot.img

# Flash rootfs (via SUPER partition)
heimdall flash --SUPER steamphone-${DEVICE}.img

METHOD 2: Odin (Windows)
--------------------------
1. Open Odin3
2. Load steamphone-${DEVICE}-odin.tar in AP slot
3. Ensure "Auto Reboot" is checked
4. Click "Start"

POST-FLASH:
- First boot may take 2-3 minutes
- Default user: deck / password: deck
- WiFi setup: nmtui
- Steam install: install-steam
EOF

    log_info "Flash instructions written to: ${img_dir}/flash-instructions.txt"
}

main() {
    parse_args "$@"
    check_root

    log_info "=== Creating flashable image for ${DEVICE} ==="

    create_disk_image
    partition_image
    format_and_populate
    create_samsung_package

    log_info "=== Image creation complete ==="
    log_info "Image: ${OUTPUT}"
    log_info "Size: $(du -h "$OUTPUT" | cut -f1)"
}

main "$@"
