#!/usr/bin/env bash
# /home/jeremiec/Documents/perso/voice-typing/clipboard.sh /home/jeremiec/clips/recording
set -eo pipefail
IFS=$'\n\t'

FILE=$1
if [[ -z "$FILE" ]]; then
  echo "Usage: $0 <filepath>"
  exit 1
fi

set -u

perl -pi -e 'chomp if eof' "$FILE.txt"
xdotool type --clearmodifiers --file "$FILE.txt"
