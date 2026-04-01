# Bluetooth Driver Information - Galaxy S20 FE (SM-G781N)

## Hardware

Bluetooth is typically integrated with WiFi chip:
- **Qualcomm WCN6856** - Combined WiFi 6E + Bluetooth 5.2
- **Broadcom BCM4375** - Combined WiFi 6 + Bluetooth 5.0

## Kernel Configuration

The kernel config includes:
```
CONFIG_BT=y
CONFIG_BT_HCIUART=y
CONFIG_BT_QCA=y          # For Qualcomm chips
CONFIG_BT_HCIBTSDIO=y    # For SDIO connected chips
```

## Bluetooth Services

On SteamPhone, Bluetooth is managed via BlueZ:
```bash
systemctl enable bluetooth
systemctl start bluetooth
```

## Pairing Controllers

### Steam Controller or Xbox Controller
```bash
bluetoothctl
[bluetooth]# power on
[bluetooth]# scan on
# Put controller in pairing mode
[bluetooth]# pair <MAC>
[bluetooth]# connect <MAC>
[bluetooth]# trust <MAC>
```

### PS4/PS5 Controller
```bash
# PS5 may require user emulation
bluetoothctl
[bluetooth]# agent on
[bluetooth]# default-agent
[bluetooth]# pair <MAC>
```

## Known Issues

1. **Controller disconnects**: Disable Bluetooth power save in `/etc/bluetooth/input.conf`
2. **No audio**: Install `pipewire-pulse` and `bluez-utils`
3. **Pairing fails**: Remove old pairing info: `bluetoothctl remove <MAC>`

## References

- BlueZ: http://www.bluez.org/
- Bluetooth HCI: https://www.bluetooth.com/specifications/bluetooth-hci/
