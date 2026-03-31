# SteamPhone TODO List

**Target:** Samsung Galaxy S20 FE 5G (SM-G781N) - SteamOS ARM Gaming Device

---

## Phase 1: Build System Validation

- [ ] Test kernel build script
- [ ] Test device tree compilation
- [ ] Test rootfs creation
- [ ] Test gamescope build
- [ ] Test Box64/Box86 build
- [ ] Create bootable image

## Phase 2: Hardware Enablement

- [ ] Obtain WiFi/BT firmware files
- [ ] Configure actual WiFi driver for WCN6856
- [ ] Configure actual Bluetooth driver
- [ ] Test and configure audio (ALSA/PipeWire)
- [ ] Test touchscreen input
- [ ] Calibrate display timings

## Phase 3: Steam Integration

- [ ] Test Steam client installation via Box64
- [ ] Configure Steam for ARM
- [ ] Test Gamescope + Steam integration
- [ ] Configure Steam Deck profiles
- [ ] Test game launching

## Phase 4: Optimization

- [ ] Optimize GPU performance (Adreno 650)
- [ ] Configure thermal management
- [ ] Optimize battery life
- [ ] Enable controller support
- [ ] Test and verify touch gamepad overlay

## Phase 5: Documentation

- [ ] Hardware testing guide
- [ ] Flashing guide with actual commands
- [ ] Gaming performance benchmarks
- [ ] Known issues and workarounds
- [ ] FAQ section

---

## Low Priority / Future

- [ ] Exynos 990 (SM-G780F) support
- [ ] Mainline kernel upstreaming
- [ ] Android app compatibility
- [ ] Multiplayer networking improvements
- [ ] Custom bootloader (U-Boot)

---

## Dependencies

### External Files Needed

| File | Source | License |
|------|--------|---------|
| WiFi firmware (WCN6856) | Qualcomm downstream | Proprietary |
| BT firmware | Qualcomm downstream | Proprietary |
| GPU firmware | Mesa/Freedreno | Open source |

### Build Dependencies

| Tool | Version |
|------|---------|
| aarch64-linux-gnu-gcc | Latest |
| meson | ≥0.60 |
| ninja | Latest |
| cmake | ≥3.20 |
