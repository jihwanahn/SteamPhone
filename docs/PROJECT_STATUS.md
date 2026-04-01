# SteamPhone Project Status

**Last Updated:** 2026-03-31
**Target Device:** Samsung Galaxy S20 FE 5G (SM-G781N) - Snapdragon 865
**Base OS:** SteamOS (Arch Linux ARM)

---

## Project Overview

SteamPhone transforms Samsung Galaxy S20 FE into a SteamOS-powered handheld gaming device.

## Current Status

### ✅ Completed Components

| Component | Status | Notes |
|-----------|--------|-------|
| **Kernel Config** | Done | `steamphone_sd865_defconfig` for SM8250 |
| **Device Tree** | Done | `sm8250-s20fe.dts` for SM-G781N |
| **Kernel Patches (stubs)** | Done | 5 patch files for common + sd865 |
| **Rootfs Build Script** | Done | Full ALARM + SteamOS overlay |
| **Package Lists** | Done | gaming, desktop, network, development |
| **GPU Configuration** | Done | Freedreno/Mesa for Adreno 650 |
| **Driver Documentation** | Done | WiFi, BT, Audio, Touch, Sensors, Modem |
| **Input System (stub)** | Done | Touchscreen gamepad overlay |
| **Gamescope Build Script** | Done | ARM64 cross-compilation |
| **Box64/Box86 Build Script** | Done | Steam translation layer |
| **SteamOS Overlay** | Done | systemd services, init scripts |
| **Documentation** | Done | contributing, troubleshooting |
| **CI/CD** | Done | GitHub Actions workflow |
| **README** | Done | Updated with SM-G781N |

### ⚠️ Incomplete / Needs Testing

| Component | Status | Priority |
|-----------|--------|----------|
| **Actual Kernel Build** | Not Tested | HIGH |
| **Device Tree Compilation** | Not Tested | HIGH |
| **Gamescope ARM Compilation** | Not Tested | HIGH |
| **Box64/Box86 Build** | Not Tested | HIGH |
| **Actual Rootfs Creation** | Not Tested | HIGH |
| **Flash to Device** | Not Tested | HIGH |
| **Real Hardware Boot** | Not Tested | CRITICAL |
| **WiFi/BT Firmware** | Need Files | HIGH |
| **Audio Driver** | Stub Only | MEDIUM |
| **Touch Input** | Stub Only | MEDIUM |

### ❌ Not Started

- Actual hardware testing (no device available)
- Firmware binary files (WiFi, BT)
- Kernel mainline upstreaming
- Real driver implementation

---

## Repository Structure

```
SteamPhone/
├── kernel/
│   ├── configs/           # Kernel .config files
│   │   ├── steamphone_exynos990_defconfig
│   │   └── steamphone_sd865_defconfig
│   ├── dtb/               # Device tree sources
│   │   ├── sm8250-s20fe.dts
│   │   └── sm8250-steamphone-overlay.dts
│   └── patches/           # Kernel patches
│       ├── common/
│       └── sd865/
├── rootfs/
│   ├── base/              # Base system defaults
│   ├── packages/           # Package lists
│   └── steamphone-overlay/ # SteamOS customization
├── drivers/
│   ├── audio/README.md
│   ├── bt/README.md
│   ├── gpu/
│   ├── modem/README.md
│   ├── sensors/README.md
│   ├── touch/README.md
│   └── wifi/README.md
├── gamescope/             # Gamescope compositor
├── steam/                 # Steam + Box64/Box86
├── input/                 # Touchscreen gamepad
│   ├── steamphone-input.sh
│   └── gamepad-layout.json
├── scripts/
│   ├── build/
│   │   ├── build-kernel.sh
│   │   ├── build-rootfs.sh
│   │   ├── build-gamescope.sh
│   │   └── build-box64.sh
│   └── install/
├── tools/
├── docs/
│   ├── architecture/
│   └── guides/
└── ci/
    └── github-actions.yml
```

---

## Build Instructions

```bash
# 1. Setup build environment
./scripts/build/setup-host.sh

# 2. Build kernel
./scripts/build/build-kernel.sh --device sd865

# 3. Build rootfs
./scripts/build/build-rootfs.sh --device sd865

# 4. Build gamescope
./scripts/build/build-gamescope.sh

# 5. Build Box64/Box86
./scripts/build/build-box64.sh

# 6. Create flashable image
./scripts/build/create-image.sh

# 7. Flash to device
./scripts/install/flash.sh --device /dev/ttyUSB0
```

---

## Known Issues

1. **No hardware for testing** - Build artifacts untested on real device
2. **Kernel patches are stubs** - Need real patch content
3. **WiFi/BT firmware missing** - Binary blobs not included (licensing)
4. **Audio driver stub** - May not work without actual ALSA config
5. **Touch gamepad incomplete** - uinput implementation is stub
6. **Samsung partition layout** - super.img handling needs verification

---

## Build System Validation (2026-03-31)

### Scripts Validated
- `build-kernel.sh` ✅ Syntax OK - kernel 6.6.10 download/patch/config/build
- `build-rootfs.sh` ✅ Syntax OK - ALARM + SteamOS overlay
- `build-gamescope.sh` ✅ Syntax OK - meson cross-compilation
- `build-box64.sh` ✅ Syntax OK - Box64/Box86 + Steam installer
- `create-image.sh` ✅ Syntax OK - GPT + F2FS + Odin package
- `flash.sh` ✅ Syntax OK - Heimdall flashing

### Issues Fixed
- ✅ Removed non-existent `steam` package from gaming.txt (Steam via Box64 bootstrap)
- ✅ Added missing GPU config files (panfrost.conf, freedreno.conf)

### Remaining Concerns
- ⚠️ Device tree (sm8250-s20fe.dts) is marked as stub by author
- ⚠️ Kernel patches are stubs, not tested on actual hardware
- ⚠️ gamescope/patches/ empty - relies on upstream ARM support
- ⚠️ Samsung SUPER partition layout may need adjustment

---

## Next Steps

See [TODO.md](./TODO.md) for detailed task list.
