#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

./scripts/format.sh --check
./scripts/flutterw.sh analyze
./scripts/check_architecture.sh
python3 -I tool/decisions/test_decisions.py
python3 tool/decisions/decisions.py check
python3 -I tool/design/check_asset_promotion.py
./scripts/flutterw.sh test
./scripts/quality_sli_common.sh
