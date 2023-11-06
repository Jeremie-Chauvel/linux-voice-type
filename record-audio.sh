#!/usr/bin/env bash

# /usage exec ./record-audio.sh twice to start and stop recording
set -euo pipefail
IFS=$'\n\t'

readonly PID_FILE="${HOME}/.recordpid"
readonly FILE="${HOME}/.voice-type/recording"
readonly MAX_DURATION=15

early_exit_if_command_not_found() {
  set +u
  local command_name="$1"
  set -u
  set +e
  is_command "$command_name"
  result_status="$?"
  set -e
  if [ "$result_status" -gt '0' ]; then
    echo "command $command_name not found, install it or make it available in path"
    exit 1
  fi
}

start_recording() {
  mkdir -p "$(dirname "$FILE")"
  echo "aaa" >"$PID_FILE"
  nohup arecord --device=hw:0,0 --format cd "$FILE.wav" --duration="$MAX_DURATION" &>/dev/null &
}

stop_recording() {
  set +e
  killall -w arecord
  set -e
  rm -f "$PID_FILE"
}

write_transcript() {
  perl -pi -e 'chomp if eof' "$FILE.txt"
  xdotool type --clearmodifiers --file "$FILE.txt"
}

transcript() {

  if [[ -z "$DEEPGRAM_TOKEN" ]]; then
    curl --silent --request POST \
      --url https://api.openai.com/v1/audio/transcriptions \
      --header "Authorization: Bearer $OPEN_AI_TOKEN" \
      --header 'Content-Type: multipart/form-data' \
      --form file="@$FILE.wav" \
      --form model=whisper-1 \
      --form response_format=text \
      -o "${FILE}.txt"
    return 0
  fi
  curl --silent \
    --request POST \
    --header "Authorization: Token $DEEPGRAM_TOKEN" \
    --header 'Content-Type: audio/wav' \
    --data-binary "@$FILE.wav" \
    --url 'https://api.deepgram.com/v1/listen?smart_format=true&keywords=NodeJs&keywords=Java&keywords=React&keywords=NextJs&keywords=pnpm&keywords=TF1&keywords=Altar' \
    -o "${FILE}.json"
  jq '.results.channels[0].alternatives[0].transcript' -r "${FILE}.json" >"${FILE}.txt"

}

sanity_check() {
  early_exit_if_command_not_found "xdotool"
  early_exit_if_command_not_found "arecord"
  early_exit_if_command_not_found "killall"
  early_exit_if_command_not_found "jq"
  early_exit_if_command_not_found "curl"

  source "$HOME/.ai-token"

  if [[ -z "$DEEPGRAM_TOKEN" ]] && [[ -z "$OPEN_AI_TOKEN" ]]; then
    echo "You must set the DEEPGRAM_TOKEN or OPEN_AI_TOKEN environment variable."
    exit 1
  fi

}

main() {
  sanity_check

  if [[ -f "$PID_FILE" ]]; then
    echo "Recording ongoing, stopping..."
    stop_recording
    transcript
    write_transcript
  else
    echo "No recording ongoing, starting a new recording..."
    start_recording
  fi
}

main
