#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

# The shared toolkit is a separate repository and owns its own format gate.
source_files=()
while IFS= read -r -d '' source_file; do
  source_files+=("$source_file")
done < <(find lib test tool \
  -path 'lib/modules' -prune -o \
  -type f -name '*.dart' -print0)

if [[ "${1:-}" == "--check" ]]; then
  dart format --output=none --set-exit-if-changed "${source_files[@]}"
else
  dart format "${source_files[@]}"
fi
