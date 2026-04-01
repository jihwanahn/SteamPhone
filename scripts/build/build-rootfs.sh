#!/usr/bin/env bash
# SteamPhone - Root Filesystem Build Script
# Creates an Arch Linux ARM root filesystem with SteamOS overlay.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Defaults
DEVICE="exynos990"
GPU_DRIVER="panfrost"
KERNEL_DIR="${PROJECT_ROOT}/build/kernel"
OUTPUT_DIR="${PROJECT_ROOT}/build/rootfs"
ALARM_URL="http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[ROOTFS]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[ROOTFS]${NC} $*"; }
log_error() { echo -e "${RED}[ROOTFS]${NC} $*"; }

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
    --device DEVICE       Target device (default: exynos990)
    --kernel DIR          Kernel build directory
    --gpu-driver DRIVER   GPU driver: panfrost or freedreno (default: panfrost)
    --output DIR          Output directory (default: build/rootfs)
    -h, --help            Show this help
EOF
    exit 0
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --device)      DEVICE="$2"; shift 2 ;;
            --kernel)      KERNEL_DIR="$2"; shift 2 ;;
            --gpu-driver)  GPU_DRIVER="$2"; shift 2 ;;
            --output)      OUTPUT_DIR="$2"; shift 2 ;;
            -h|--help)     usage ;;
            *)             log_error "Unknown option: $1"; usage ;;
        esac
    done
}

download_alarm() {
    local tarball="${OUTPUT_DIR}/alarm-base.tar.gz"
    if [[ -f "$tarball" ]]; then
        log_info "Arch Linux ARM tarball already downloaded"
        return
    fi
    log_info "Downloading Arch Linux ARM (aarch64)..."
    mkdir -p "$OUTPUT_DIR"
    wget -q --show-progress -O "$tarball" "$ALARM_URL"
}

create_rootfs() {
    local rootfs="${OUTPUT_DIR}/root"
    local tarball="${OUTPUT_DIR}/alarm-base.tar.gz"

    if [[ -d "$rootfs/etc" ]]; then
        log_info "Rootfs already extracted"
        return
    fi

    log_info "Extracting Arch Linux ARM rootfs..."
    mkdir -p "$rootfs"
    bsdtar -xpf "$tarball" -C "$rootfs" 2>/dev/null || \
        tar -xzf "$tarball" -C "$rootfs"
}

install_kernel() {
    local rootfs="${OUTPUT_DIR}/root"

    log_info "Installing custom kernel..."

    # Install kernel image
    if [[ -f "${KERNEL_DIR}/boot/Image" ]]; then
        cp "${KERNEL_DIR}/boot/Image" "${rootfs}/boot/"
        log_info "Kernel image installed"
    else
        log_warn "No kernel image found at ${KERNEL_DIR}/boot/Image"
    fi

    # Install DTB files
    if ls "${KERNEL_DIR}/boot/"*.dtb &>/dev/null; then
        mkdir -p "${rootfs}/boot/dtbs"
        cp "${KERNEL_DIR}/boot/"*.dtb "${rootfs}/boot/dtbs/"
        log_info "Device tree blobs installed"
    fi

    # Install kernel modules
    if [[ -d "${KERNEL_DIR}/modules/lib/modules" ]]; then
        cp -a "${KERNEL_DIR}/modules/lib/modules/"* "${rootfs}/lib/modules/" 2>/dev/null || true
        log_info "Kernel modules installed"
    fi
}

