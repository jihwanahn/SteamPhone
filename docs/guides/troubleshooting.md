# Troubleshooting Guide

Common issues and their solutions for SteamPhone.

## Boot Issues

### Device not booting after flash

1. **Check bootloader unlock**:
   ```bash
   # On device, before flashing:
   # Settings > Developer Options > OEM Unlocking must be ON
   ```

2. **Verify image integrity**:
   ```bash
   sha256sum steamphone-*.img
   # Compare with checksums in releases
   ```

3. **Check USB connection**:
   ```bash
   # Use quality USB-C cable
   # Try different USB port on host
   lsusb | grep -i samsung
   ```

4. **Recovery mode**:
   - Hold Volume Down + Power
   - Select "Recovery mode"
   - Try re-flashing

### Kernel panic on boot

1. **Check DTB compatibility**:
   ```bash
   # Verify correct DTB for your model
   # SM-G780F = Exynos 990
   # SM-G780G/SM-G781N = Snapdragon 865
   ```

2. **Serial debug output**:
   - Connect UART adapter to debug pins
   - Check what causes panic

3. **Common causes**:
   - Missing WiFi firmware
   - GPU driver not loaded
   - Display panel initialization failed

## Display Issues

### No display output

1. **Check HDMI/DisplayPort**:
   ```bash
   # If using external display
   cat /sys/class/drm/card0-VIRTUAL-1/status
   ```

2. **Check backlight**:
   ```bash
   cat /sys/class/backlight/backlight/brightness
   echo 100 > /sys/class/backlight/backlight/brightness
   ```

3. **Check Gamescope**:
   ```bash
   systemctl status steamphone-session
   journalctl -u steamphone-session
   ```

### Display orientation wrong

Edit `/etc/steamphone/steamphone.conf`:
```bash
STEAMPHONE_ORIENTATION=landscape  # or portrait
```

Then restart:
```bash
systemctl restart steamphone-session
```

### 120Hz not working

1. **Verify panel support**:
   ```bash
   cat /sys/class/drm/card0/card0-DSI-1/modes
   ```

2. **Check Gamescope settings**:
   ```bash
   gamescope --refresh-rate 120
   ```

## Network Issues

### WiFi not connecting

1. **Check firmware loaded**:
   ```bash
   dmesg | grep -i wifi
   ls /lib/firmware/qca/
   ```

2. **Enable WiFi**:
   ```bash
   ip link set wlan0 up
   iw dev wlan0 scan | grep SSID
   ```

3. **Check network manager**:
   ```bash
   systemctl status NetworkManager
   nmcli device wifi list
   ```

4. **Disable power management**:
   ```bash
   iw dev wlan0 set power_save off
   ```

### Bluetooth not working

1. **Check Bluetooth service**:
   ```bash
   systemctl status bluetooth
   rfkill list bluetooth
   rfkill unblock bluetooth
   ```

2. **Scan for devices**:
   ```bash
   bluetoothctl
   [bluetooth]# power on
   [bluetooth]# scan on
   ```

## Steam Issues

### Steam client won't start

1. **Check Box64 installed**:
   ```bash
   which box64
   box64 --version
   ```

2. **Check Steam installation**:
   ```bash
   ls -la ~/.steam/
   ~/.steam/steam.sh -help
   ```

3. **Check libraries**:
   ```bash
   ldd ~/.steam/steam/ubuntu12_32/steamui.so
   ```

### Games crashing

1. **Enable MangoHud**:
   ```bash
   MANGOHUD=1 steam
   ```

2. **Check for missing libraries**:
   ```bash
   steam-dependencies  # if available
   ```

3. **Verify Wine/DXVK**:
   ```bash
   WINEDEBUG=-all dxvk
   ```

## Audio Issues

### No sound

1. **Check PipeWire**:
   ```bash
   systemctl status pipewire
   pw-top
   ```

2. **List audio devices**:
   ```bash
   pactl list sinks
   ```

3. **Set default output**:
   ```bash
   pactl set-default-sink <sink-name>
   ```

### Crackling/popping audio

1. **Increase buffer size**:
   Edit `/etc/pipewire/pipewire.conf`:
   ```
   default.clock.quantum = 1024
   ```

2. **Restart PipeWire**:
   ```bash
   systemctl restart pipewire
   ```

## Performance Issues

### Low FPS in games

1. **Check GPU driver**:
   ```bash
   glxinfo | grep "OpenGL renderer"
   vkcube
   ```

2. **Check CPU frequency**:
   ```bash
   watch -n1 "cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq"
   ```

3. **Enable performance mode**:
   ```bash
   cpupower frequency-set -g performance
   ```

### Device overheating

1. **Check thermal zones**:
   ```bash
   cat /sys/class/thermal/thermal_zone*/temp
   ```

2. **Reduce GPU clock**:
   Edit `/etc/steamphone/steamphone.conf`:
   ```
   STEAMPHONE_GPU_PROFILE=powersave
   ```

3. **Limit refresh rate**:
   ```
   STEAMPHONE_REFRESH_RATE=60
   ```

## Getting Help

If you've tried these solutions and still have issues:

1. **Search existing issues**: https://github.com/jihwanahn/steamphone/issues
2. **Create new issue** with:
   - Device model (SM-XXXXX)
   - Kernel version
   - Steps to reproduce
   - Debug logs (`journalctl -b`, `dmesg`)
3. **Discord community**: Link in README
