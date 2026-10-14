#!/usr/bin/env python3
"""Asset từ design package (The Forge contract 0.2) chỉ vào app qua ASSET-PROMOTION.json, hash nguồn và đích phải khớp."""
from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> int:
    errors = []
    for record in sorted((ROOT / "docs/specs").glob("*/design/*/ASSET-PROMOTION.json")):
        design = record.parent
        try:
            entries = json.loads(record.read_text(encoding="utf-8"))
        except ValueError as error:
            errors.append(f"{record}: JSON hỏng — {error}")
            continue
        for e in entries if isinstance(entries, list) else []:
            src, dest = design / str(e.get("source", "")), ROOT / str(e.get("dest", ""))
            if not str(e.get("dest", "")).startswith("assets/"):
                errors.append(f"{record.relative_to(ROOT)}: dest phải trong assets/ — {e.get('dest')}")
            elif not src.is_file() or sha(src) != e.get("sourceHash"):
                errors.append(f"{record.relative_to(ROOT)}: nguồn {e.get('source')} mất hoặc khác sourceHash")
            elif not dest.is_file() or sha(dest) != e.get("destHash"):
                errors.append(f"{record.relative_to(ROOT)}: đích {e.get('dest')} mất hoặc khác destHash")
        if not isinstance(entries, list):
            errors.append(f"{record.relative_to(ROOT)}: phải là danh sách")
    for line in errors:
        print("✗ " + line)
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
