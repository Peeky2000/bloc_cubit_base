#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

if command -v fvm >/dev/null 2>&1; then
  exec fvm flutter "$@"
fi

exec flutter "$@"
