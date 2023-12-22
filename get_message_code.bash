#!/bin/bash

createFolderAndFile() {
  mkdir -p "assets/server_localization"
  touch "assets/server_localization/message_en.json"
  touch "assets/server_localization/message_vi.json"
}

getMessageCodeEn() {
  arrUrlServerCode=(
    "http://localhost:5001/api/v1/localization/message_en.json"
  )
  truncate -s0 assets/server_localization/message_en.json
  jsonEn=""
  for i in "${!arrUrlServerCode[@]}"; do
    var=$(curl -s "${arrUrlServerCode[i]}" | jq | tr -d '{-}')
    if ((i > 0)); then
      jsonEn+=$',\n'
    fi
    jsonEn+="$var"
    jsonEn+=$'\n'
  done
  echo "{$jsonEn}" | jq >> assets/server_localization/message_en.json
}

getMessageCodeVi() {
  arrUrlServerCode=(
      "http://localhost:5001/api/v1/localization/message_vi.json"
    )
    truncate -s0 assets/server_localization/message_vi.json
    jsonVi=""
    for i in "${!arrUrlServerCode[@]}"; do
      var=$(curl -s "${arrUrlServerCode[i]}" | jq | tr -d '{-}')
      if ((i > 0)); then
        jsonVi+=$',\n'
      fi
      jsonVi+="$var"
      jsonVi+=$'\n'
    done
    echo "{$jsonVi}" | jq >> assets/server_localization/message_vi.json
}

if [ -d ./assets/server_localization ]; then
  if [ -f ./assets/server_localization/message_en.json ]; then
    getMessageCodeEn
  else
    touch "assets/server_localization/message_en.json"
    getMessageCodeEn
  fi
  if [ -f ./assets/server_localization/message_vi.json ]; then
    getMessageCodeVi
  else
    touch "assets/server_localization/message_vi.json"
    getMessageCodeVi
  fi
else
  createFolderAndFile
  getMessageCodeEn
  getMessageCodeVi
fi