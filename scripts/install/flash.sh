#!/usr/bin/env bash
# SteamPhone - Device Flasher
# Flashes SteamPhone image to Galaxy S20 FE via Heimdall.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

IMAGE=""
DEVICE="exynos990"
DRY_RUN=false

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[FLASH]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[FLASH]${NC} $*"; }
log_error() { echo -e "${RED}[FLASH]${NC} $*"; }

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
    --image FILE    Path to flashable image
    --device DEV    Target device (exynos990 or sd865)
    --dry-run       Show commands without executing
    -h, --help      Show this help

IMPORTANT: Device must be in Download Mode!
  1. Power off the device completely
  2. Hold Volume Down + USB cable insert
  3. Accept the warning screen
EOF
    exit 0
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --image)    IMAGE="$2"; shift 2 ;;
            --device)   DEVICE="$2"; shift 2 ;;
            --dry-run)  DRY_RUN=true; shift ;;
            -h|--help)  usage ;;
            *)          log_error "Unknown: $1"; usage ;;
        esac
    done

    IMAGE="${IMAGE:-${PROJECT_ROOT}/build/images/steamphone-${DEVICE}.img}"

    if [[ ! -f "$IMAGE" ]]; then
        log_error "Image not found: $IMAGE"
        log_error "Build first with: make image DEVICE=${DEVICE}"
        exit 1
    fi
}

check_prerequisites() {
    log_info "Checking prerequisites..."

    if ! command -v heimdall &>/dev/null; then
        log_error "Heimdall not found. Install with: sudo apt install heimdall-flash"
        exit 1
    fi

    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (for USB access)"
        exit 1
    fi
}

detect_device() {
    log_info "Detecting device in Download Mode..."

    if ! heimdall detect 2>/dev/null; then
        log_error "No Samsung device detected in Download Mode."
        echo ""
        echo "To enter Download Mode:"
        echo "  1. Power off the device"
        echo "  2. Hold Volume Down"
        echo "  3. Connect USB cable"
        echo "  4. Accept the warning (Volume Up)"
        exit 1
    fi

    log_info "Device detected!"

    # Print partition table info
    log_info "Reading partition table (PIT)..."
    heimdall print-pit 2>/dev/null | head -50 || true
}

confirm_flash() {
    echo ""
    echo -e "${RED}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  WARNING: THIS WILL ERASE ALL DATA ON DEVICE!   ║${NC}"
    echo -e "${RED}║  THIS IS IRREVERSIBLE. THE ORIGINAL ANDROID OS  ║${NC}"
    echo -e "${RED}║  WILL BE PERMANENTLY REMOVED.                   ║${NC}"
    echo -e "${RED}╠══════════════════════════════════════════════════╣${NC}"
    echo -e "${RED}║  Device: Galaxy S20 FE (${DEVICE})           ║${NC}"
    echo -e "${RED}║  Image:  $(basename "$IMAGE")$(printf '%*s' $((27 - ${#IMAGE})) '')║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════╝${NC}"
    echo ""

    read -rp "Type 'FLASH' to confirm: " confirm
    if [[ "$confirm" != "FLASH" ]]; then
        log_info "Aborted by user."
        exit 0
    fi
}

flash_device() {
    log_info "Starting flash process..."

    local boot_img="${PROJECT_ROOT}/build/kernel/boot/Image"

    # Phase 1: Flash kernel/boot partition
    if [[ -f "$boot_img" ]]; then
        log_info "Phase 1/2: Flashing boot partition..."
        if [[ "$DRY_RUN" == true ]]; then
            echo "[DRY RUN] heimdall flash --BOOT $boot_img"
        else
            heimdall flash --BOOT "$boot_img" --no-reboot
            sleep 2
        fi
    fi

    # Phase 2: Flash rootfs to SUPER/SYSTEM partition
    log_info "Phase 2/2: Flashing rootfs (this may take several minutes)..."
    if [[ "$DRY_RUN" == true ]]; then
        echo "[DRY RUN] heimdall flash --SUPER $IMAGE"
    else
        heimdall flash --SUPER "$IMAGE"
    fi

    log_info "Flash complete! Device will reboot."
    echo ""
    log_info "First boot:"
    log_info "  - May take 2-3 minutes"
    log_info "  - Default login: deck / deck"
    log_info "  - Configure WiFi: nmtui"
    log_info "  - Install Steam: install-steam"
}

main() {
    parse_args "$@"

    log_info "=== SteamPhone Device Flasher ==="

    check_prerequisites
    detect_device
    confirm_flash
    flash_device

    log_info "=== Done! ==="
}

main "$@"
