#!/bin/bash

# Using self-voicing with natural voices in Linux with Piper-TTS
# For more information, visit: https://github.com/rhasspy/piper

# Disclaimer: This guide is intended for regular Linux users, not developers.
# If you are using espeak outside of Ren'Py, you may experience conflicts.

# What is Piper?
# Piper is considered one of the best free TTS (Text-to-Speech) engines for Linux.
# It is a fast, local neural text-to-speech system that delivers high-quality sound.

# Ren'Py uses espeak to generate voice. This guide provides a method to use Piper
# with an espeak wrapper script.


# --- Check Dependencies ---
# Verify aplay and wget are installed
aplay --version
wget --version
# If missing, install with: sudo apt install alsa-utils wget


# --- Create directories ---
mkdir -p $HOME/.local/share/piper/models
mkdir -p $HOME/.local/share/piper/scripts
mkdir -p $HOME/.local/bin


# --- Download and install Piper ---
wget https://github.com/rhasspy/piper/releases/download/v1.2.0/piper_amd64.tar.gz

# Extract to the piper directory (strip the top-level 'piper' folder from the archive)
tar xvfz piper_amd64.tar.gz --strip-components=1 -C $HOME/.local/share/piper

# Create a symbolic link for the piper binary
ln -sf $HOME/.local/share/piper/piper $HOME/.local/bin/piper


# --- Download a voice model ---
# Default: US English female voice
wget "https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_US/hfc_female/medium/en_US-hfc_female-medium.onnx?download=true" \
    -O $HOME/.local/share/piper/models/en_US-hfc_female-medium.onnx

wget "https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_US/hfc_female/medium/en_US-hfc_female-medium.onnx.json?download=true" \
    -O $HOME/.local/share/piper/models/en_US-hfc_female-medium.onnx.json


# --- Install the espeak wrapper script ---
# Copy the wrapper script from this repository
cp piper_espeak_wrapper.sh $HOME/.local/share/piper/scripts/espeak
chmod +x $HOME/.local/share/piper/scripts/espeak

# Or create an empty script and fill it manually:
# touch $HOME/.local/share/piper/scripts/espeak
# chmod +x $HOME/.local/share/piper/scripts/espeak
# your_favorite_text_editor $HOME/.local/share/piper/scripts/espeak


# --- Create symlink so 'espeak' is found in PATH ---
# $HOME/.local/bin is typically already in PATH on modern Linux distros
ln -sf $HOME/.local/share/piper/scripts/espeak $HOME/.local/bin/espeak


# --- Test the installation ---
espeak "Piper installation complete."

# If you can hear the voice, the installation was successful.


# --- Download other models ---
# Visit: https://rhasspy.github.io/piper-samples/
#
# After downloading, place files in: $HOME/.local/share/piper/models/
#   - A .onnx model file, e.g. en_US-lessac-medium.onnx
#   - A .onnx.json config file, e.g. en_US-lessac-medium.onnx.json
#
# Then update the MODEL variable in the espeak script:
#   MODEL=en_US-lessac-medium

