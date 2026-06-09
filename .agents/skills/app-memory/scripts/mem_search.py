#!/usr/bin/env python3
"""
Search app memory by query. Reads from .agents/memory/*.json.

Tokenizes the query into individual keywords, scores each entry by how many
tokens match (across name, description, keywords, location, props, etc.), and
returns results ranked by relevance (most matches first).

Usage:
    mem_search.py <query> [--type widget|validator|feature|utility|icon|model|entity|api|route|bloc|extension] [--path /path/to/memory/dir]

Examples:
    mem_search.py "button primary"
    mem_search.py "email validator" --type validator
    mem_search.py "user entity domain" --type entity
    mem_search.py "login route path" --type route
    mem_search.py "auth bloc state" --type bloc
    mem_search.py "string extension" --type extension
    mem_search.py "fetch user list" --type api
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

STOPWORDS = {"and", "or", "the", "is", "a", "an", "in", "on", "at", "to", "for", "of", "with", "by", "it", "its"}

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


def find_memory_dir(custom_path: str | None) -> Path:
    if custom_path:
        return Path(custom_path).resolve()
    script_dir = Path(__file__).resolve().parent
    project_root = script_dir.parent.parent.parent.parent
    return project_root / ".agents" / "memories"


def load_memory(mem_dir: Path) -> dict:
    data: dict[str, list] = {}
    for key, filename in TYPE_TO_FILE.items():
        path = mem_dir / filename
        if path.exists():
            with open(path, encoding="utf-8") as f:
                data[key] = json.load(f)
        else:
            data[key] = []
    return data


def tokenize(text: str) -> list[str]:
    raw = re.split(r"[\s\-_/.,;:!?()]+", text.lower())
    return [t for t in raw if len(t) > 1 and t not in STOPWORDS]


def entry_text(entry: dict) -> str:
    parts: list[str] = [
        entry.get("name", ""),
        entry.get("description", ""),
        entry.get("location", ""),
        entry.get("group", ""),
        entry.get("method", ""),
        entry.get("endpoint", ""),
        entry.get("model_type", ""),
        entry.get("bloc_type", ""),
        entry.get("path", ""),
        entry.get("feature", ""),
        entry.get("scope", ""),
        entry.get("on", ""),
        entry.get("state", ""),
    ]
    for field in ("props", "keywords", "groups", "fields", "params", "events"):
        val = entry.get(field, [])
        if isinstance(val, list):
            parts.extend(str(v) for v in val)
        elif val:
            parts.append(str(val))
    return " ".join(parts).lower()


def score(text: str, tokens: list[str]) -> int:
    return sum(1 for t in tokens if t in text)


def search(data: dict, query: str, type_filter: str | None) -> list[dict]:
    tokens = tokenize(query)
    if not tokens:
        return []

    keys = [type_filter] if type_filter and type_filter in TYPE_TO_FILE else list(TYPE_TO_FILE.keys())

    results: list[dict] = []
    for key in keys:
        for entry in data.get(key, []):
            text = entry_text(entry)
            s = score(text, tokens)
            if s > 0:
                results.append({**entry, "_type": key, "_score": s})

    results.sort(key=lambda x: (-x["_score"], x.get("name", "").lower()))
    return results


def format_result(h: dict) -> str:
    t    = h.get("_type", "?")
    s    = h.get("_score", 0)
    name = h.get("name", "?")
    loc  = h.get("location", "")
    desc = h.get("description", "")
    kw   = h.get("keywords", [])

    lines = [f"[{t}] {name}  (score: {s})"]
    lines.append(f"  location : {loc}")
    if desc:
        short = desc if len(desc) <= 100 else desc[:100] + "..."
        lines.append(f"  desc     : {short}")
    if kw:
        lines.append(f"  keywords : {', '.join(kw) if isinstance(kw, list) else kw}")

    # type-specific extras
    if h.get("method"):
        lines.append(f"  method   : {h['method']}  {h.get('endpoint', '')}")
    if h.get("props"):
        lines.append(f"  props    : {', '.join(h['props'])}")
    if h.get("model_type"):
        lines.append(f"  type     : {h['model_type']}")
    if h.get("fields"):
        lines.append(f"  fields   : {', '.join(h['fields'])}")
    if h.get("scope"):
        lines.append(f"  scope    : {h['scope']}")
    if h.get("path"):
        lines.append(f"  path     : {h['path']}")
    if h.get("params"):
        lines.append(f"  params   : {', '.join(h['params'])}")
    if h.get("bloc_type"):
        lines.append(f"  bloc_type: {h['bloc_type']}")
    if h.get("state"):
        lines.append(f"  state    : {h['state']}")
    if h.get("events"):
        lines.append(f"  events   : {', '.join(h['events'])}")
    if h.get("on"):
        lines.append(f"  on       : {h['on']}")
    if h.get("feature"):
        lines.append(f"  feature  : {h['feature']}")

    return "\n".join(lines)


def main() -> int:
    args = sys.argv[1:]
    if not args:
        print("Usage: mem_search.py <query> [--type TYPE] [--path PATH]")
        return 1

    query = args[0]
    type_filter: str | None = None
    custom_path: str | None = None

    i = 1
    while i < len(args):
        if args[i] == "--type" and i + 1 < len(args):
            type_filter = args[i + 1].lower()
            i += 2
        elif args[i] == "--path" and i + 1 < len(args):
            custom_path = args[i + 1]
            i += 2
        else:
            i += 1

    if type_filter and type_filter not in TYPE_TO_FILE:
        print(f"Unknown type '{type_filter}'. Valid: {', '.join(TYPE_TO_FILE)}")
        return 1

    mem_dir = find_memory_dir(custom_path)
    data    = load_memory(mem_dir)
    hits    = search(data, query, type_filter)

    if not hits:
        print("No matches found.")
        return 0

    tokens = tokenize(query)
    print(f"Query tokens: {tokens}")
    print(f"Found {len(hits)} result(s), ranked by relevance:\n")
    for h in hits:
        print(format_result(h))
        print()

    return 0


if __name__ == "__main__":
    sys.exit(main())
