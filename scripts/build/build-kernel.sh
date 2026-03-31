#!/usr/bin/env bash
# SteamPhone - Kernel Build Script
# Downloads, patches, configures, and builds the Linux kernel for Galaxy S20 FE.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Defaults
DEVICE="exynos990"
CROSS_COMPILE="aarch64-linux-gnu-"
KERNEL_VER="6.6.10"
KERNEL_MAJOR="6.6"
OUTPUT_DIR="${PROJECT_ROOT}/build/kernel"
JOBS="$(nproc)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[KERNEL]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[KERNEL]${NC} $*"; }
log_error() { echo -e "${RED}[KERNEL]${NC} $*"; }

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
    --device DEVICE       Target device: exynos990 or sd865 (default: exynos990)
    --cross-compile PREFIX Cross compiler prefix (default: aarch64-linux-gnu-)
    --defconfig CONFIG    Kernel defconfig name
    --output DIR          Output directory (default: build/kernel)
    --jobs N              Parallel build jobs (default: nproc)
    -h, --help            Show this help
EOF
    exit 0
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --device)       DEVICE="$2"; shift 2 ;;
            --cross-compile) CROSS_COMPILE="$2"; shift 2 ;;
            --defconfig)    DEFCONFIG="$2"; shift 2 ;;
            --output)       OUTPUT_DIR="$2"; shift 2 ;;
            --jobs)         JOBS="$2"; shift 2 ;;
            -h|--help)      usage ;;
            *)              log_error "Unknown option: $1"; usage ;;
        esac
    done

    # Set device-specific defaults
    case "$DEVICE" in
        exynos990)
            DEFCONFIG="${DEFCONFIG:-steamphone_exynos990_defconfig}"
            DTB_TARGET="exynos990-s20fe"
            ;;
        sd865)
            DEFCONFIG="${DEFCONFIG:-steamphone_sd865_defconfig}"
            DTB_TARGET="sm8250-s20fe"
            ;;
        *)
            log_error "Unknown device: $DEVICE"
            exit 1
            ;;
    esac
}

download_kernel() {
    local src_dir="${OUTPUT_DIR}/linux-${KERNEL_VER}"
    local tarball="linux-${KERNEL_VER}.tar.xz"
    local url="https://cdn.kernel.org/pub/linux/kernel/v6.x/${tarball}"

    if [[ -d "$src_dir" ]]; then
        log_info "Kernel source already exists: $src_dir"
        return
    fi

    log_info "Downloading Linux ${KERNEL_VER}..."
    mkdir -p "$OUTPUT_DIR"
    wget -q --show-progress -O "${OUTPUT_DIR}/${tarball}" "$url"

    log_info "Extracting..."
    tar -xf "${OUTPUT_DIR}/${tarball}" -C "$OUTPUT_DIR"
    rm -f "${OUTPUT_DIR}/${tarball}"
}

apply_patches() {
    local src_dir="${OUTPUT_DIR}/linux-${KERNEL_VER}"
    local patch_dir="${PROJECT_ROOT}/kernel/patches"
    local device_patches="${patch_dir}/${DEVICE}"
    local common_patches="${patch_dir}/common"

    # Apply common patches first
    if [[ -d "$common_patches" ]]; then
        log_info "Applying common kernel patches..."
        for patch in "$common_patches"/*.patch; do
            [[ -f "$patch" ]] || continue
            log_info "  Applying: $(basename "$patch")"
            (cd "$src_dir" && git apply "$patch" 2>/dev/null || patch -p1 < "$patch")
        done
    fi

    # Apply device-specific patches
    if [[ -d "$device_patches" ]]; then
        log_info "Applying ${DEVICE} kernel patches..."
        for patch in "$device_patches"/*.patch; do
            [[ -f "$patch" ]] || continue
            log_info "  Applying: $(basename "$patch")"
            (cd "$src_dir" && git apply "$patch" 2>/dev/null || patch -p1 < "$patch")
        done
    fi
}

configure_kernel() {
    local src_dir="${OUTPUT_DIR}/linux-${KERNEL_VER}"
    local config_src="${PROJECT_ROOT}/kernel/configs/${DEFCONFIG}"

    log_info "Configuring kernel with ${DEFCONFIG}..."

    # Copy our defconfig
    cp "$config_src" "${src_dir}/arch/arm64/configs/${DEFCONFIG}"

    make -C "$src_dir" \
        ARCH=arm64 \
        CROSS_COMPILE="$CROSS_COMPILE" \
        "$DEFCONFIG"
}

build_kernel() {
    local src_dir="${OUTPUT_DIR}/linux-${KERNEL_VER}"

    log_info "Building kernel (${JOBS} jobs)..."
    make -C "$src_dir" \
        ARCH=arm64 \
        CROSS_COMPILE="$CROSS_COMPILE" \
        -j"$JOBS" \
        Image dtbs modules

    log_info "Installing modules..."
    make -C "$src_dir" \
        ARCH=arm64 \
        CROSS_COMPILE="$CROSS_COMPILE" \
        INSTALL_MOD_PATH="${OUTPUT_DIR}/modules" \
        modules_install

    # Copy outputs
    log_info "Copying build artifacts..."
    mkdir -p "${OUTPUT_DIR}/boot"
    cp "${src_dir}/arch/arm64/boot/Image" "${OUTPUT_DIR}/boot/"

    # Copy device tree
    local dtb_path
    dtb_path=$(find "${src_dir}/arch/arm64/boot/dts" -name "${DTB_TARGET}*.dtb" 2>/dev/null | head -1)
    if [[ -n "$dtb_path" ]]; then
        cp "$dtb_path" "${OUTPUT_DIR}/boot/"
        log_info "DTB: $(basename "$dtb_path")"
    else
        log_warn "No DTB found for ${DTB_TARGET}. You may need to create one."
    fi
}

main() {
    parse_args "$@"

    log_info "=== Building kernel for ${DEVICE} ==="
    log_info "Kernel version: ${KERNEL_VER}"
    log_info "Cross compiler: ${CROSS_COMPILE}"
    log_info "Output: ${OUTPUT_DIR}"

    download_kernel
    apply_patches
    configure_kernel
    build_kernel

    log_info "=== Kernel build complete ==="
    log_info "Image: ${OUTPUT_DIR}/boot/Image"
    log_info "Modules: ${OUTPUT_DIR}/modules/"
}

main "$@"
