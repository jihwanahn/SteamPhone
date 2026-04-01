#!/usr/bin/env python3
"""
SteamPhone Touchscreen Gamepad
Translates touchscreen input into virtual gamepad events for Steam.
Presents as a standard Xbox-compatible controller via uinput.
"""

import struct
import os
import sys
import signal
import json
from pathlib import Path

try:
    import evdev
    from evdev import UInput, ecodes, AbsInfo
except ImportError:
    print("Error: python-evdev required. Install: pip install evdev")
    sys.exit(1)

# Default layout configuration (can be overridden via config file)
DEFAULT_LAYOUT = {
    "screen_width": 1080,
    "screen_height": 2400,
    "zones": {
        "left_stick": {
            "center_x": 200,
            "center_y": 1800,
            "radius": 150,
            "type": "analog_stick",
            "axis_x": "ABS_X",
            "axis_y": "ABS_Y"
        },
        "right_stick": {
            "center_x": 880,
            "center_y": 1800,
            "radius": 150,
            "type": "analog_stick",
            "axis_x": "ABS_RX",
            "axis_y": "ABS_RY"
        },
        "dpad_up": {
            "x": 100, "y": 1200, "w": 100, "h": 100,
            "type": "button",
            "button": "BTN_DPAD_UP"
        },
        "dpad_down": {
            "x": 100, "y": 1400, "w": 100, "h": 100,
            "type": "button",
            "button": "BTN_DPAD_DOWN"
        },
        "dpad_left": {
            "x": 0, "y": 1300, "w": 100, "h": 100,
            "type": "button",
            "button": "BTN_DPAD_LEFT"
        },
        "dpad_right": {
            "x": 200, "y": 1300, "w": 100, "h": 100,
            "type": "button",
            "button": "BTN_DPAD_RIGHT"
        },
        "btn_a": {
            "x": 930, "y": 1400, "w": 100, "h": 100,
            "type": "button",
            "button": "BTN_SOUTH"
        },
        "btn_b": {
            "x": 1030, "y": 1300, "w": 100, "h": 100,
            "type": "button",
            "button": "BTN_EAST"
        },
        "btn_x": {
            "x": 830, "y": 1300, "w": 100, "h": 100,
            "type": "button",
            "button": "BTN_WEST"
        },
        "btn_y": {
            "x": 930, "y": 1200, "w": 100, "h": 100,
            "type": "button",
            "button": "BTN_NORTH"
        },
        "btn_start": {
            "x": 590, "y": 1100, "w": 80, "h": 60,
            "type": "button",
            "button": "BTN_START"
        },
        "btn_select": {
            "x": 410, "y": 1100, "w": 80, "h": 60,
            "type": "button",
            "button": "BTN_SELECT"
        },
        "btn_steam": {
            "x": 490, "y": 1200, "w": 100, "h": 100,
            "type": "button",
            "button": "BTN_MODE"
        },
        "left_trigger": {
            "x": 0, "y": 0, "w": 200, "h": 100,
            "type": "trigger",
            "axis": "ABS_Z"
        },
        "right_trigger": {
            "x": 880, "y": 0, "w": 200, "h": 100,
            "type": "trigger",
            "axis": "ABS_RZ"
        },
        "left_bumper": {
            "x": 0, "y": 100, "w": 200, "h": 80,
            "type": "button",
            "button": "BTN_TL"
        },
        "right_bumper": {
            "x": 880, "y": 100, "w": 200, "h": 80,
            "type": "button",
            "button": "BTN_TR"
        }
    }
}

CONFIG_PATH = Path("/etc/steamphone/gamepad-layout.json")


