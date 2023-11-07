#!/usr/bin/env bash
# usage: exec ./voice-typing.sh twice to start and stop recording
# Dependencies: curl, jq, arecord, xdotool, killall

set -euo pipefail
IFS=$'\n\t'

# Configuration
readonly PID_FILE="${HOME}/.recordpid"
readonly FILE="${HOME}/.voice-type/recording"
readonly MAX_DURATION=15
readonly AUDIO_INPUT='hw:0,0' # Use `arecord -l` to list available devices
source "$HOME/.ai-token"      # Ensure this file has restrictive permissions

start_recording() {
  mkdir -p "$(dirname "$FILE")"
  echo "Starting new recording..."
  nohup arecord --device="$AUDIO_INPUT" --format cd "$FILE.wav" --duration="$MAX_DURATION" &>/dev/null &
  echo $! >"$PID_FILE"
}

stop_recording() {
  echo "Stopping recording..."
  if [ -s "$PID_FILE" ]; then
    local pid
    pid=$(<"$PID_FILE")
    kill "$pid" && wait "$pid" 2>/dev/null || killall -w arecord
    rm -f "$PID_FILE"
    return 0
  fi
  echo "No recording process found."

}

write_transcript() {
  perl -pi -e 'chomp if eof' "$FILE.txt"
  xdotool type --clearmodifiers --file "$FILE.txt"
}

transcribe_with_openai() {
  curl --silent --fail --request POST \
    --url https://api.openai.com/v1/audio/transcriptions \
    --header "Authorization: Bearer $OPEN_AI_TOKEN" \
    --header 'Content-Type: multipart/form-data' \
    --form file="@$FILE.wav" \
    --form model=whisper-1 \
    --form response_format=text \
    -o "${FILE}.txt"
}

transcribe_with_deepgram() {
  curl --silent --fail --request POST \
    --url 'https://api.deepgram.com/v1/listen?smart_format=true' \
    --header "Authorization: Token $DEEPGRAM_TOKEN" \
    --header 'Content-Type: audio/wav' \
    --data-binary "@$FILE.wav" \
    -o "${FILE}.json"
  jq '.results.channels[0].alternatives[0].transcript' -r "${FILE}.json" >"${FILE}.txt"
}

transcript() {
  set +u
  if [[ -z "$DEEPGRAM_TOKEN" ]]; then
    transcribe_with_openai
  else
    transcribe_with_deepgram
  fi
  set -u
}

sanity_check() {
  for cmd in xdotool arecord killall jq curl; do
    if ! command -v "$cmd" &>/dev/null; then
      echo >&2 "Error: command $cmd not found."
      exit 1
    fi
  done
  set +u
  if [[ -z "$DEEPGRAM_TOKEN" ]] && [[ -z "$OPEN_AI_TOKEN" ]]; then
    echo >&2 "You must set the DEEPGRAM_TOKEN or OPEN_AI_TOKEN environment variable."
    exit 1
  fi
  set -u
}

main() {
  sanity_check

  if [[ -f "$PID_FILE" ]]; then
    stop_recording
    transcript
    write_transcript
  else
    start_recording
  fi
}

main
