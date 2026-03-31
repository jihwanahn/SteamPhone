# SteamPhone

Galaxy S20 FE를 SteamOS 기반 ARM 게이밍 디바이스로 변환하는 프로젝트.

## Overview

SteamPhone은 사용하지 않는 Galaxy S20 FE(SM-G780F/G)에서 Android OS, 커널, 앱을 모두 제거하고,
SteamOS(Arch Linux ARM 기반)로 구동되는 휴대용 Steam 게이밍 디바이스로 변환하는 오픈소스 프로젝트입니다.

## Supported Devices

| Model | SoC | GPU | Status |
|-------|-----|-----|--------|
| SM-G780F | Exynos 990 | Mali-G77 MP11 | Primary target |
| SM-G780G | Snapdragon 865 | Adreno 650 | Secondary target |

## Architecture

```
┌─────────────────────────────────────────────┐
│              Steam Client (x86)             │
│           (via Box64/Box86 translation)      │
├─────────────────────────────────────────────┤
│          Gamescope Compositor (ARM)          │
├─────────────────────────────────────────────┤
│        SteamOS Overlay (packages/config)     │
├─────────────────────────────────────────────┤
│           Arch Linux ARM (base OS)           │
├─────────────────────────────────────────────┤
│    Mesa (Panfrost/Freedreno) + Wayland       │
├─────────────────────────────────────────────┤
│     Linux Kernel 6.x (mainline + patches)    │
├─────────────────────────────────────────────┤
│    Device Drivers (display, touch, audio,    │
│     WiFi, BT, GPU, modem, sensors)           │
├─────────────────────────────────────────────┤
│         Bootloader (U-Boot / custom ABL)     │
├─────────────────────────────────────────────┤
│          Galaxy S20 FE Hardware              │
└─────────────────────────────────────────────┘
```

## Project Structure

```
SteamPhone/
├── kernel/          # Linux kernel configs, patches, DTB
├── rootfs/          # Root filesystem build (Arch ARM + SteamOS)
├── drivers/         # Device-specific driver configs and patches
├── gamescope/       # Gamescope compositor ARM port
├── steam/           # Steam client integration (Box86/Box64)
├── input/           # Touchscreen gamepad overlay
├── tools/           # Flashing and installation tools
├── scripts/         # Build, install, test scripts
├── docs/            # Documentation
└── ci/              # CI/CD configs
```

## Prerequisites

- Galaxy S20 FE with unlocked bootloader (OEM unlock enabled)
- Linux host machine (Ubuntu 22.04+ recommended)
- AArch64 cross-compilation toolchain (`aarch64-linux-gnu-`)
- Heimdall or Odin (for Samsung device flashing)
- At least 50GB free disk space
- USB cable (USB-C)

## Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/jihwanahn/steamphone.git
cd steamphone

# 2. Install build dependencies
./scripts/build/setup-host.sh

# 3. Build the kernel
./scripts/build/build-kernel.sh --device exynos990

# 4. Build the root filesystem
./scripts/build/build-rootfs.sh

# 5. Create flashable image
./scripts/build/create-image.sh

# 6. Flash to device (CAUTION: erases all data!)
./scripts/install/flash.sh --device /dev/ttyUSB0
```

## Build System

The build system uses Make as the top-level orchestrator:

```bash
make all          # Build everything
make kernel       # Build kernel only
make rootfs       # Build rootfs only
make image        # Create flashable image
make clean        # Clean build artifacts
```

## Warning

**This project will permanently erase all data and the original OS on your Galaxy S20 FE.**
There is a risk of bricking your device. Proceed at your own risk.
This project is for educational and experimental purposes only.

## License

GPL-2.0 (kernel components) / MIT (userspace tools and scripts)

## Contributing

Contributions are welcome! See [docs/guides/contributing.md](docs/guides/contributing.md) for details.
