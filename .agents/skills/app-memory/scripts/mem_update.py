#!/usr/bin/env python3
"""
Update an existing memory entry. Matches by --location (preferred) or --name.
Only provided fields are updated; others are preserved.

Usage:
    mem_update.py widget  --location lib/... --desc "Updated" [--props label,onPressed] [--keywords button,cta]
    mem_update.py widget  --name AppButton --group atoms --keywords button,primary
    mem_update.py validator  --location lib/... --desc "..." [--keywords email]
    mem_update.py utility    --name formatDate --keywords date,format,display
    mem_update.py model      --location lib/features/auth/data/models/auth_token_model.dart --model-type class [--keywords auth,token]
    mem_update.py entity     --location lib/shared/domain/entities/user.dart --fields id,email,name [--scope shared]
    mem_update.py api        --location lib/features/auth/data/datasources/auth_remote_datasource.dart --method POST --endpoint /api/auth/login
    mem_update.py route      --location lib/features/auth/auth_router.dart --path /login [--params id,token]
    mem_update.py bloc       --location lib/features/auth/presentation/bloc/auth_bloc.dart --bloc-type bloc [--state AuthState] [--events LoginEvent,LogoutEvent]
    mem_update.py extension  --location lib/core/utils/string_extension.dart --on String [--keywords string,util]
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

TYPE_TO_FILE: dict[str, str] = {
    "widget":    "widgets.json",
    "validator": "validators.json",
    "feature":   "features.json",
    "utility":   "utilities.json",
    "icon":      "icons.json",
    "model":     "models.json",
    "entity":    "entities.json",
    "api":       "apis.json",
    "route":     "routes.json",
    "bloc":      "blocs.json",
    "extension": "extensions.json",
}

VALID_TYPES = set(TYPE_TO_FILE.keys())


def find_memory_dir() -> Path:
    script_dir = Path(__file__).resolve().parent
    project_root = script_dir.parent.parent.parent.parent
    return project_root / ".agents" / "memories"


def parse_args(args: list[str]) -> dict:
    out: dict[str, str] = {}
    i = 0
    while i < len(args):
        if args[i].startswith("--") and i + 1 < len(args):
            key = args[i][2:].replace("-", "_")
            out[key] = args[i + 1]
            i += 2
        else:
            i += 1
    return out


def parse_list(value: str) -> list[str]:
    return [v.strip() for v in value.split(",") if v.strip()]


def main() -> int:
    args = sys.argv[1:]
    if len(args) < 2:
        print(__doc__)
        return 1

    mem_type = args[0].lower()
    if mem_type not in VALID_TYPES:
        print(f"Invalid type '{mem_type}'. Valid: {', '.join(sorted(VALID_TYPES))}")
        return 1

    parsed = parse_args(args[1:])
    if not parsed:
        print("Provide at least --location or --name to identify the entry to update.")
        return 1

    location = parsed.get("location")
    name     = parsed.get("name")
    if not location and not name:
        print("Required: --location or --name (to identify which entry to update)")
        return 1

    mem_dir = find_memory_dir()
    path = mem_dir / TYPE_TO_FILE[mem_type]
    if not path.exists():
        print(f"No {mem_type} memory found at {path}")
        return 1

    with open(path, encoding="utf-8") as f:
        data: list[dict] = json.load(f)

    idx = -1
    for i, entry in enumerate(data):
        if location and entry.get("location") == location:
            idx = i
            break
        if name and entry.get("name") == name:
            idx = i
            break

    if idx < 0:
        print(f"Not found: {location or name}")
        return 1

    e = data[idx]

    # Common fields
    if "name" in parsed:
        e["name"] = parsed["name"]
    if "desc" in parsed:
        e["description"] = parsed["desc"]
    if "location" in parsed:
        e["location"] = parsed["location"]
    if "keywords" in parsed:
        e["keywords"] = parse_list(parsed["keywords"])

    # widget / icon
    if mem_type in ("widget", "icon") and "props" in parsed:
        e["props"] = parse_list(parsed["props"])
    if mem_type == "widget":
        if "group" in parsed:
            e["group"] = parsed["group"]
        if "scope" in parsed:
            e["scope"] = parsed["scope"]

    # model
    if mem_type == "model" and "model_type" in parsed:
        e["model_type"] = parsed["model_type"]

    # entity
    if mem_type == "entity":
        if "fields" in parsed:
            e["fields"] = parse_list(parsed["fields"])
        if "scope" in parsed:
            e["scope"] = parsed["scope"]

    # api
    if mem_type == "api":
        if "method" in parsed:
            e["method"] = parsed["method"].upper()
        if "endpoint" in parsed:
            e["endpoint"] = parsed["endpoint"]
        if "feature" in parsed:
            e["feature"] = parsed["feature"]

    # route
    if mem_type == "route":
        if "path" in parsed:
            e["path"] = parsed["path"]
        if "feature" in parsed:
            e["feature"] = parsed["feature"]
        if "params" in parsed:
            e["params"] = parse_list(parsed["params"])

    # bloc
    if mem_type == "bloc":
        if "bloc_type" in parsed:
            e["bloc_type"] = parsed["bloc_type"]
        if "feature" in parsed:
            e["feature"] = parsed["feature"]
        if "state" in parsed:
            e["state"] = parsed["state"]
        if "events" in parsed:
            e["events"] = parse_list(parsed["events"])

    # extension
    if mem_type == "extension" and "on" in parsed:
        e["on"] = parsed["on"]

    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

    print(f"Updated [{mem_type}] {e['name']} -> {e['location']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
