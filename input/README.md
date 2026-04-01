# SteamPhone Input System

The input system converts touchscreen regions into virtual gamepad inputs,
allowing touchscreen-only devices like phones to play Steam games.

## Components

### steamphone-input.sh

The main input daemon that:
1. Reads touch events from `/dev/input/eventX`
2. Maps touch coordinates to gamepad buttons
3. Sends virtual gamepad events via uinput

### gamepad-layout.json

Configuration file defining:
- Touch regions (position and size)
- Button mappings
- Display dimensions
- Multiple layouts (future: per-game layouts)

## Installation

The input system is automatically configured during rootfs build.

To install manually:
```bash
cp steamphone-input.sh /usr/local/bin/
chmod +x /usr/local/bin/steamphone-input.sh
cp gamepad-layout.json /etc/steamphone/
```

## Configuration

Edit `/etc/steamphone/gamepad-layout.json` to customize touch regions.

### Layout Format

```json
{
  "version": 1,
  "name": "My Layout",
  "display": {
    "width": 1080,
    "height": 2400,
    "orientation": "portrait"
  },
  "touch_regions": [
    {
      "id": "A",
      "x": 900, "y": 1200,
      "w": 110, "h": 110,
      "type": "button",
      "button": "a"
    }
  ]
}
```

### Region Types

- **button**: Press/release event
- **trigger**: Analog value based on y-position
- **shoulder**: Binary on/off
- **dpad**: 4-way directional
- **stick**: 2-axis analog stick emulation

## Usage

```bash
# Start the input daemon
steamphone-input.sh

# Run with debug output
DEBUG=1 steamphone-input.sh

# Check status
systemctl status steamphone-input
```

## Steam Integration

Steam recognizes gamepad input via:
- XInput (Xbox controllers)
- SDL2 GameController API
- Native gamepad events

The uinput device creates a virtual Xbox-style controller.

## Troubleshooting

### Input not working in Steam

1. Check if steamphone-input is running:
   ```bash
   systemctl status steamphone-input
   ```

2. Verify touch events:
   ```bash
   evtest /dev/input/eventX
   ```

3. Check gamepad is recognized:
   ```bash
   jstest /dev/input/js0
   ```

### Wrong buttons detected

1. Verify layout coordinates match your display
2. Check if device is in correct orientation
3. Recalibrate touch regions

## Future Enhancements

- [ ] Multiple configurable layouts
- [ ] Per-game layout selection
- [ ] Gesture support (swipe, pinch)
- [ ] Pressure sensitivity
- [ ] Haptic feedback
