# WiFi Driver Information - Galaxy S20 FE (SM-G781N)

## Hardware

The Samsung Galaxy S20 FE 5G typically uses one of:
- **Qualcomm WCN6856** - WiFi 6E + Bluetooth 5.2 (Snapdragon variant)
- **Broadcom BCM4375** - WiFi 6 + Bluetooth 5.0

## Kernel Configuration

The `steamphone_sd865_defconfig` includes:
```
CONFIG_CFG80211=y
CONFIG_MAC80211=y
CONFIG_WLAN=y
CONFIG_ATH11K=y        # For WCN6856
CONFIG_ATH11K_PCI=y
```

## Firmware Files

Firmware files are typically loaded from:
- `/lib/firmware/qca/` for WCN6856
- `/lib/firmware/brcm/` for BCM4375

### WCN6856 (most likely for SM-G781N)
Required firmware:
- `qca/crbtfw21.tlv`
- `qca/crnv21.bin`
- `qca/wpss.tx.bt_4.0.2.bin`

### BCM4375 (alternative)
Required firmware:
- `brcm/brcmfmac4375-pcie.bin`
- `brcm/brcmfmac4375-pcie.clm_blob`

## Building the Driver

WCN6856/ATH11K driver is in mainline kernel:
```bash
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- CONFIG_ATH11K=m
```

## Known Issues

1. **WiFi not detecting**: Check firmware files are in /lib/firmware
2. **No scan results**: Try `iw reg set US` to set regulatory domain
3. **Unstable connection**: Disable power save: `iw dev wlan0 set power_save off`

## References

- ATH11K driver: https://wireless.wiki.kernel.org/en/users/drivers/ath11k
- Linux Wireless: https://wireless.wiki.kernel.org/en/users/documentation
