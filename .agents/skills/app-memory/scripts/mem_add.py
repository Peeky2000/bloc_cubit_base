#!/usr/bin/env python3
"""
Add a memory entry to .agents/memories/{type}s.json.

Usage:
    mem_add.py widget     --name AppButton --desc "..." --location lib/... [--props label,onPressed] [--group atoms] [--scope shared] [--keywords button,cta]
    mem_add.py widget     --name LoginForm --desc "..." --location lib/features/auth/presentation/widgets/login_form.dart [--props onSubmit] [--scope auth] [--keywords login,form]
    mem_add.py validator  --name emailValidator --desc "..." --location lib/... [--keywords email,validation]
    mem_add.py feature    --name auth --desc "..." --location lib/features/auth/ [--keywords login,register]
    mem_add.py utility    --name formatDate --desc "..." --location lib/core/utils/format_date.dart [--keywords date,format]
    mem_add.py icon       --name ArrowIcon --desc "..." --location lib/shared/presentation/design_system/atoms/icons/arrow_icon.dart [--props color,size]
    mem_add.py model      --name AuthTokenModel --desc "..." --location lib/features/auth/data/models/auth_token_model.dart [--model-type class] [--keywords auth,token]
    mem_add.py entity     --name UserEntity --desc "..." --location lib/shared/domain/entities/user.dart [--fields id,email,name] [--scope shared] [--keywords user,domain]
    mem_add.py api        --name loginApi --desc "..." --location lib/features/auth/data/datasources/auth_remote_datasource.dart --method POST --endpoint /api/auth/login [--keywords auth,login]
    mem_add.py route      --name loginRoute --desc "..." --location lib/features/auth/auth_router.dart --path /login [--feature auth] [--keywords auth,login,nav]
    mem_add.py bloc       --name AuthBloc --desc "..." --location lib/features/auth/presentation/bloc/auth_bloc.dart [--bloc-type bloc] [--feature auth] [--keywords auth,state]
    mem_add.py extension  --name StringExtension --desc "..." --location lib/core/utils/string_extension.dart --on String [--keywords string,util]
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
    missing = [f for f in ("name", "desc", "location") if f not in parsed]
    if missing:
        print(f"Required flags missing: {', '.join('--' + m for m in missing)}")
        return 1

    if mem_type == "api" and "method" not in parsed:
        print("api type requires --method (GET|POST|PUT|PATCH|DELETE)")
        return 1

    if mem_type == "extension" and "on" not in parsed:
        print("extension type requires --on (e.g. String, BuildContext, int)")
        return 1

    mem_dir = find_memory_dir()
    mem_dir.mkdir(parents=True, exist_ok=True)

    path = mem_dir / TYPE_TO_FILE[mem_type]
    data: list[dict] = []
    if path.exists():
        with open(path, encoding="utf-8") as f:
            data = json.load(f)

    entry: dict = {
        "type":        mem_type,
        "name":        parsed["name"],
        "description": parsed["desc"],
        "location":    parsed["location"],
    }

    if "keywords" in parsed:
        entry["keywords"] = parse_list(parsed["keywords"])

    # widget / icon
    if mem_type in ("widget", "icon") and "props" in parsed:
        entry["props"] = parse_list(parsed["props"])
    if mem_type == "widget":
        if "group" in parsed:
            entry["group"] = parsed["group"]
        if "scope" in parsed:
            entry["scope"] = parsed["scope"]

    # model
    if mem_type == "model" and "model_type" in parsed:
        entry["model_type"] = parsed["model_type"]

    # entity
    if mem_type == "entity":
        if "fields" in parsed:
            entry["fields"] = parse_list(parsed["fields"])
        if "scope" in parsed:
            entry["scope"] = parsed["scope"]

    # api
    if mem_type == "api":
        entry["method"]   = parsed["method"].upper()
        entry["endpoint"] = parsed.get("endpoint", "")
        if "feature" in parsed:
            entry["feature"] = parsed["feature"]

    # route
    if mem_type == "route":
        entry["path"] = parsed.get("path", "")
        if "feature" in parsed:
            entry["feature"] = parsed["feature"]
        if "params" in parsed:
            entry["params"] = parse_list(parsed["params"])

    # bloc
    if mem_type == "bloc":
        entry["bloc_type"] = parsed.get("bloc_type", "cubit")
        if "feature" in parsed:
            entry["feature"] = parsed["feature"]
        if "state" in parsed:
            entry["state"] = parsed["state"]
        if "events" in parsed:
            entry["events"] = parse_list(parsed["events"])

    # extension
    if mem_type == "extension":
        entry["on"] = parsed["on"]

    data.append(entry)

    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

    print(f"Added [{mem_type}] {entry['name']} -> {entry['location']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
