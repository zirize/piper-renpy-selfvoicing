#!/bin/bash

toggle_file=/run/user/$UID/espeak_auto_skip
log_toggle_file=/run/user/$UID/espeak_log_text
LOG_DIR=/run/user/$UID/espeak_logs

# This is a dummy espeak file used as a wrapper script for utilizing piper.
# It allows Ren'Py engines to utilize piper as a TTS engine.
# Note: Many espeak functions are not supported.
# Recommended for use with Ren'Py engines only.
# Modify the script to support additional functions if needed.

# Requires: the standalone Piper 1.2.0 binary extracted to ~/.local/share/piper
# (https://github.com/rhasspy/piper/releases/tag/v1.2.0); see install.sh.

# Set the model to use.
# Since Ren'Py calls this script every time it needs to synthesize text,
# changing this value allows you to change the voice during gameplay.
#MODEL=en_GB-cori-high
#MODEL=en_GB-alba-medium
MODEL=en_GB-jenny_dioco-medium
#MODEL=en_GB-semaine-medium
#MODEL=en_US-hfc_female-medium
#MODEL=en_US-amy-medium

# Model used instead of MODEL when the text contains Hangul.
# The stock ko_KR-kss-medium.onnx.json (piper 1.5.0 format) crashes piper 1.2.0
# with "Phonemes must be one codepoint"; the installed copy has the five
# multi-codepoint English diphthong entries (aɪ aʊ ɔɪ eɪ oʊ) removed.
MODEL_KO=ko_KR-kss-medium

# Set the model directory and piper binary.
# The Piper 1.2.0 archive puts the binary, its libraries and espeak-ng-data here.
PIPER_DIR=$HOME/.local/share/piper
PIPER_MODEL_DIR=$PIPER_DIR/models
PIPER_BIN=$PIPER_DIR/piper

# Set the options for piper.
# piper reads <model>.onnx.json from next to the .onnx file.
OPT_MODEL_DATA="--model $PIPER_MODEL_DIR/$MODEL.onnx"

# Set the aplay binary and options.

#if [ -n "$PULSE_SERVER" ]; then
#    PLAY="aplay -D pulse -q -r 22050 -f S16_LE -t raw -"
#else
#    PLAY="pw-play --rate 22050 --channel-map LE - "
#fi

PLAY="aplay -D pulse -q -r 22050 -f S16_LE -t raw -"

# Check if there are no arguments
if [ $# -eq 0 ]; then
    exit 0
fi

# Parse command-line arguments.
# Ren'Py passes arguments as -v <voice> -a <amp> <text>.
# We are not using the voice and amp options, so we are just parsing the text.
while getopts "v:a:" opt; do
    case $opt in
    v) ;;
    a) ;;
    *) ;;
    esac
done

# Shift the parsed options away
shift $((OPTIND - 1))

# Remaining arguments which are the actual text to synthesize.
# fix wired bug that '*' is somehow 'ls' result
text=$(echo "$@" | sed 's/\b$(ls)\b//g')

# Check stdin pipe if there is any text.
if [ -p /dev/stdin ]; then
    text=$(cat)
fi

# Check if the text is empty then quit.
if [ -z "$text" ]; then
    exit 0
fi

# using sed to remove any other characters that are alphanumeric, space, or punctuation
# slience sed errors
text=$(echo "$text" | sed 's/[…–]/  /g' 2>/dev/null)
if [ $? -ne 0 ]; then
    exit 0
fi
test=$(echo "$text" | sed 's/[…]/./g' 2>/dev/null)

text=$(echo "$text" | sed 's/[’]/\x27/g' 2>/dev/null)
if [ $? -ne 0 ]; then
    exit 0
fi
# Korean text (any Hangul syllable or jamo) switches to the Korean model and
# keeps Hangul through the character filter.
HANGUL='\x{AC00}-\x{D7A3}\x{3131}-\x{318E}'
if echo "$text" | perl -CSD -0777 -ne "exit(/[$HANGUL]/ ? 0 : 1)"; then
    MODEL=$MODEL_KO
    OPT_MODEL_DATA="--model $PIPER_MODEL_DIR/$MODEL.onnx"
    text=$(echo "$text" | perl -CSD -pe "s/[^-a-zA-Z0-9,.?!:;\@\\\$%&\"' $HANGUL]//g")
else
    text=$(echo "$text" | sed 's/[^-a-zA-Z0-9,.?!:;@$%&"\x27 ]//g' 2>/dev/null)
fi
text=$(echo "$text" | sed 's/\([A-Z][a-z]*\)\. \([A-Z]\)/\1.\2/g')

# Ren'Py joins every text on screen with ": ". Symbol-only texts (e.g. "·"
# quick-menu separators) were just stripped above, leaving ": : : <dialogue>".
# Collapse runs of colons and drop leading/trailing ones.
text=$(echo "$text" | sed -E 's/:([[:space:]]*:)+/:/g; s/^[[:space:]:]+//; s/[[:space:]:]+$//')

if [ $? -ne 0 ]; then
    exit 0
fi

#if remove all spaces of text and store in tmp and it's lenght is 0 then exit
tmp=$(echo $text | tr -d ' ')
if [ ${#tmp} -eq 0 ]; then
    exit 0
fi

# Print the text for debug
echo -e $text

# Save the echoed text to a log file if the toggle is enabled
if [ -f "$log_toggle_file" ]; then
    mkdir -p "$LOG_DIR"
    echo -e "$text" >> "$LOG_DIR/espeak_output.log"
fi

# Terminate any previously running instances to prevent overlapping voices.
/usr/bin/pkill -x "piper"
/usr/bin/pkill -x "aplay"
/usr/bin/pkill -x "pw-play"

# if $text start with 'Self-Voicing' then exit
if [[ $text == "Self-voicing"* ]]; then
    exit 0
fi

if [[ $text == "Skipping:"* ]]; then
    exit 0
fi

# Print the command for debug
#echo "$PIPER_BIN $OPT_ALL | $PLAY"

# Synthesize the text using piper and play the resulting audio using aplay.
#echo -e $text | $PIPER_BIN $OPT_MODEL_DATA --output-raw 2>/dev/null | $APLAY $APLAY_OPT 2>/dev/null
echo -e $text | $PIPER_BIN $OPT_MODEL_DATA --output-raw 2>/dev/null | $PLAY 2>/dev/null
#echo -e "$text" | $PIPER_BIN $OPT_MODEL_DATA --output_raw 2>/dev/null | $PLAY 2>/dev/null

exit 0

# Check if toglgle file exists then exit
if [ ! -f "$toggle_file" ]; then
    exit 0
fi

if [ "$DISPLAY" == ":5.0" ]; then
    exit 0
fi

#exit 0
if [ $? -ne 0 ]; then
    exit 0
fi

# Ren'Py's auto mode and self-voicing cannot be used simultaneously.
# The following code sends the space key automatically
# after the dialogue ends to move to the next page.

# if RENPY_MODE is not set 1 then exit
if [ -z $RENPY_MODE ]; then
    exit 0
fi

# you have to install xdotool to use this feature
WINDOW_ID=$(xdotool search --pid $PPID | head -n 1)
if [ -z $WINDOW_ID ]; then
    exit 0
fi

WIN_NAME=$(xwininfo -id $WINDOW_ID | grep ^xwininfo | cut -d' ' -f5- | sed 's/^"\(.*\)"$/\1/')

sleep 1.5

xdotool key --window $WINDOW_ID space
