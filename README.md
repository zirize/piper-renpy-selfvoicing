# Piper TTS — Ren'Py Self-Voicing on Linux

📄 Project page: **[Piper TTS for Ren'Py Self-Voicing on Linux](https://zirize.github.io/piper-renpy-selfvoicing/)** · More projects: **[zirize.github.io](https://zirize.github.io/)**

Use natural-sounding AI voices in [Ren'Py](https://www.renpy.org/) visual novels on Linux, powered by [Piper TTS](https://github.com/OHF-Voice/piper1-gpl).

Ren'Py's built-in self-voicing feature uses `espeak` to read dialogue aloud. This project replaces it with a wrapper script that silently redirects speech synthesis to Piper — a fast, local neural TTS engine — while staying fully compatible with Ren'Py's existing self-voicing system.

> 📖 Also available as a [Reddit guide on r/RenPy](https://www.reddit.com/r/RenPy/comments/1ganueb/selfvoicing_with_natural_voices_with_pipertts_on/)

---

## Features

- 🔊 High-quality neural TTS voices (local, no internet required after setup)
- 🎮 Works transparently with Ren'Py's self-voicing (`V` key)
- 🔇 Filters out system messages (`Self-voicing enabled`, `Skipping:`, etc.)
- 🌍 Supports multiple English voice models (US and UK accents)
- ⏭️ Optional auto-advance: press Space automatically after each line (requires `xdotool`)
- 🔄 Switch voices by changing one variable in the script

---

## Requirements

- Linux (x86_64)
- Python 3.9 or later: `sudo apt install python3`
- `aplay` (ALSA/PulseAudio): `sudo apt install alsa-utils`
- *(Optional)* `xdotool` for auto-skip: `sudo apt install xdotool`

---

## Quick Install

```bash
# 1. Install piper-tts (Python package)
pip install --user piper-tts

# 2. Create the model directory
mkdir -p $HOME/.local/share/piper/models

# 3. Download a voice model (UK English female)
python3 -m piper.download_voices en_GB-jenny_dioco-medium \
    --data-dir $HOME/.local/share/piper/models

# 4. Install the espeak wrapper
mkdir -p $HOME/.local/share/piper/scripts
cp piper_espeak_wrapper.sh $HOME/.local/share/piper/scripts/espeak
chmod +x $HOME/.local/share/piper/scripts/espeak
ln -sf $HOME/.local/share/piper/scripts/espeak $HOME/.local/bin/espeak

# 5. Test
espeak "Piper installation complete."
```

> `$HOME/.local/bin` is included in PATH by default on most modern Linux distributions (Ubuntu 21.04+, Fedora, Arch, etc.). If `espeak` is not found, add it to your shell profile: `export PATH="$HOME/.local/bin:$PATH"`

See [`install.sh`](install.sh) for the full annotated script, and [`guide.txt`](guide.txt) for step-by-step instructions.

---

## Using Self-Voicing in Ren'Py

1. Launch your Ren'Py game
2. Press **`V`** to enable self-voicing
3. Piper will now speak each line of dialogue using your selected voice model

---

## Changing Voice Models

Edit the `MODEL` variable at the top of `$HOME/.local/share/piper/scripts/espeak`:

```bash
# Available models (uncomment one):
#MODEL=en_GB-cori-high
#MODEL=en_GB-alba-medium
MODEL=en_GB-jenny_dioco-medium
#MODEL=en_GB-semaine-medium
#MODEL=en_US-hfc_female-medium
#MODEL=en_US-amy-medium
```

Browse all available voices at: **https://rhasspy.github.io/piper-samples/**

Download additional voices with:

```bash
python3 -m piper.download_voices                                      # list all voices
python3 -m piper.download_voices en_US-lessac-medium \
    --data-dir $HOME/.local/share/piper/models
```

---

## Optional: Auto-Advance (Auto-Skip)

The wrapper can automatically press **Space** after each line finishes speaking, mimicking Ren'Py's auto mode while self-voicing is active.

```bash
# Install xdotool
sudo apt install xdotool

# Launch Ren'Py with auto-skip enabled
RENPY_MODE=1 ./your_game
```

---

## Files

| File | Description |
|------|-------------|
| `piper_espeak_wrapper.sh` | Main espeak wrapper script (copy to `~/.local/share/piper/scripts/espeak`) |
| `install.sh` | Automated installation script |
| `guide.txt` | Detailed step-by-step guide |
| `note.txt` | Quick reference for available voice models |

---

## How It Works

Ren'Py calls `espeak -v <voice> -a <amp> <text>` when self-voicing is active. This wrapper script:

1. Parses the arguments (ignoring `-v` and `-a` options)
2. Cleans up the text (removes unicode special characters Piper can't handle)
3. Filters out Ren'Py system messages
4. Kills any previously playing audio to prevent overlap
5. Pipes the text to `piper` → `aplay` for immediate playback

---

## Troubleshooting

**No audio output:**
- Verify `aplay` works: `aplay /usr/share/sounds/alsa/Front_Left.wav`
- Try changing `aplay -D pulse` to just `aplay` in the script
- Check that `$HOME/.local/bin` is in your `$PATH`: `echo $PATH`

**`espeak` command not found:**
- Verify the symlink: `ls -la $HOME/.local/bin/espeak`
- Manually add to PATH: `export PATH="$HOME/.local/bin:$PATH"`

**Piper binary not found:**
- Check: `ls $HOME/.local/share/piper/piper`
- Re-extract the archive if missing

---

## License

This wrapper script is released into the public domain. Piper TTS is licensed under the [MIT License](https://github.com/rhasspy/piper/blob/master/LICENSE).
