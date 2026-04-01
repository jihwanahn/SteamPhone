# SteamPhone Architecture Overview

## Boot Flow

```
Samsung Bootloader (BL1/BL2)
    ↓
U-Boot / Custom ABL (ARM Trusted Firmware)
    ↓
Linux Kernel 6.6 (Image + DTB)
    ↓
initramfs (mount rootfs, load modules)
    ↓
systemd (PID 1)
    ↓
seatd → steamphone-session.service
    ↓
Gamescope (Wayland compositor)
    ↓
Box64 → Steam Client (Game Mode UI)
```

## Component Map

### 1. Bootloader Layer
Samsung Galaxy S20 FE uses Samsung's proprietary secure boot chain.
With OEM unlock, we can replace the boot and system partitions.

**Exynos 990 (SM-G780F):**
- BL1 → BL2 → U-Boot (custom) → Linux
- Uses Samsung's proprietary partition table
- Flash via Heimdall/Odin (Download Mode)

**Snapdragon 865 (SM-G780G):**
- PBL → XBL → ABL → Linux
- Uses GPT partition table
- Flash via Heimdall/Odin (Download Mode)

### 2. Kernel Layer
Mainline Linux 6.6.x with device-specific patches:
- Device Tree (DTB) for S20 FE hardware mapping
- Display panel driver (Samsung S6E3FC3 AMOLED)
- Touchscreen driver (Samsung SEC_TS)
- Power management (PMIC, charger, fuel gauge)
- Wireless (WiFi, BT, cellular modem)

### 3. Graphics Stack

```
Steam / Games
    ↓
Gamescope (Wayland compositor + frame limiter)
    ↓
Vulkan / OpenGL ES
    ↓
Mesa (Panfrost for Mali-G77 / Freedreno for Adreno 650)
    ↓
DRM/KMS (kernel)
    ↓
Display panel (Samsung AMOLED 6.5" FHD+ 120Hz)
```

### 4. x86 Translation
Steam client is x86_64 only. We use:
- **Box64**: x86_64 → ARM64 dynamic translation
- **Box86**: x86 → ARM32 translation (for 32-bit libraries)
- Wrap OpenGL calls to native ARM GPU drivers

### 5. Input System

```
Touchscreen (hardware)
    ↓
evdev (kernel input subsystem)
    ↓
steamphone-gamepad (Python/uinput)
    ↓
Virtual Xbox Controller (/dev/input/jsX)
    ↓
Steam Input API
```

### 6. Audio

```
Game audio
    ↓
PipeWire (sound server)
    ↓
ALSA (kernel)
    ↓
SoC audio codec
    ↓
Speaker / 3.5mm jack / Bluetooth
```

## Partition Layout

```
mmcblk0
├── p1  boot    512MB   FAT32   Kernel Image + DTBs
├── p2  rootfs  ~120GB  F2FS    Arch Linux ARM + SteamOS
└── (Samsung bootloader partitions preserved)
```

## Key Technical Challenges

1. **GPU drivers**: Panfrost (Mali) has good but incomplete Vulkan support.
   Freedreno (Adreno) has better Vulkan via turnip. Game compatibility varies.

2. **Steam client**: Box64 translation adds overhead. Not all Steam features
   work perfectly under translation.

3. **Display**: Need to handle 120Hz AMOLED panel, HDR, and portrait→landscape
   rotation for gaming.

4. **Thermals**: Phone form factor has limited cooling. Need aggressive
   thermal management and clock throttling.

5. **Battery**: 4500mAh battery. Heavy gaming will drain quickly.
   Need power profile management.

6. **Modem**: Linux cellular modem support for Exynos is limited.
   WiFi-only mode is the practical default.
