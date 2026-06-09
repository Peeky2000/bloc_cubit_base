#!/usr/bin/env bash
# Creates a new doc review file from template.
# Usage: from project root, run:
#   ./.agents/skills/spec-analyze/scripts/create-review-file.sh <spec-path>
# Examples:
#   ./.agents/skills/spec-analyze/scripts/create-review-file.sh docs/specs/009-add-transaction-pink

set -e

SPEC_PATH="${1:?Usage: create-review-file.sh <spec-path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TPL_FILE="${SCRIPT_DIR}/../templates/review-file-template.md"

ROOT_DIR="$(pwd)"
REVIEWS_DIR="${ROOT_DIR}/${SPEC_PATH}/reviews"
SPEC_NAME="$(basename "$SPEC_PATH")"
mkdir -p "$REVIEWS_DIR"

# Filename: doc-YYYY-MM-DD-HH-mm-ss.md
FILENAME="doc-$(date +%Y-%m-%d-%H-%M-%S).md"
OUTPUT_FILE="${REVIEWS_DIR}/${FILENAME}"

DATE_TIME="$(date +%Y-%m-%d\ %H:%M)"

sed -e "s|{{SPEC_PATH}}|${SPEC_PATH}|g" \
    -e "s|{{DATE_TIME}}|${DATE_TIME}|g" \
    -e "s|{{SPEC_NAME}}|${SPEC_NAME}|g" \
    "$TPL_FILE" > "$OUTPUT_FILE"

echo "Created: ${OUTPUT_FILE}"
