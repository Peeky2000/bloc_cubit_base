#!/usr/bin/env python3
"""Creates a new doc review file from template.
Usage: from project root, run:
    python .agents/skills/spec-analyze/scripts/create-review-file.py <spec-path>
Examples:
    python .agents/skills/spec-analyze/scripts/create-review-file.py docs/specs/009-add-transaction-pink
"""

import sys
import os
from pathlib import Path
from datetime import datetime

def main():
    if len(sys.argv) < 2:
        print("Usage: create-review-file.py <spec-path>", file=sys.stderr)
        sys.exit(1)

    spec_path = sys.argv[1]
    script_dir = Path(__file__).resolve().parent
    tpl_file = script_dir / ".." / "templates" / "review-file-template.md"

    root_dir = Path.cwd()
    reviews_dir = root_dir / spec_path / "reviews"
    spec_name = Path(spec_path).name
    reviews_dir.mkdir(parents=True, exist_ok=True)

    now = datetime.now()
    filename = now.strftime("doc-%Y-%m-%d-%H-%M-%S.md")
    output_file = reviews_dir / filename
    date_time = now.strftime("%Y-%m-%d %H:%M")

    template = tpl_file.read_text(encoding="utf-8")
    content = (
        template
        .replace("{{SPEC_PATH}}", spec_path)
        .replace("{{DATE_TIME}}", date_time)
        .replace("{{SPEC_NAME}}", spec_name)
    )
    output_file.write_text(content, encoding="utf-8")

    print(f"Created: {output_file}")

if __name__ == "__main__":
    main()
