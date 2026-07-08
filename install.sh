#!/bin/bash
# Install script for Dell Precision 5540 audio enhancement
# Run this after copying config files or cloning the repo

set -e

echo "Installing Dell Precision 5540 audio enhancement..."
echo ""

# Check for swh-plugins
if ! dpkg -l swh-plugins >/dev/null 2>&1; then
    echo "Installing swh-plugins (required for limiter + stereo widener)..."
    sudo apt install -y swh-plugins
fi

# Copy PipeWire config
echo "Installing PipeWire filter-chain config..."
mkdir -p ~/.config/pipewire/pipewire.conf.d
cp pipewire/pipewire.conf.d/preamp-sink.conf ~/.config/pipewire/pipewire.conf.d/

# Copy WirePlumber config
echo "Installing WirePlumber config..."
mkdir -p ~/.config/wireplumber/wireplumber.conf.d
cp wireplumber/wireplumber.conf.d/50-default-volume.conf ~/.config/wireplumber/wireplumber.conf.d/
cp wireplumber/wireplumber.conf.d/51-soft-mixer.conf ~/.config/wireplumber/wireplumber.conf.d/

# Set ALSA Master to 0 dB
echo "Setting ALSA Master to 0 dB (127/127)..."
amixer -c 0 cset numid=17 127 >/dev/null

# Save ALSA state

# Install ALSA Master pin service (ensures hardware stays at 0 dB on reboot)
echo "Installing ALSA Master pin service..."
mkdir -p ~/.config/systemd/user
cp alsa-master-pin.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable alsa-master-pin.service

# Restart audio services
echo "Restarting PipeWire and WirePlumber..."
systemctl --user restart pipewire wireplumber
sleep 3

# Set boosted sink as default
echo "Setting boosted sink as default..."
pactl set-default-sink boosted_input.built_in

# Save WirePlumber state
echo "Saving WirePlumber state..."
killall -SIGUSR2 wireplumber 2>/dev/null || true
sleep 1

# Restart COSMIC settings daemon if running
if pgrep -x cosmic-settings-daemon >/dev/null 2>&1; then
    echo "Restarting COSMIC settings daemon..."
    killall cosmic-settings-daemon 2>/dev/null || true
    sleep 1
    /usr/bin/cosmic-settings-daemon &
    sleep 1
    killall cosmic-panel 2>/dev/null || true
    sleep 2
fi

echo ""
echo "Done! Audio should now be enhanced."
echo "Test with: speaker-test -c 2 -t sine -f 440"
echo ""
echo "If the COSMIC Sound panel doesn't show 'Built-in Audio (Enhanced)',"
echo "run: killall cosmic-settings-daemon; /usr/bin/cosmic-settings-daemon &"