#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

git submodule sync --recursive
git submodule update --init --recursive
./scripts/flutterw.sh pub get
./scripts/generate.sh
