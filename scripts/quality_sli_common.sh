#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
toolkit_root="$project_root/lib/modules/sli_common"

if [[ ! -f "$toolkit_root/pubspec.yaml" ]]; then
  echo "Missing sli_common submodule. Run: git submodule update --init --recursive" >&2
  exit 1
fi

cd "$toolkit_root"

if command -v fvm >/dev/null 2>&1; then
  fvm dart format --output=none --set-exit-if-changed lib test example/lib
  fvm flutter analyze
  fvm flutter test
else
  dart format --output=none --set-exit-if-changed lib test example/lib
  flutter analyze
  flutter test
fi
