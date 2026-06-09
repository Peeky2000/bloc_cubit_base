#!/usr/bin/env python3
"""
Generate a spec folder slug from a short description and optional keywords/type.
Output is kebab-case, unique against existing docs/specs/NNN-* folders.
Usage (from project root):
  python3 .agents/skills/spec-analyze/scripts/generate-spec-name.py --description "Transaction list, light" [--keywords "screen,light"] [--type new-screen]
"""

import argparse
import os
import re
import sys


# Spec types that add a prefix to the slug
PREFIX_TYPES = ("fix-design", "fix-logic", "refactor")

# Theme keywords that may become suffix
THEME_KEYWORDS = ("light", "dark", "pink")


def normalize_to_slug(text: str) -> str:
    """Lowercase, replace non-alphanumeric with hyphen, collapse hyphens, strip."""
    s = (text or "").lower().strip()
    s = re.sub(r"[^a-z0-9\s-]", "", s)
    s = re.sub(r"[\s_]+", "-", s)
    s = re.sub(r"-+", "-", s).strip("-")
    return s


def slug_to_title(slug: str) -> str:
    """Convert kebab-case slug to Title Case for fe.md."""
    return " ".join(w.capitalize() for w in slug.split("-"))


def existing_slugs(specs_dir: str) -> set[str]:
    """Return set of existing slugs (without NNN prefix) in docs/specs/."""
    out = set()
    if not os.path.isdir(specs_dir):
        return out
    for name in os.listdir(specs_dir):
        path = os.path.join(specs_dir, name)
        if not os.path.isdir(path):
            continue
        # NNN-name -> name
        if re.match(r"^\d{3}-", name):
            out.add(name[4:])
    return out


def ensure_unique(slug: str, existing: set[str]) -> str:
    """If slug exists, append -v2, -v3, ... until unique."""
    if slug not in existing:
        return slug
    i = 2
    while f"{slug}-v{i}" in existing:
        i += 1
    return f"{slug}-v{i}"


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generate spec folder slug from description and optional keywords/type."
    )
    parser.add_argument(
        "--description",
        required=True,
        help="Short English description (e.g. 'Transaction list screen, light mode').",
    )
    parser.add_argument(
        "--keywords",
        default="",
        help="Comma-separated keywords (e.g. 'screen,list,transaction,light').",
    )
    parser.add_argument(
        "--type",
        choices=("new-screen", "new-component", "new-logic", "fix-design", "fix-logic", "refactor"),
        default=None,
        help="Spec type; fix-design, fix-logic, refactor add a prefix to the slug.",
    )
    parser.add_argument(
        "--no-unique-check",
        action="store_true",
        help="Skip uniqueness check against docs/specs/.",
    )
    args = parser.parse_args()

    # Resolve docs/specs dir (script lives in .agents/skills/spec-analyze/scripts/)
    script_dir = os.path.dirname(os.path.abspath(__file__))
    root_dir = os.path.normpath(os.path.join(script_dir, "..", "..", "..", ".."))
    specs_dir = os.path.join(root_dir, "docs", "specs")

    # Base slug from description
    slug = normalize_to_slug(args.description)
    if not slug:
        print("Error: description produced an empty slug.", file=sys.stderr)
        raise SystemExit(1)

    # Optional prefix by type
    if args.type and args.type in PREFIX_TYPES:
        prefix = args.type
        if not slug.startswith(prefix + "-"):
            slug = f"{prefix}-{slug}"

    # Optional theme suffix from keywords (at most one); skip if slug already contains that theme
    kw = [k.strip().lower() for k in args.keywords.split(",") if k.strip()]
    for theme in THEME_KEYWORDS:
        if theme in kw and theme not in slug:
            slug = f"{slug}-{theme}"
            break

    # Uniqueness
    if not args.no_unique_check:
        existing = existing_slugs(specs_dir)
        slug = ensure_unique(slug, existing)

    suggested_title = slug_to_title(slug)
    print(slug)
    print(f"# Suggested title for fe.md: {suggested_title}", file=sys.stderr)


if __name__ == "__main__":
    main()
