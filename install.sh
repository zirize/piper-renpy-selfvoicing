#!/bin/bash
# Install Piper 1.2.0 (standalone binary) and the espeak wrapper for Ren'Py self-voicing.
#
#   ./install.sh            English voice only (en_GB-jenny_dioco-medium)
#   ./install.sh --korean   also the Korean voice (ko_KR-kss-medium), needs python3
#
# Everything goes under ~/.local/share/piper and ~/.local/bin/espeak.
# Undo: rm -rf ~/.local/share/piper ~/.local/bin/espeak
set -euo pipefail

PIPER_DIR=$HOME/.local/share/piper
PIPER_URL=https://github.com/rhasspy/piper/releases/download/v1.2.0/piper_amd64.tar.gz
VOICES=https://huggingface.co/rhasspy/piper-voices/resolve/main
REPO=https://github.com/zirize/piper-renpy-selfvoicing.git

korean=0
[ "${1:-}" = "--korean" ] && korean=1

for cmd in curl tar git aplay perl; do
    command -v $cmd >/dev/null || { echo "missing: $cmd (e.g. sudo apt install curl git alsa-utils perl)"; exit 1; }
done
[ "$(uname -m)" = "x86_64" ] || { echo "this script installs the x86_64 build only"; exit 1; }

# --- Piper 1.2.0: binary, libraries and espeak-ng-data in one archive ---
mkdir -p $HOME/.local/share $HOME/.local/bin
if [ ! -x $PIPER_DIR/piper ]; then
    curl -fL $PIPER_URL | tar xz -C $HOME/.local/share    # creates ~/.local/share/piper/
fi

# --- Voice models: a .onnx file and its .onnx.json config ---
get_voice() {    # get_voice <lang>/<locale>/<name>/<quality>/<model>
    local m=$(basename $1)
    [ -s $PIPER_DIR/models/$m.onnx ] && return
    curl -fL -o $PIPER_DIR/models/$m.onnx      "$VOICES/$1.onnx"
    curl -fL -o $PIPER_DIR/models/$m.onnx.json "$VOICES/$1.onnx.json"
}
mkdir -p $PIPER_DIR/models
get_voice en/en_GB/jenny_dioco/medium/en_GB-jenny_dioco-medium

if [ $korean = 1 ]; then
    get_voice ko/ko_KR/kss/medium/ko_KR-kss-medium
    # This config was written by piper 1.5.0. Piper 1.2.0 refuses its five
    # multi-codepoint phonemes ("Phonemes must be one codepoint"); Korean does not use them.
    python3 - $PIPER_DIR/models/ko_KR-kss-medium.onnx.json <<'EOF'
import json, sys
p = sys.argv[1]
d = json.load(open(p))
for k in [k for k in d['phoneme_id_map'] if len(k) != 1]:
    del d['phoneme_id_map'][k]
json.dump(d, open(p, 'w'), ensure_ascii=False)
EOF
fi

# --- The wrapper: this repository, linked in as 'espeak' ---
if [ ! -e $PIPER_DIR/scripts ]; then
    git clone $REPO $PIPER_DIR/scripts
fi
chmod +x $PIPER_DIR/scripts/piper_espeak_wrapper.sh
ln -sf $PIPER_DIR/scripts/piper_espeak_wrapper.sh $HOME/.local/bin/espeak

# --- Test ---
$HOME/.local/bin/espeak "Piper installation complete."
if [ $korean = 1 ]; then
    $HOME/.local/bin/espeak "한국어 음성도 설치되었습니다."
fi

echo "Done. If ~/.local/bin is not in PATH, add: export PATH=\"\$HOME/.local/bin:\$PATH\""