class SteamPhoneGamepad:
    """Virtual gamepad driven by touchscreen input."""

    def __init__(self, config_path=None):
        self.layout = self._load_layout(config_path)
        self.touchscreen = None
        self.gamepad = None
        self.active_touches = {}  # slot -> zone mapping

    def _load_layout(self, config_path):
        path = Path(config_path) if config_path else CONFIG_PATH
        if path.exists():
            with open(path) as f:
                return json.load(f)
        return DEFAULT_LAYOUT

    def _find_touchscreen(self):
        """Find the touchscreen input device."""
        devices = [evdev.InputDevice(path) for path in evdev.list_devices()]
        for dev in devices:
            caps = dev.capabilities()
            if ecodes.EV_ABS in caps:
                abs_caps = caps[ecodes.EV_ABS]
                has_mt = any(
                    code in [c[0] if isinstance(c, tuple) else c for c in abs_caps]
                    for code in [ecodes.ABS_MT_POSITION_X, ecodes.ABS_MT_POSITION_Y]
                )
                if has_mt:
                    print(f"Found touchscreen: {dev.name} ({dev.path})")
                    return dev
        return None

    def _create_virtual_gamepad(self):
        """Create a virtual Xbox-compatible gamepad via uinput."""
        capabilities = {
            ecodes.EV_KEY: [
                ecodes.BTN_SOUTH, ecodes.BTN_EAST,
                ecodes.BTN_WEST, ecodes.BTN_NORTH,
                ecodes.BTN_TL, ecodes.BTN_TR,
                ecodes.BTN_SELECT, ecodes.BTN_START,
                ecodes.BTN_MODE,
                ecodes.BTN_THUMBL, ecodes.BTN_THUMBR,
                ecodes.BTN_DPAD_UP, ecodes.BTN_DPAD_DOWN,
                ecodes.BTN_DPAD_LEFT, ecodes.BTN_DPAD_RIGHT,
            ],
            ecodes.EV_ABS: [
                (ecodes.ABS_X, AbsInfo(0, -32768, 32767, 16, 128, 0)),
                (ecodes.ABS_Y, AbsInfo(0, -32768, 32767, 16, 128, 0)),
                (ecodes.ABS_RX, AbsInfo(0, -32768, 32767, 16, 128, 0)),
                (ecodes.ABS_RY, AbsInfo(0, -32768, 32767, 16, 128, 0)),
                (ecodes.ABS_Z, AbsInfo(0, 0, 255, 0, 0, 0)),   # LT
                (ecodes.ABS_RZ, AbsInfo(0, 0, 255, 0, 0, 0)),  # RT
            ],
        }

        return UInput(
            capabilities,
            name="SteamPhone Virtual Gamepad",
            vendor=0x28de,  # Valve vendor ID
            product=0x1205,
            version=0x0001,
        )

    def _point_in_zone(self, x, y, zone):
        """Check if touch point is within a zone."""
        zone_cfg = self.layout["zones"][zone]
        if zone_cfg["type"] == "analog_stick":
            cx, cy, r = zone_cfg["center_x"], zone_cfg["center_y"], zone_cfg["radius"]
            return ((x - cx) ** 2 + (y - cy) ** 2) <= r ** 2
        else:
            zx, zy = zone_cfg["x"], zone_cfg["y"]
            zw, zh = zone_cfg["w"], zone_cfg["h"]
            return zx <= x <= zx + zw and zy <= y <= zy + zh

    def _find_zone(self, x, y):
        """Find which gamepad zone a touch point falls in."""
        for zone_name in self.layout["zones"]:
            if self._point_in_zone(x, y, zone_name):
                return zone_name
        return None

    def _handle_analog_stick(self, zone_name, x, y):
        """Convert touch position to analog stick values."""
        zone_cfg = self.layout["zones"][zone_name]
        cx, cy = zone_cfg["center_x"], zone_cfg["center_y"]
        radius = zone_cfg["radius"]

        # Normalize to -32768..32767
        nx = int(((x - cx) / radius) * 32767)
        ny = int(((y - cy) / radius) * 32767)
        nx = max(-32768, min(32767, nx))
        ny = max(-32768, min(32767, ny))

        axis_x = getattr(ecodes, zone_cfg["axis_x"])
        axis_y = getattr(ecodes, zone_cfg["axis_y"])

        self.gamepad.write(ecodes.EV_ABS, axis_x, nx)
        self.gamepad.write(ecodes.EV_ABS, axis_y, ny)
        self.gamepad.syn()

    def _handle_trigger(self, zone_name, pressed):
        """Handle trigger press/release."""
        zone_cfg = self.layout["zones"][zone_name]
        axis = getattr(ecodes, zone_cfg["axis"])
        value = 255 if pressed else 0
        self.gamepad.write(ecodes.EV_ABS, axis, value)
        self.gamepad.syn()

    def _handle_button(self, zone_name, pressed):
        """Handle button press/release."""
        zone_cfg = self.layout["zones"][zone_name]
        btn = getattr(ecodes, zone_cfg["button"])
        self.gamepad.write(ecodes.EV_KEY, btn, 1 if pressed else 0)
        self.gamepad.syn()

    def run(self):
        """Main event loop."""
        self.touchscreen = self._find_touchscreen()
        if not self.touchscreen:
            print("Error: No touchscreen found!")
            sys.exit(1)

        self.gamepad = self._create_virtual_gamepad()
        print("SteamPhone Gamepad active. Press Ctrl+C to stop.")

        # Grab touchscreen exclusively
        self.touchscreen.grab()

        try:
            current_slot = 0
            touch_x, touch_y = 0, 0

            for event in self.touchscreen.read_loop():
                if event.type == ecodes.EV_ABS:
                    if event.code == ecodes.ABS_MT_SLOT:
                        current_slot = event.value
                    elif event.code == ecodes.ABS_MT_POSITION_X:
                        touch_x = event.value
                    elif event.code == ecodes.ABS_MT_POSITION_Y:
                        touch_y = event.value
                    elif event.code == ecodes.ABS_MT_TRACKING_ID:
                        if event.value == -1:
                            # Touch released
                            if current_slot in self.active_touches:
                                zone = self.active_touches[current_slot]
                                zone_cfg = self.layout["zones"][zone]
                                if zone_cfg["type"] == "button":
                                    self._handle_button(zone, False)
                                elif zone_cfg["type"] == "trigger":
                                    self._handle_trigger(zone, False)
                                elif zone_cfg["type"] == "analog_stick":
                                    self._handle_analog_stick(zone, zone_cfg["center_x"], zone_cfg["center_y"])
                                del self.active_touches[current_slot]
                        else:
                            # New touch
                            zone = self._find_zone(touch_x, touch_y)
                            if zone:
                                self.active_touches[current_slot] = zone
                                zone_cfg = self.layout["zones"][zone]
                                if zone_cfg["type"] == "button":
                                    self._handle_button(zone, True)
                                elif zone_cfg["type"] == "trigger":
                                    self._handle_trigger(zone, True)

                elif event.type == ecodes.EV_SYN:
                    # Update analog sticks for active touches
                    for slot, zone in self.active_touches.items():
                        zone_cfg = self.layout["zones"][zone]
                        if zone_cfg["type"] == "analog_stick":
                            self._handle_analog_stick(zone, touch_x, touch_y)

        except KeyboardInterrupt:
            pass
        finally:
            self.touchscreen.ungrab()
            self.gamepad.close()
            print("\nSteamPhone Gamepad stopped.")


def main():
    config_path = sys.argv[1] if len(sys.argv) > 1 else None
    gamepad = SteamPhoneGamepad(config_path)
    gamepad.run()


if __name__ == "__main__":
    main()
