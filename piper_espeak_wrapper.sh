#!/bin/bash

toggle_file=/run/user/$UID/espeak_auto_skip

# This is a dummy espeak file used as a wrapper script for utilizing piper.
# It allows Ren'Py engines to utilize piper as a TTS engine.
# Note: Many espeak functions are not supported.
# Recommended for use with Ren'Py engines only.
# Modify the script to support additional functions if needed.

# Requires: piper-tts >= 1.4.2 installed via pip
#   pip install --user piper-tts
# Piper home page: https://github.com/OHF-Voice/piper1-gpl

# Set the model to use.
# Since Ren'Py calls this script every time it needs to synthesize text,
# changing this value allows you to change the voice during gameplay.
#MODEL=en_GB-cori-high
#MODEL=en_GB-alba-medium
MODEL=en_GB-jenny_dioco-medium
#MODEL=en_GB-semaine-medium
#MODEL=en_US-hfc_female-medium
#MODEL=en_US-amy-medium

# Set the model directory and piper binary.
# piper is installed to ~/.local/bin/piper via: pip install --user piper-tts
PIPER_MODEL_DIR=$HOME/.local/share/piper/models
PIPER_BIN=$HOME/.local/bin/piper

# Set the options for piper.
# Using --data-dir + model name (piper auto-detects the .onnx.json config).
OPT_MODEL_DATA="--model $MODEL --data-dir $PIPER_MODEL_DIR"

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
text=$(echo "$text" | sed 's/[^-a-zA-Z0-9,.?!:;@$%&"\x27 ]//g' 2>/dev/null)
text=$(echo "$text" | sed 's/\([A-Z][a-z]*\)\. \([A-Z]\)/\1.\2/g')

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
#echo -e $text | $PIPER_BIN $OPT_MODEL_DATA 

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
