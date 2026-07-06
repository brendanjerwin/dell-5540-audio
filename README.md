# Dell Precision 5540 Audio Enhancement (ALC3266)

Audio enhancement configuration for the Dell Precision 5540 (Realtek ALC3266,
subsystem ID `10280906`) running Pop!_OS / COSMIC with PipeWire + WirePlumber.

## Problem

This laptop has no ALSA UCM profile. The generic ACP fallback applies
PulseAudio's cubic volume curve (v³), which makes 20% slider = 0.008 linear
= −42 dB — inaudible on the small built-in speakers. Additionally, the
speakers are thin and lack bass/presence.

## Solution

A PipeWire filter-chain virtual sink with:
- **5-band EQ** — bass boost, warmth, voice/presence, air/clarity
- **Stereo widener** — increases stereo separation (swh matrixSpatialiser)
- **Limiter** — +15 dB input gain (makes low volumes audible), −3 dB ceiling
  (prevents clipping/distortion at high volumes)

Plus WirePlumber config to:
- Pin the ALSA hardware Master at 0 dB (soft-mixer)
- Allow software volume above 1.0 (max-volume = 10.0)
- Set default sink volume to 100% (not the built-in 6.4%)

## Signal Chain

```
app → [slider volume] → bass (+5dB @ 80Hz) → warm (+2dB @ 250Hz)
  → voice (+1dB @ 3kHz) → presence (+2dB @ 5kHz) → air (+3dB @ 10kHz)
  → stereo widener (1.5×) → limiter (+15dB, −3dB ceiling)
  → hardware sink (0 dB) → ALSA Master (127/127) → speakers
```

## Volume Curve

| Slider | Linear (v³) | × 5.6 gain | dB | Result |
|--------|-----------|------------|-----|--------|
| 5% | 0.000125 | 0.0007 | −63 | Inaudible (noise floor) |
| 20% | 0.008 | 0.045 | −27 | Audible |
| 50% | 0.125 | 0.7 | −3 | Comfortable |
| 100% | 1.0 | 5.6 → limited | −3 | Loud, clean |

## Requirements

```bash
sudo apt install swh-plugins
```

## Installation

```bash
# PipeWire filter-chain config
cp pipewire/pipewire.conf.d/preamp-sink.conf ~/.config/pipewire/pipewire.conf.d/

# WirePlumber config
cp wireplumber/wireplumber.conf.d/50-default-volume.conf ~/.config/wireplumber/wireplumber.conf.d/
cp wireplumber/wireplumber.conf.d/51-soft-mixer.conf ~/.config/wireplumber/wireplumber.conf.d/

# Set ALSA hardware Master to 0 dB (127/127) and persist
amixer -c 0 cset numid=17 127
sudo alsactl store 0

# Restart audio services
systemctl --user restart pipewire wireplumber

# Set boosted sink as default
pactl set-default-sink boosted_input.built_in

# Restart COSMIC settings daemon to pick up new sink
killall cosmic-settings-daemon; /usr/bin/cosmic-settings-daemon &
killall cosmic-panel
```

## Files

| File | Purpose |
|------|---------|
| `pipewire/pipewire.conf.d/preamp-sink.conf` | Filter-chain: 5-band EQ + widener + limiter |
| `wireplumber/wireplumber.conf.d/50-default-volume.conf` | Default sink volume = 1.0 |
| `wireplumber/wireplumber.conf.d/51-soft-mixer.conf` | Hardware mixer disabled, max-volume 10× |
| `state/wireplumber/default-nodes` | Default sink = boosted_input.built_in |
| `state/wireplumber/default-routes` | Speaker route volume = 1.0 |
| `state/cosmic/.../default_sink_name` | COSMIC cached sink name |

## Tuning

All EQ bands are in `pipewire/pipewire.conf.d/preamp-sink.conf`. Adjust the
`Gain` values to taste:

- More bass: raise band 1 `Gain` from 5.0 to 7.0
- More voice: raise band 3 `Gain` from 1.0 to 2.0, band 4 from 2.0 to 3.0
- More stereo width: raise widener `Width` from 1.5 to 2.0
- More/less overall boost: adjust limiter `Input gain (dB)` from 15.0

After changing config:
```bash
systemctl --user restart pipewire wireplumber
pactl set-default-sink boosted_input.built_in
```

## Hardware

- **Laptop**: Dell Precision 5540
- **Codec**: Realtek ALC3266
- **Subsystem ID**: 10280906
- **Vendor ID**: 10ec0298
- **Driver**: snd_hda_intel
- **Desktop**: Pop!_OS 24.04 with COSMIC
- **Audio stack**: PipeWire 1.5.85 + WirePlumber + pipewire-pulse