#!/usr/bin/env bash
# Creates a new spec folder and fe.md from the spec template (do not create manually).
# Usage: from project root, run:
#   ./.agents/skills/spec-analyze/scripts/create-spec-folder.sh <kebab-case-name>
# Example:
#   ./.agents/skills/spec-analyze/scripts/create-spec-folder.sh dashboard
#   → creates docs/specs/011-dashboard/fe.md and docs/specs/011-dashboard/references/
# Next number is computed from existing docs/specs/NNN-* folders.

set -e

NAME="${1:?Usage: create-spec-folder.sh <kebab-case-name>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# Project root: from scripts/ go up spec-analyze -> skills -> .agents -> app root
ROOT_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
SPECS_DIR="${ROOT_DIR}/docs/specs"
TEMPLATE="${SCRIPT_DIR}/../templates/spec-fe-template.md"

if [ ! -f "$TEMPLATE" ]; then
  echo "Error: Template not found: $TEMPLATE" >&2
  exit 1
fi

mkdir -p "$SPECS_DIR"
# Next number: list NNN-* dirs, take max N, +1, zero-pad 3
NEXT=1
if [ -d "$SPECS_DIR" ]; then
  for d in "$SPECS_DIR"/[0-9][0-9][0-9]-*; do
    [ -d "$d" ] || continue
    n="${d##*/}"
    n="${n%%-*}"
    n=$((10#$n))
    [ "$n" -ge "$NEXT" ] && NEXT=$((n + 1))
  done
fi
PREFIX="$(printf '%03d' "$NEXT")"
SPEC_DIR="${SPECS_DIR}/${PREFIX}-${NAME}"
REF_DIR="${SPEC_DIR}/references"
FE_MD="${SPEC_DIR}/fe.md"

mkdir -p "$REF_DIR"
cp "$TEMPLATE" "$FE_MD"

echo "Created: ${FE_MD}"
echo "Spec dir: ${SPEC_DIR}"
echo "References: ${REF_DIR}"
