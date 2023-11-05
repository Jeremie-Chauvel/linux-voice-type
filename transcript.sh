#! /bin/bash

set -eo pipefail
IFS=$'\n\t'

FILE=$1
if [[ -z "$FILE" ]]; then
  echo "Usage: $0 <filepath>"
  exit 1
fi

set -u
source "${HOME}/.openai-token"
curl --silent --request POST \
  --url https://api.openai.com/v1/audio/transcriptions \
  --header "Authorization: Bearer $TOKEN" \
  --header 'Content-Type: multipart/form-data' \
  --form file="@$FILE.wav" \
  --form model=whisper-1 \
  --form response_format=text \
  -o "${FILE}.txt"
