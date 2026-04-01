# Audio Driver Information - Galaxy S20 FE (SM-G781N)

## Hardware

The SM-G781N (Snapdragon 865) typically uses:
- **Primary codec**: Qualcomm WCD9385 (integrated in Snapdragon)
- **Audio DSP**: Qualcomm QDSP6 (Hexagon)

## Kernel Configuration

```bash
CONFIG_SND=y
CONFIG_SND_SOC=y
CONFIG_SND_SOC_QCOM=y
CONFIG_SND_SOC_SM8250=y
CONFIG_SND_SOC_QDSP6=y
CONFIG_QCOM_APR=y
```

## Audio Paths

### Speakers
- Analog speaker via CS47L93 or similar codec
- Route through MIXER

### USB-C Audio
USB-C headphones use standard USB Audio Class:
```bash
# List audio devices
pactl list sinks
# Set default
pactl set-default-sink <sink-name>
```

### HDMI Audio
HDMI audio is handled via DisplayPort alternate mode:
```
/dev/snd/pcmC0D0 - HDMI output
```

## PipeWire Configuration

SteamPhone uses PipeWire as the audio server:

```bash
# Check audio status
pw-top
# List devices
pw-cli list-all
```

## Known Issues

1. **No sound**: Check PipeWire: `systemctl status pipewire`
2. **Wrong output**: Set default sink with `pw-metadata`
3. **Crackling**: Increase buffer size in `/etc/pipewire/pipewire.conf`

## References

- ALSA: https://www.alsa-project.org/
- PipeWire: https://pipewire.org/
- Qualcomm Audio: https://source.codeaurora.org/quic/la/kernel/audio-kernel
