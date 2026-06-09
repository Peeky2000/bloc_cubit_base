#!/usr/bin/env bash
# Creates checklist files from template for a given part. Agent provides entity names (no parsing of fe.md).
# Usage (from project root):
#   ./.agents/skills/spec-checklists/scripts/create-checklist-files.sh <spec-dir-or-fe.md> <part> [entity1 entity2 ...]
#   If no entities after <part>, read one entity per line from stdin.
# Example:
#   ./.agents/skills/spec-checklists/scripts/create-checklist-files.sh docs/specs/007-financial-report api get-income-summary get-expense-summary get-report-breakdown get-spending-trend
#   echo -e "user\ncategory" | ./.agents/skills/spec-checklists/scripts/create-checklist-files.sh docs/specs/001-foo data-model
# Parts: entity | data-model | repository | api | route | validation | utility | component | bloc-cubit | page

set -e

INPUT="${1:?Usage: create-checklist-files.sh <spec-dir-or-fe.md> <part> [entity1 entity2 ...]}"
PART="${2:?Usage: create-checklist-files.sh <spec-dir-or-fe.md> <part> [entity1 entity2 ...]}"
shift 2

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TEMPLATES_DIR="${ROOT_DIR}/.agents/skills/spec-checklists/templates/checklists"

VALID_PARTS="entity data-model repository api route validation utility component bloc-cubit page"
if ! echo " $VALID_PARTS " | grep -q " $PART "; then
  echo "Error: part must be one of: $VALID_PARTS" >&2
  exit 1
fi

# Resolve spec dir
if [ "${INPUT#/}" = "$INPUT" ]; then
  INPUT="${ROOT_DIR}/${INPUT}"
fi
if [ -f "$INPUT" ]; then
  SPEC_DIR="$(cd "$(dirname "$INPUT")" && pwd)"
elif [ -d "$INPUT" ]; then
  SPEC_DIR="$(cd "$INPUT" && pwd)"
else
  echo "Error: Not a file or directory: $INPUT" >&2
  exit 1
fi

FE_MD="${SPEC_DIR}/fe.md"
if [ ! -f "$FE_MD" ]; then
  echo "Error: fe.md not found in spec dir: $SPEC_DIR" >&2
  exit 1
fi

CHECKLISTS_DIR="${SPEC_DIR}/checklists"
TEMPLATE="${TEMPLATES_DIR}/${PART}.md"
if [ ! -f "$TEMPLATE" ]; then
  echo "Error: Template not found: $TEMPLATE" >&2
  exit 1
fi

# Entity names: from args or stdin (one per line)
ENTITIES=()
if [ $# -ge 1 ]; then
  ENTITIES=("$@")
else
  while IFS= read -r line; do
    line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    [ -n "$line" ] && ENTITIES+=("$line")
  done
fi

if [ ${#ENTITIES[@]} -eq 0 ]; then
  echo "Usage: provide entity names as args or stdin (one per line). No entities given." >&2
  exit 1
fi

# Placeholder in template (per part) — replace with entity name in generated file
case "$PART" in
  entity)       PLACEHOLDER="{entity-name}" ;;
  data-model)   PLACEHOLDER="{model-name}" ;;
  repository)   PLACEHOLDER="{repository-name}" ;;
  api)          PLACEHOLDER="{api-name}" ;;
  route)        PLACEHOLDER="{route-name}" ;;
  validation)   PLACEHOLDER="{form-name}" ;;
  utility)      PLACEHOLDER="{util-name}" ;;
  component)    PLACEHOLDER="{widget-name}" ;;
  bloc-cubit)   PLACEHOLDER="{bloc-cubit-name}" ;;
  page)         PLACEHOLDER="{page-name}" ;;
  *)            PLACEHOLDER="{entity}" ;;
esac

mkdir -p "${CHECKLISTS_DIR}/${PART}"
CREATED=()
for entity in "${ENTITIES[@]}"; do
  dest="${CHECKLISTS_DIR}/${PART}/${entity}.md"
  cp "$TEMPLATE" "$dest"
  # Replace placeholder with entity name (portable: no -i on macOS)
  if [ -n "$PLACEHOLDER" ]; then
    sed "s|${PLACEHOLDER}|${entity}|g" "$dest" > "${dest}.tmp" && mv "${dest}.tmp" "$dest"
  fi
  CREATED+=("$dest")
done

echo "Created ${#CREATED[@]} file(s) in ${CHECKLISTS_DIR}/${PART}/"
for f in "${CREATED[@]}"; do echo "  $f"; done
