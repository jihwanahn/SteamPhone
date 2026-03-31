#!/usr/bin/env bash
# SteamPhone - Box64/Box86 Build Script
# Builds x86/x86_64 translation layers needed to run Steam client on ARM.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

CROSS_COMPILE="aarch64-linux-gnu-"
OUTPUT_DIR="${PROJECT_ROOT}/build/steam"
BOX64_REPO="https://github.com/ptitSeb/box64.git"
BOX86_REPO="https://github.com/ptitSeb/box86.git"

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[STEAM]${NC} $*"; }
log_error() { echo -e "${RED}[STEAM]${NC} $*"; }

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
    --cross-compile PREFIX  Cross compiler prefix
    --output DIR            Output directory
    -h, --help              Show this help
EOF
    exit 0
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --cross-compile) CROSS_COMPILE="$2"; shift 2 ;;
            --output)        OUTPUT_DIR="$2"; shift 2 ;;
            -h|--help)       usage ;;
            *)               log_error "Unknown: $1"; usage ;;
        esac
    done
}

build_box64() {
    local src_dir="${OUTPUT_DIR}/box64-src"
    local build_dir="${OUTPUT_DIR}/box64-build"

    if [[ ! -d "${src_dir}/.git" ]]; then
        log_info "Cloning Box64..."
        git clone "$BOX64_REPO" "$src_dir"
    fi

    log_info "Building Box64 (x86_64 -> ARM64 translation)..."
    mkdir -p "$build_dir"

    cmake -B "$build_dir" -S "$src_dir" \
        -DCMAKE_C_COMPILER="${CROSS_COMPILE}gcc" \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DARM_DYNAREC=ON \
        -DCMAKE_INSTALL_PREFIX=/usr

    cmake --build "$build_dir" -j"$(nproc)"

    DESTDIR="${OUTPUT_DIR}/install" cmake --install "$build_dir"

    log_info "Box64 built successfully"
}

build_box86() {
    local src_dir="${OUTPUT_DIR}/box86-src"
    local build_dir="${OUTPUT_DIR}/box86-build"

    if [[ ! -d "${src_dir}/.git" ]]; then
        log_info "Cloning Box86..."
        git clone "$BOX86_REPO" "$src_dir"
    fi

    log_info "Building Box86 (x86 -> ARM translation)..."
    mkdir -p "$build_dir"

    cmake -B "$build_dir" -S "$src_dir" \
        -DCMAKE_C_COMPILER="${CROSS_COMPILE}gcc" \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DARM_DYNAREC=ON \
        -DCMAKE_INSTALL_PREFIX=/usr

    cmake --build "$build_dir" -j"$(nproc)"

    DESTDIR="${OUTPUT_DIR}/install" cmake --install "$build_dir"

    log_info "Box86 built successfully"
}

create_steam_installer() {
    local install_dir="${OUTPUT_DIR}/install"

    log_info "Creating Steam client installer script..."

    mkdir -p "${install_dir}/usr/local/bin"
    cat > "${install_dir}/usr/local/bin/install-steam" <<'EOF'
#!/bin/bash
# SteamPhone - Steam Client Installer
# Installs Steam via Box64 on ARM64

set -e

STEAM_DIR="$HOME/.steam"

echo "=== Installing Steam Client on SteamPhone ==="

# Verify Box64 is installed
if ! command -v box64 &>/dev/null; then
    echo "Error: box64 not found. Install it first."
    exit 1
fi

# Download Steam bootstrap
mkdir -p "$STEAM_DIR"
cd "$STEAM_DIR"

if [[ ! -f "steam.sh" ]]; then
    echo "Downloading Steam bootstrap..."
    wget -q "https://cdn.cloudflare.steamstatic.com/client/installer/steam.deb" -O /tmp/steam.deb
    ar x /tmp/steam.deb data.tar.xz
    tar xf data.tar.xz --strip-components=3 ./usr/lib/steam/
    rm -f data.tar.xz /tmp/steam.deb
fi

echo "Steam installed to $STEAM_DIR"
echo "Launch with: box64 ~/.steam/steam.sh -steamos3 -gamepadui"
EOF
    chmod +x "${install_dir}/usr/local/bin/install-steam"

    # Box64 configuration for Steam
    mkdir -p "${install_dir}/etc/box64.box64rc.d"
    cat > "${install_dir}/etc/box64.box64rc.d/steam.box64rc" <<'EOF'
# Box64 configuration optimized for Steam on SteamPhone
[steam]
BOX64_DYNAREC=1
BOX64_DYNAREC_BIGBLOCK=2
BOX64_DYNAREC_STRONGMEM=1
BOX64_DYNAREC_FASTNAN=1
BOX64_LOG=0

[steamwebhelper]
BOX64_DYNAREC=1
BOX64_DYNAREC_BIGBLOCK=1
BOX64_LOG=0
BOX64_MALLOC_HACK=2
EOF
}

main() {
    parse_args "$@"
    mkdir -p "$OUTPUT_DIR"

    log_info "=== Building Steam translation layer ==="

    build_box64
    build_box86
    create_steam_installer

    log_info "=== Steam integration complete ==="
    log_info "Staged files: ${OUTPUT_DIR}/install/"
}

main "$@"
