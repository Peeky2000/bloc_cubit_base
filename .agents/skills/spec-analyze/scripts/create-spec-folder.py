#!/usr/bin/env python3
"""Creates a new spec folder and fe.md from the spec template (do not create manually).
Usage: from project root, run:
    python .agents/skills/spec-analyze/scripts/create-spec-folder.py <kebab-case-name>
Example:
    python .agents/skills/spec-analyze/scripts/create-spec-folder.py dashboard
    → creates docs/specs/011-dashboard/fe.md and docs/specs/011-dashboard/references/
Next number is computed from existing docs/specs/NNN-* folders.
"""

import sys
import re
import shutil
from pathlib import Path

def main():
    if len(sys.argv) < 2:
        print("Usage: create-spec-folder.py <kebab-case-name>", file=sys.stderr)
        sys.exit(1)

    name = sys.argv[1]
    script_dir = Path(__file__).resolve().parent
    # Project root: from scripts/ go up spec-analyze -> skills -> .agents -> app root
    root_dir = (script_dir / ".." / ".." / ".." / "..").resolve()
    specs_dir = root_dir / "docs" / "specs"
    template = script_dir / ".." / "templates" / "spec-fe-template.md"

    if not template.is_file():
        print(f"Error: Template not found: {template}", file=sys.stderr)
        sys.exit(1)

    specs_dir.mkdir(parents=True, exist_ok=True)

    next_num = 1
    pattern = re.compile(r"^(\d{3})-")
    if specs_dir.is_dir():
        for d in specs_dir.iterdir():
            if not d.is_dir():
                continue
            m = pattern.match(d.name)
            if m:
                n = int(m.group(1))
                if n >= next_num:
                    next_num = n + 1

    prefix = f"{next_num:03d}"
    spec_dir = specs_dir / f"{prefix}-{name}"
    ref_dir = spec_dir / "references"
    fe_md = spec_dir / "fe.md"

    ref_dir.mkdir(parents=True, exist_ok=True)
    shutil.copy(template, fe_md)

    print(f"Created: {fe_md}")
    print(f"Spec dir: {spec_dir}")
    print(f"References: {ref_dir}")

if __name__ == "__main__":
    main()
