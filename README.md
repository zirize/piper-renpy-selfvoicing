# Piper TTS — Ren'Py Self-Voicing on Linux

📄 Project page: **[Piper TTS for Ren'Py Self-Voicing on Linux](https://zirize.github.io/piper-renpy-selfvoicing/)** · More projects: **[zirize.github.io](https://zirize.github.io/)**

Use natural-sounding AI voices in [Ren'Py](https://www.renpy.org/) visual novels on Linux, powered by [Piper TTS](https://github.com/rhasspy/piper).

Ren'Py's built-in self-voicing feature uses `espeak` to read dialogue aloud. This project replaces it with a wrapper script that silently redirects speech synthesis to Piper — a fast, local neural TTS engine — while staying fully compatible with Ren'Py's existing self-voicing system.

> 📖 Also available as a [Reddit guide on r/RenPy](https://www.reddit.com/r/RenPy/comments/1ganueb/selfvoicing_with_natural_voices_with_pipertts_on/)

---

## Features

- 🔊 High-quality neural TTS voices (local, no internet required after setup)
- 🎮 Works transparently with Ren'Py's self-voicing (`V` key)
- 🔇 Filters out system messages (`Self-voicing enabled`, `Skipping:`, etc.)
- 🌍 English voices (US and UK accents), plus an optional Korean voice used automatically for lines containing Hangul
- 🔄 Switch voices by changing one variable in the script
- 📝 Optional log of every spoken line

---

## Which Piper?

This project uses the **standalone Piper 1.2.0 binary** (C++, from [rhasspy/piper](https://github.com/rhasspy/piper/releases/tag/v1.2.0)). It needs no Python and starts fast, which matters because Ren'Py launches a new process for every line:

| | Delay per line |
|---|---|
| Piper 1.2.0 (standalone) | about 0.25 s |
| piper-tts 1.8.0 (Python package) | about 0.95 s |

The newer Python package ([OHF-Voice/piper1-gpl](https://github.com/OHF-Voice/piper1-gpl)) also cannot be installed with `pip install --user` on recent Ubuntu/Debian (PEP 668). The rhasspy/piper repository is archived, but the 1.2.0 release and all voice models are still downloadable.

---

## Requirements

- Linux (x86_64)
- `curl`, `tar`, `git`, `perl`
- `aplay` (ALSA/PulseAudio): `sudo apt install alsa-utils`
- *(Korean voice only)* `python3`, to fix the model config once at install time

---

## Quick Install

```bash
git clone https://github.com/zirize/piper-renpy-selfvoicing.git
cd piper-renpy-selfvoicing
./install.sh            # or: ./install.sh --korean
```

Or by hand:

```bash
# 1. Piper 1.2.0 (creates ~/.local/share/piper/ with the binary, libraries and espeak-ng-data)
mkdir -p $HOME/.local/share $HOME/.local/bin
curl -L https://github.com/rhasspy/piper/releases/download/v1.2.0/piper_amd64.tar.gz \
    | tar xz -C $HOME/.local/share

# 2. A voice model (.onnx plus its .onnx.json)
mkdir -p $HOME/.local/share/piper/models
cd $HOME/.local/share/piper/models
V=https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_GB/jenny_dioco/medium/en_GB-jenny_dioco-medium
curl -L -O $V.onnx -O $V.onnx.json

# 3. The wrapper, linked in as 'espeak'
git clone https://github.com/zirize/piper-renpy-selfvoicing.git $HOME/.local/share/piper/scripts
ln -sf $HOME/.local/share/piper/scripts/piper_espeak_wrapper.sh $HOME/.local/bin/espeak

# 4. Test
espeak "Piper installation complete."
```

> `$HOME/.local/bin` is included in PATH by default on most modern Linux distributions (Ubuntu 21.04+, Fedora, Arch, etc.). If `espeak` is not found, add it to your shell profile: `export PATH="$HOME/.local/bin:$PATH"`

See [`install.sh`](install.sh) for the annotated script, and [`guide.txt`](guide.txt) for step-by-step instructions.

---

## Using Self-Voicing in Ren'Py

1. Launch your Ren'Py game
2. Press **`V`** to enable self-voicing
3. Piper will now speak each line of dialogue using your selected voice model

---

## Changing Voice Models

Edit the `MODEL` variable at the top of `$HOME/.local/share/piper/scripts/piper_espeak_wrapper.sh`:

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

Download another voice into `~/.local/share/piper/models`; the path is `<lang>/<locale>/<name>/<quality>/<model>` under the voices repository:

```bash
cd $HOME/.local/share/piper/models
V=https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium
curl -L -O $V.onnx -O $V.onnx.json
```

Voices with `"phoneme_type": "espeak"` in their `.onnx.json` work with 1.2.0. Japanese (`"japanese"`) and other non-espeak phonemizers need a newer Piper.

---

## Korean Voice

When a line contains Hangul, the wrapper uses `MODEL_KO` (`ko_KR-kss-medium`) instead of `MODEL`, and keeps the Hangul through its character filter. Install it with `./install.sh --korean`.

The stock `ko_KR-kss-medium.onnx.json` was written by Piper 1.5.0 and makes 1.2.0 abort with `Phonemes must be one codepoint`. `install.sh --korean` deletes the five multi-codepoint entries (`aɪ aʊ ɔɪ eɪ oʊ`) from its `phoneme_id_map`; Korean does not use them. Re-downloading the config undoes the fix.

The voice is licensed CC BY-NC-SA 4.0 (non-commercial).

---

## Logging Spoken Text

Create the toggle file to append every spoken line to `/run/user/$UID/espeak_logs/espeak_output.log`; delete it to stop:

```bash
touch /run/user/$UID/espeak_log_text    # on
rm /run/user/$UID/espeak_log_text       # off
```

---

## Auto-Advance (currently disabled)

The wrapper contains code that presses **Space** after each line (needs `xdotool`, X11 only, and `RENPY_MODE=1`). It is disabled: the script exits right after playback. Delete the `exit 0` line after the `piper` command to re-enable it.

---

## Files

| File | Description |
|------|-------------|
| `piper_espeak_wrapper.sh` | The espeak wrapper; `~/.local/bin/espeak` links to it |
| `install.sh` | Installation script (`--korean` adds the Korean voice) |
| `guide.txt` | Step-by-step guide |
| `note.txt` | Quick reference for the `MODEL` lines |

---

## How It Works

Ren'Py calls `espeak -v <voice> -a <amp> <text>` when self-voicing is active. This wrapper script:

1. Parses the arguments (ignoring `-v` and `-a` options)
2. Picks the Korean model if the text contains Hangul
3. Cleans up the text (removes characters Piper can't handle, collapses the `: : :` Ren'Py leaves behind)
4. Filters out Ren'Py system messages
5. Kills any previously playing audio to prevent overlap
6. Pipes the text to `piper` → `aplay` for immediate playback

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
- Re-extract the 1.2.0 archive if missing

**A voice crashes with `Phonemes must be one codepoint`:**
- Its config was written by a newer Piper; see [Korean Voice](#korean-voice) for the fix

---

## License

This wrapper script is released into the public domain. Piper 1.2.0 is licensed under the [MIT License](https://github.com/rhasspy/piper/blob/master/LICENSE). Each voice model has its own license (see its `MODEL_CARD` on Hugging Face).
