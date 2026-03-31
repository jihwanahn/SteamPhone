#!/bin/bash
# SteamPhone Touchscreen Gamepad Overlay
# Converts touchscreen regions into virtual gamepad inputs

set -euo pipefail

CONFIG_FILE="/etc/steamphone/gamepad-layout.json"
STATE_FILE="/tmp/steamphone-input.state"

log() { echo "[steamphone-input] $*"; }

# Default gamepad layout for portrait mode
DEFAULT_LAYOUT='
{
  "version": 1,
  "touch_regions": [
    {"id": "L2", "x": 0, "y": 0, "w": 270, "h": 600, "type": "trigger"},
    {"id": "L1", "x": 0, "y": 600, "w": 270, "h": 300, "type": "shoulder"},
    {"id": "DPAD_UP", "x": 80, "y": 1200, "w": 110, "h": 110, "type": "button"},
    {"id": "DPAD_DOWN", "x": 80, "y": 1520, "w": 110, "h": 110, "type": "button"},
    {"id": "DPAD_LEFT", "x": 0, "y": 1310, "w": 110, "h": 110, "type": "button"},
    {"id": "DPAD_RIGHT", "x": 160, "y": 1310, "w": 110, "h": 110, "type": "button"},
    {"id": "R2", "x": 810, "y": 0, "w": 270, "h": 600, "type": "trigger"},
    {"id": "R1", "x": 810, "y": 600, "w": 270, "h": 300, "type": "shoulder"},
    {"id": "A", "x": 900, "y": 1200, "w": 110, "h": 110, "type": "button"},
    {"id": "B", "x": 1010, "y": 1100, "w": 110, "h": 110, "type": "button"},
    {"id": "X", "x": 790, "y": 1100, "w": 110, "h": 110, "type": "button"},
    {"id": "Y", "x": 900, "y": 1000, "w": 110, "h": 110, "type": "button"},
    {"id": "START", "x": 540, "y": 1350, "w": 80, "h": 80, "type": "button"},
    {"id": "SELECT", "x": 440, "y": 1350, "w": 80, "h": 80, "type": "button"}
  ],
  "display": {
    "width": 1080,
    "height": 2400,
    "orientation": "portrait"
  }
}
'

# Gamepad state
declare -A BUTTON_STATE

# Load configuration
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        log "Loading config from $CONFIG_FILE"
        # Simple parsing - jq would be better but may not be available
        return 0
    else
        log "No config found, using defaults"
        echo "$DEFAULT_LAYOUT" > "$STATE_FILE"
    fi
}

# Initialize uinput for gamepad
init_uinput() {
    if ! modprobe uinput 2>/dev/null; then
        log "Warning: uinput module not available"
        return 1
    fi

    # Create gamepad device via uinput
    # This is a stub - full implementation would use uinput ioctls
    log "Gamepad input initialized"
    return 0
}

# Handle touch event
handle_touch() {
    local x=$1
    local y=$2
    local pressed=$3  # 1 = down, 0 = up

    # Simple region matching
    case "$pressed" in
        1)  log "Touch at $x,$y (press)" ;;
        0)  log "Touch at $x,$y (release)" ;;
    esac

    # In full implementation:
    # 1. Find matching region
    # 2. Send gamepad event via uinput
    # 3. Update button state
}

# Main loop - watches for touch events
main() {
    log "Starting SteamPhone input daemon"

    load_config
    init_uinput || true

    # In full implementation, this would read from /dev/input/eventX
    # For now, just log startup
    log "Watching for touch input..."

    # Keep running
    while true; do
        sleep 1
    done
}

# Signal handler
trap 'log "Received signal, shutting down"; exit 0' INT TERM

main "$@"