configure_base_system() {
    local rootfs="${OUTPUT_DIR}/root"

    log_info "Configuring base system..."

    # Hostname
    echo "steamphone" > "${rootfs}/etc/hostname"

    # Hosts
    cat > "${rootfs}/etc/hosts" <<EOF
127.0.0.1   localhost
127.0.1.1   steamphone
::1         localhost
EOF

    # Locale
    echo "en_US.UTF-8 UTF-8" > "${rootfs}/etc/locale.gen"

    # Timezone
    ln -sf /usr/share/zoneinfo/UTC "${rootfs}/etc/localtime"

    # fstab - basic setup (will be adjusted per-device)
    cat > "${rootfs}/etc/fstab" <<EOF
# SteamPhone fstab
# <device>    <mount>   <type>   <options>                <dump> <pass>
/dev/mmcblk0p2  /        f2fs     defaults,noatime         0      1
/dev/mmcblk0p1  /boot    vfat     defaults                 0      2
tmpfs           /tmp     tmpfs    defaults,nosuid,nodev    0      0
EOF

    # Default user: deck (matching SteamOS convention)
    cat > "${rootfs}/tmp/setup-users.sh" <<'CHROOT_SCRIPT'
#!/bin/bash
# Generate locale
locale-gen 2>/dev/null || true
# Create deck user (SteamOS convention)
useradd -m -G wheel,audio,video,input,network -s /bin/bash deck 2>/dev/null || true
echo "deck:deck" | chpasswd
# Enable sudo for wheel
echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/wheel
# Lock root password
passwd -l root
CHROOT_SCRIPT
    chmod +x "${rootfs}/tmp/setup-users.sh"
}

install_steamos_overlay() {
    local rootfs="${OUTPUT_DIR}/root"
    local overlay="${PROJECT_ROOT}/rootfs/steamos-overlay"

    log_info "Installing SteamOS overlay packages and configs..."

    # Package list for SteamOS-like experience
    cat > "${rootfs}/tmp/install-packages.sh" <<'CHROOT_SCRIPT'
#!/bin/bash
set -e

# Initialize pacman keyring
pacman-key --init
pacman-key --populate archlinuxarm

# Update system
pacman -Syu --noconfirm

# Core desktop packages
pacman -S --noconfirm --needed \
    wayland \
    wlroots \
    xorg-xwayland \
    mesa \
    vulkan-tools \
    libinput \
    seatd \
    pipewire \
    pipewire-pulse \
    pipewire-alsa \
    wireplumber \
    dbus \
    polkit \
    networkmanager \
    bluez \
    bluez-utils

# Development tools (needed for building gamescope etc.)
pacman -S --noconfirm --needed \
    base-devel \
    cmake \
    meson \
    ninja \
    git \
    python

# Gaming dependencies
pacman -S --noconfirm --needed \
    sdl2 \
    sdl2_image \
    sdl2_ttf \
    lib32-glibc \
    mangohud

# System utilities
pacman -S --noconfirm --needed \
    htop \
    vim \
    openssh \
    iwd \
    zsh

# Enable services
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable sshd
systemctl enable seatd

echo "SteamOS overlay packages installed"
CHROOT_SCRIPT
    chmod +x "${rootfs}/tmp/install-packages.sh"

    # Copy overlay files (configs, systemd units, etc.)
    if [[ -d "$overlay" ]]; then
        cp -a "$overlay/." "${rootfs}/"
        log_info "Overlay files copied"
    fi
}

install_gpu_driver() {
    local rootfs="${OUTPUT_DIR}/root"

    log_info "Configuring GPU driver: ${GPU_DRIVER}..."

    cat > "${rootfs}/tmp/install-gpu.sh" <<CHROOT_SCRIPT
#!/bin/bash
set -e
case "${GPU_DRIVER}" in
    panfrost)
        # Mali-G77 via Panfrost (Mesa)
        pacman -S --noconfirm --needed mesa mesa-utils
        # Panfrost is included in Mesa by default on ARM
        echo "Panfrost GPU driver configured"
        ;;
    freedreno)
        # Adreno 650 via Freedreno (Mesa)
        pacman -S --noconfirm --needed mesa mesa-utils
        # Freedreno is included in Mesa by default on ARM
        echo "Freedreno GPU driver configured"
        ;;
esac
CHROOT_SCRIPT
    chmod +x "${rootfs}/tmp/install-gpu.sh"
}

