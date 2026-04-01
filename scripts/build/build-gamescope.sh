#!/usr/bin/env bash
# SteamPhone - Gamescope Build Script
# Cross-compiles Valve's Gamescope compositor for ARM64.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

CROSS_COMPILE="aarch64-linux-gnu-"
OUTPUT_DIR="${PROJECT_ROOT}/build/gamescope"
GAMESCOPE_REPO="https://github.com/ValveSoftware/gamescope.git"
GAMESCOPE_BRANCH="master"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[GAMESCOPE]${NC} $*"; }
log_error() { echo -e "${RED}[GAMESCOPE]${NC} $*"; }

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
    --cross-compile PREFIX  Cross compiler prefix (default: aarch64-linux-gnu-)
    --output DIR            Output directory
    --branch BRANCH         Gamescope git branch (default: master)
    -h, --help              Show this help
EOF
    exit 0
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --cross-compile) CROSS_COMPILE="$2"; shift 2 ;;
            --output)        OUTPUT_DIR="$2"; shift 2 ;;
            --branch)        GAMESCOPE_BRANCH="$2"; shift 2 ;;
            -h|--help)       usage ;;
            *)               log_error "Unknown: $1"; usage ;;
        esac
    done
}

clone_gamescope() {
    local src_dir="${OUTPUT_DIR}/src"

    if [[ -d "${src_dir}/.git" ]]; then
        log_info "Gamescope source exists, updating..."
        (cd "$src_dir" && git pull --rebase)
        return
    fi

    log_info "Cloning Gamescope (branch: ${GAMESCOPE_BRANCH})..."
    mkdir -p "$OUTPUT_DIR"
    git clone --recursive --branch "$GAMESCOPE_BRANCH" "$GAMESCOPE_REPO" "$src_dir"
}

apply_arm_patches() {
    local src_dir="${OUTPUT_DIR}/src"
    local patch_dir="${PROJECT_ROOT}/gamescope/patches"

    if [[ ! -d "$patch_dir" ]] || [[ -z "$(ls -A "$patch_dir"/*.patch 2>/dev/null)" ]]; then
        log_info "No ARM patches to apply"
        return
    fi

    log_info "Applying ARM64 patches..."
    for patch in "$patch_dir"/*.patch; do
        log_info "  Applying: $(basename "$patch")"
        (cd "$src_dir" && git apply "$patch")
    done
}

build_gamescope() {
    local src_dir="${OUTPUT_DIR}/src"
    local build_dir="${OUTPUT_DIR}/build"

    log_info "Configuring Gamescope for ARM64 cross-compilation..."

    # Create cross-compilation meson file
    cat > "${OUTPUT_DIR}/aarch64-cross.ini" <<EOF
[binaries]
c = '${CROSS_COMPILE}gcc'
cpp = '${CROSS_COMPILE}g++'
ar = '${CROSS_COMPILE}ar'
strip = '${CROSS_COMPILE}strip'
pkgconfig = 'pkg-config'

[host_machine]
system = 'linux'
cpu_family = 'aarch64'
cpu = 'cortex-a76'
endian = 'little'

[properties]
needs_exe_wrapper = true
EOF

    # Configure with meson
    meson setup "$build_dir" "$src_dir" \
        --cross-file "${OUTPUT_DIR}/aarch64-cross.ini" \
        --prefix=/usr \
        --buildtype=release \
        -Dpipewire=disabled \
        -Dforce_fallback_for=stb,wlroots,libliftoff,vkroots,glm,reshade,libpipewire

    # Build
    log_info "Building Gamescope..."
    ninja -C "$build_dir"

    # Stage install
    log_info "Staging install..."
    DESTDIR="${OUTPUT_DIR}/install" ninja -C "$build_dir" install

    log_info "Gamescope built successfully"
}

main() {
    parse_args "$@"

    log_info "=== Building Gamescope for ARM64 ==="

    clone_gamescope
    apply_arm_patches
    build_gamescope

    log_info "=== Gamescope build complete ==="
    log_info "Staged files: ${OUTPUT_DIR}/install/"
}

main "$@"
