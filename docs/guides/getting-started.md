# Getting Started with SteamPhone

## Step 1: Prepare Your Device

### Enable OEM Unlock
1. Go to **Settings > About Phone**
2. Tap **Build Number** 7 times to enable Developer Options
3. Go to **Settings > Developer Options**
4. Enable **OEM Unlock**
5. Reboot the device

### Enter Download Mode
1. Power off the device completely
2. Hold **Volume Down** while connecting USB cable to PC
3. When warning screen appears, press **Volume Up** to continue
4. Device is now in Download Mode

### Unlock Bootloader (if not already done)
```bash
# Using Heimdall
heimdall flash --repartition --pit samsung-s20fe.pit
```

**WARNING**: Unlocking the bootloader will trigger a factory reset and void warranty.

## Step 2: Set Up Build Environment

### Requirements
- Ubuntu 22.04+ or Debian 12+ (host PC)
- 50GB+ free disk space
- 8GB+ RAM recommended
- Internet connection

### Install Dependencies
```bash
sudo ./scripts/build/setup-host.sh
```

## Step 3: Build SteamPhone

### For Exynos 990 (SM-G780F)
```bash
make all DEVICE=exynos990
```

### For Snapdragon 865 (SM-G780G)
```bash
make all DEVICE=sd865
```

This will:
1. Download and compile Linux kernel 6.6
2. Build Arch Linux ARM root filesystem
3. Install SteamOS overlay packages
4. Build Gamescope for ARM64
5. Build Box64/Box86 translation layers
6. Create a flashable image

### Build Individual Components
```bash
make kernel     # Kernel only
make rootfs     # Root filesystem only
make gamescope  # Gamescope only
make steam      # Box64/Box86 only
make image      # Package into flashable image
```

## Step 4: Flash to Device

Ensure your device is in Download Mode (see Step 1).

```bash
sudo make flash DEVICE=exynos990
```

**THIS WILL ERASE ALL DATA. THIS IS IRREVERSIBLE.**

## Step 5: First Boot

1. Device will reboot automatically after flashing
2. First boot takes 2-3 minutes (filesystem setup)
3. You'll see the SteamPhone boot screen

### Default Credentials
- **Username**: deck
- **Password**: deck

### Initial Setup
```bash
# Connect to WiFi
nmtui

# Install Steam
install-steam

# Start gaming session
steamphone-session
```

## Troubleshooting

### Device doesn't boot
- Re-flash with `--dry-run` first to verify commands
- Check serial console output via USB debug cable
- Try flashing only the kernel: `heimdall flash --BOOT boot.img`

### No display output
- Kernel may not have correct display panel driver
- Check `/var/log/dmesg` after booting via SSH

### WiFi not working
- Check `dmesg | grep wifi` for driver loading
- Firmware files may be missing from `/lib/firmware`

### Steam crashes
- Check Box64 logs: `BOX64_LOG=1 box64 steam`
- Ensure sufficient swap: `swapon -s`