configure_steamphone_services() {
    local rootfs="${OUTPUT_DIR}/root"

    log_info "Setting up SteamPhone systemd services..."

    # Auto-login to deck user
    mkdir -p "${rootfs}/etc/systemd/system/getty@tty1.service.d"
    cat > "${rootfs}/etc/systemd/system/getty@tty1.service.d/autologin.conf" <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin deck --noclear %I \$TERM
EOF

    # Gamescope session launcher
    mkdir -p "${rootfs}/usr/local/bin"
    cat > "${rootfs}/usr/local/bin/steamphone-session" <<'EOF'
#!/bin/bash
# SteamPhone Session Launcher
# Starts Gamescope with Steam in Game Mode

export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export WLR_BACKENDS=drm
export WLR_DRM_NO_ATOMIC=1
export MANGOHUD=1

# Wait for display
sleep 2

# Launch Gamescope with Steam
exec gamescope \
    --fullscreen \
    --adaptive-sync \
    --xwayland-count 2 \
    -W 1080 -H 2400 \
    -r 120 \
    -- steam -steamos3 -gamepadui
EOF
    chmod +x "${rootfs}/usr/local/bin/steamphone-session"

    # Systemd service for SteamPhone session
    cat > "${rootfs}/etc/systemd/system/steamphone-session.service" <<EOF
[Unit]
Description=SteamPhone Gaming Session
After=graphical.target seatd.service
Wants=seatd.service

[Service]
User=deck
PAMName=login
Environment=XDG_SESSION_TYPE=wayland
ExecStart=/usr/local/bin/steamphone-session
Restart=on-failure
RestartSec=3

[Install]
WantedBy=graphical.target
EOF

    # Power button handler
    cat > "${rootfs}/usr/local/bin/steamphone-power" <<'EOF'
#!/bin/bash
# Handle power button press - suspend device
systemctl suspend
EOF
    chmod +x "${rootfs}/usr/local/bin/steamphone-power"
}

run_chroot_scripts() {
    local rootfs="${OUTPUT_DIR}/root"

    if ! command -v qemu-aarch64-static &>/dev/null; then
        log_warn "qemu-aarch64-static not found. Skipping chroot setup."
        log_warn "Run setup-host.sh first, or execute chroot scripts manually on ARM device."
        return
    fi

    log_info "Running chroot configuration scripts..."

    # Mount required filesystems
    mount --bind /proc "${rootfs}/proc" 2>/dev/null || true
    mount --bind /sys  "${rootfs}/sys"  2>/dev/null || true
    mount --bind /dev  "${rootfs}/dev"  2>/dev/null || true

    # Copy qemu binary
    cp "$(which qemu-aarch64-static)" "${rootfs}/usr/bin/" 2>/dev/null || true

    # Run scripts in chroot
    for script in setup-users.sh install-packages.sh install-gpu.sh; do
        if [[ -f "${rootfs}/tmp/${script}" ]]; then
            log_info "Running chroot: ${script}"
            chroot "${rootfs}" "/tmp/${script}" || log_warn "Script ${script} failed (may need real hardware)"
        fi
    done

    # Cleanup
    umount "${rootfs}/proc" 2>/dev/null || true
    umount "${rootfs}/sys"  2>/dev/null || true
    umount "${rootfs}/dev"  2>/dev/null || true
    rm -f "${rootfs}/usr/bin/qemu-aarch64-static"
    rm -f "${rootfs}/tmp/"*.sh
}

main() {
    parse_args "$@"

    log_info "=== Building rootfs for ${DEVICE} ==="

    download_alarm
    create_rootfs
    install_kernel
    configure_base_system
    install_steamos_overlay
    install_gpu_driver
    configure_steamphone_services
    run_chroot_scripts

    log_info "=== Rootfs build complete ==="
    log_info "Root filesystem: ${OUTPUT_DIR}/root"
}

main "$@"
