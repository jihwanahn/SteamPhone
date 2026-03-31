# Touchscreen Driver Information - Galaxy S20 FE

## Hardware

Samsung Galaxy S20 FE uses Samsung's in-house touchscreen:
- **Model**: Samsung S6E3FC3 (also used for display)
- **Interface**: I2C
- **Touch points**: 10-point multi-touch

## Kernel Configuration

```bash
CONFIG_INPUT_TOUCHSCREEN=y
CONFIG_TOUCHSCREEN_SEC_TS=y
CONFIG_INPUT_EVDEV=y
CONFIG_INPUT_UINPUT=y
```

## Device Node

Touchscreen appears as:
- `/dev/input/eventX` (via evdev)
- `/dev/input/touchscreen` (via uinput)

## Touchscreen Gamepad Overlay

SteamPhone uses `steamphone-input` userspace daemon to convert
touch regions into virtual gamepad inputs.

### Configuration

Edit `/etc/steamphone/gamepad-layout.json`:
```json
{
  "touch_regions": [
    {"x": 0, "y": 0, "w": 540, "h": 1200, "button": "L2"},
    {"x": 540, "y": 0, "w": 540, "h": 1200, "button": "R2"}
  ]
}
```

## Calibration

Touch calibration is automatic. For manual calibration:
```bash
xinput_calibrator
```

## Known Issues

1. **Touch not responding**: Check I2C bus: `i2cdetect -l`
2. **Ghost touches**: Disable touch in kernel: `rmmod sec_ts`
3. **Gamepad overlay not working**: Check `steamphone-input` service status

## References

- Samsung touchscreen driver: drivers/input/touchscreen/sec_ts.c
- uinput: https://www.kernel.org/doc/html/latest/input/uinput.html
