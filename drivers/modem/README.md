# Modem Driver Information - Galaxy S20 FE (SM-G781N)

## Hardware

The Snapdragon 865 includes an integrated modem:
- **Primary**: Qualcomm Snapdragon X55 5G modem (in some variants)
- **Alternative**: 4G LTE only (varies by region)

## For SteamPhone Gaming Device

**NOTE**: The modem is typically NOT needed for SteamPhone since:
- Gaming uses WiFi/Ethernet
- Steam download/installation via WiFi
- Online gaming via WiFi connection

## If You Want to Enable Modem

### Kernel Configuration
```bash
CONFIG_QCOM_QMI_HELPERS=y
CONFIG_MHI_BUS=y
CONFIG_MHI_BUS_PCI_GENERIC=y
CONFIG_QRTR=y
CONFIG_QRTR_SMD=y
```

### Services Required
- ModemManager: `pacman -S modemmanager`
- oFono: Alternative to ModemManager

### Commands
```bash
# Check modem status
mmcli -L
# Enable modem
mmcli -m 0 -e
```

## Disabling Modem

To save power and avoid issues, modem can be disabled:
```bash
# Block modem driver
echo "blacklist qcom_qmi_legacy" >> /etc/modprobe.d/blacklist.conf
# Or via kernel cmdline: modprobe.blacklist=qcom_qmi_legacy
```

## Known Issues

1. **Modem causes power issues**: Disable in kernel config if not needed
2. **No cellular detected**: Check `mhi` and `qrtr` modules loaded
3. **Airplane mode issues**: Check RFkill: `rfkill list all`

## References

- Qualcomm MHI: https://www.codeaurora.org/external/qcom-seps/mhi
- ModemManager: https://wiki.freedesktop.org/ModemManager/
