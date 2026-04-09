#!/bin/bash

# Using self-voicing with natural voices in Linux with Piper-TTS
# Piper TTS >= 1.4.2 (Python package)
# Home page: https://github.com/OHF-Voice/piper1-gpl

# Disclaimer: This guide is intended for regular Linux users, not developers.
# If you are using espeak outside of Ren'Py, you may experience conflicts.

# What is Piper?
# Piper is considered one of the best free TTS (Text-to-Speech) engines for Linux.
# It is a fast, local neural text-to-speech system that delivers high-quality sound.

# Ren'Py uses espeak to generate voice. This guide provides a method to use Piper
# with an espeak wrapper script.


# --- Requirements ---
# Python 3.9 or later is required.
# Check your Python version:
python3 --version

# Check that pip is available:
python3 -m pip --version
# If pip is missing: sudo apt install python3-pip


# --- Check audio dependency ---
aplay --version
# If missing: sudo apt install alsa-utils


# --- Install piper-tts ---
# Option A: Install from PyPI (recommended if you have internet access)
pip install --user piper-tts

# Option B: Install from a locally downloaded wheel file
# pip install --user /path/to/piper_tts-1.4.2-*.whl

# pip installs the 'piper' command to ~/.local/bin/piper
# $HOME/.local/bin is already in PATH on most modern Linux distros.
# Verify:
which piper || echo "piper not found — make sure ~/.local/bin is in PATH"


# --- Create the model directory ---
mkdir -p $HOME/.local/share/piper/models


# --- Download a voice model ---
# Use the built-in downloader (requires internet):
#   python3 -m piper.download_voices        <- lists all available voices
#   python3 -m piper.download_voices en_GB-jenny_dioco-medium --data-dir $HOME/.local/share/piper/models

# Default: UK English (jenny_dioco) — change to your preferred voice.
# Browse all voices at: https://rhasspy.github.io/piper-samples/
python3 -m piper.download_voices en_GB-jenny_dioco-medium \
    --data-dir $HOME/.local/share/piper/models

# Other useful voices (uncomment to download):
# python3 -m piper.download_voices en_US-hfc_female-medium --data-dir $HOME/.local/share/piper/models
# python3 -m piper.download_voices en_US-amy-medium        --data-dir $HOME/.local/share/piper/models
# python3 -m piper.download_voices en_GB-cori-high         --data-dir $HOME/.local/share/piper/models
# python3 -m piper.download_voices en_GB-alba-medium       --data-dir $HOME/.local/share/piper/models


# --- Install the espeak wrapper script ---
mkdir -p $HOME/.local/share/piper/scripts

# Copy from this repository:
cp piper_espeak_wrapper.sh $HOME/.local/share/piper/scripts/espeak
chmod +x $HOME/.local/share/piper/scripts/espeak

# Create a symlink so 'espeak' is found in PATH
ln -sf $HOME/.local/share/piper/scripts/espeak $HOME/.local/bin/espeak


# --- Test the installation ---
espeak "Piper installation complete."

# If you can hear the voice, the installation was successful.


# --- Add other models later ---
# List available voices:
#   python3 -m piper.download_voices
#
# Download to model directory:
#   python3 -m piper.download_voices <model-name> --data-dir $HOME/.local/share/piper/models
#
# Then update the MODEL variable at the top of the espeak wrapper script.


# --- Optional: Auto-advance feature ---
# Install xdotool to enable automatic page-turning after each line:
#   sudo apt install xdotool
# Then launch your Ren'Py game with:
#   RENPY_MODE=1 ./YourGame
