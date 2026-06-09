#!/usr/bin/env bash
# Creates the checklists folder structure under a spec directory (do not create manually).
# Usage: from project root, run:
#   ./.agents/skills/spec-checklists/scripts/create-checklists-dir.sh <spec-dir-or-fe.md>
# Examples:
#   ./.agents/skills/spec-checklists/scripts/create-checklists-dir.sh docs/specs/001-home-new-user
#   ./.agents/skills/spec-checklists/scripts/create-checklists-dir.sh docs/specs/001-home-new-user/fe.md
# → creates docs/specs/001-home-new-user/checklists/{entity,data-model,repository,api,route,validation,utility,component,bloc-cubit,page}/
#   and docs/specs/001-home-new-user/checklists/summarize.md (placeholder).

set -e

INPUT="${1:?Usage: create-checklists-dir.sh <spec-dir-or-fe.md>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"

# Resolve input relative to project root if not absolute
if [ "${INPUT#/}" = "$INPUT" ]; then
  INPUT="${ROOT_DIR}/${INPUT}"
fi

# Resolve to absolute spec dir
if [ -f "$INPUT" ]; then
  SPEC_DIR="$(cd "$(dirname "$INPUT")" && pwd)"
elif [ -d "$INPUT" ]; then
  SPEC_DIR="$(cd "$INPUT" && pwd)"
else
  echo "Error: Not a file or directory: $INPUT" >&2
  exit 1
fi

# Require fe.md in spec dir
FE_MD="${SPEC_DIR}/fe.md"
if [ ! -f "$FE_MD" ]; then
  echo "Error: fe.md not found in spec dir: $SPEC_DIR" >&2
  exit 1
fi

CHECKLISTS_DIR="${SPEC_DIR}/checklists"
PARTS="entity data-model repository api route validation utility component bloc-cubit page"

for part in $PARTS; do
  mkdir -p "${CHECKLISTS_DIR}/${part}"
done

# Placeholder summarize
SPEC_NAME="$(basename "$SPEC_DIR")"
SUMMARIZE="${CHECKLISTS_DIR}/summarize.md"
if [ ! -f "$SUMMARIZE" ]; then
  cat > "$SUMMARIZE" << EOF
# Implementation checklists — ${SPEC_NAME}

Checklists for this spec. Order = suggested implementation sequence (Flutter Clean Architecture layers).

> Create checklists for **Create new** or when **modifications are needed** (widget, utility, validator). Skip when **Reuse with no modifications**. Entity, Model, Repository, BLoC/Cubit: always create to verify structure.

---

## Entity

<!-- Add: - [ ] [entity-name](entity/entity-name.md) -->

## Model

<!-- Add: - [ ] [model-name](data-model/model-name.md) -->

## Repository

<!-- Add: - [ ] [repository-name](repository/repository-name.md) -->

## API

<!-- Add: - [ ] [api-name](api/api-name.md) -->

## Route

<!-- Add: - [ ] [route-name](route/route-name.md) -->

## Validation

<!-- Add: - [ ] [validation-name](validation/validation-name.md) -->

## Utility

<!-- Add: - [ ] [utility-name](utility/utility-name.md) -->

## Widget

<!-- Add: - [ ] [widget-name](component/widget-name.md) -->

## BLoC / Cubit

<!-- Add: - [ ] [bloc-cubit-name](bloc-cubit/bloc-cubit-name.md) -->

## Page

<!-- Add: - [ ] [page-name](page/page-name.md) -->
EOF
fi

echo "Created: ${CHECKLISTS_DIR}"
echo "Subdirs: ${PARTS}"
echo "Summarize: ${SUMMARIZE}"
