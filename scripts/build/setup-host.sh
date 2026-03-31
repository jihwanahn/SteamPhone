#!/usr/bin/env bash
# SteamPhone - Host Build Environment Setup
# Installs all dependencies needed to build SteamPhone on Ubuntu/Debian host.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (sudo)"
        exit 1
    fi
}

check_distro() {
    if [[ ! -f /etc/os-release ]]; then
        log_error "Cannot determine OS. This script supports Ubuntu/Debian."
        exit 1
    fi
    source /etc/os-release
    case "$ID" in
        ubuntu|debian)
            log_info "Detected: $PRETTY_NAME"
            ;;
        arch|manjaro)
            log_warn "Arch-based system detected. Package names may differ."
            log_warn "Please install equivalents manually if install fails."
            ;;
        *)
            log_error "Unsupported distro: $ID. Use Ubuntu 22.04+ or Debian 12+."
            exit 1
            ;;
    esac
}

install_base_deps() {
    log_info "Installing base build dependencies..."
    apt-get update
    apt-get install -y \
        build-essential \
        gcc-aarch64-linux-gnu \
        g++-aarch64-linux-gnu \
        binutils-aarch64-linux-gnu \
        crossbuild-essential-arm64 \
        bison \
        flex \
        libssl-dev \
        libncurses-dev \
        bc \
        kmod \
        cpio \
        rsync \
        python3 \
        python3-pip \
        device-tree-compiler \
        u-boot-tools \
        lzop \
        git \
        wget \
        curl \
        unzip \
        xz-utils
}

install_rootfs_deps() {
    log_info "Installing rootfs build dependencies..."
    apt-get install -y \
        debootstrap \
        qemu-user-static \
        binfmt-support \
        parted \
        dosfstools \
        e2fsprogs \
        f2fs-tools \
        btrfs-progs \
        mtools \
        arch-install-scripts \
        systemd-container
}

install_graphics_deps() {
    log_info "Installing graphics/Wayland build dependencies..."
    apt-get install -y \
        meson \
        ninja-build \
        cmake \
        pkg-config \
        libdrm-dev \
        libgbm-dev \
        libinput-dev \
        libxkbcommon-dev \
        libpixman-1-dev \
        libcairo2-dev \
        libpango1.0-dev \
        libwayland-dev \
        wayland-protocols \
        glslang-tools \
        libvulkan-dev \
        libx11-xcb-dev \
        libxcb-composite0-dev \
        libxcb-render0-dev \
        libxcb-xfixes0-dev \
        libxcb-xinput-dev \
        libxcb-res0-dev \
        libcap-dev \
        libseat-dev
}

install_flash_deps() {
    log_info "Installing flashing tool dependencies..."
    apt-get install -y \
        heimdall-flash \
        android-tools-adb \
        android-tools-fastboot \
        libusb-1.0-0-dev
}

setup_binfmt() {
    log_info "Setting up binfmt_misc for ARM64 emulation..."
    update-binfmts --enable qemu-aarch64 2>/dev/null || true
    if [[ -f /proc/sys/fs/binfmt_misc/qemu-aarch64 ]]; then
        log_info "ARM64 binfmt_misc is active"
    else
        log_warn "ARM64 binfmt_misc not active. QEMU user emulation may not work."
    fi
}

main() {
    log_info "=== SteamPhone Host Setup ==="
    check_root
    check_distro
    install_base_deps
    install_rootfs_deps
    install_graphics_deps
    install_flash_deps
    setup_binfmt
    log_info "=== Host setup complete! ==="
    log_info "You can now build SteamPhone with: make all DEVICE=exynos990"
}

main "$@"
