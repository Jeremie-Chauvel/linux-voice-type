#!/bin/bash
# /home/jeremiec/Documents/perso/voice-typing/record-audio.sh
set -euo pipefail
IFS=$'\n\t'

readonly PID_FILE="${HOME}/.recordpid"
readonly FILE="${HOME}/clips/recording"
readonly DIR="${HOME}/Documents/perso/voice-typing/"

start_recording() {
  mkdir -p "$(dirname "$FILE")"
  echo "aaa" >"$PID_FILE"
  nohup arecord --device=hw:0,0 --format cd "$FILE.wav" --duration=15 &>/dev/null &
}

stop_recording() {
  set +e
  killall -w arecord
  set -e
  rm -f "$PID_FILE"
  bash "$DIR/transcript.sh" "$FILE"
  bash "$DIR/clipboard.sh" "$FILE"
}

if [[ -f "$PID_FILE" ]]; then
  echo "Recording ongoing, stopping..."
  stop_recording
else
  echo "No recording ongoing, starting a new recording..."
  start_recording
fi
