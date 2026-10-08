#!/usr/bin/env python3
"""Decision log for the dev team: create, search and index decisions.

Feature-level decisions live in docs/decisions/D-NNNN-<slug>.md.
Project-wide decisions are ADRs in docs/adr/NNNN-<slug>.md.
Both are indexed into docs/decisions/README.md so agents and people find a
past decision before making a new one.

Usage:
  decisions.py new "<title>" [--scope feature|project] [--tags a,b] [--feature x]
  decisions.py search "<query>" [--all]
  decisions.py index
  decisions.py check
"""

from __future__ import annotations

import argparse
import datetime as _dt
import pathlib
import re
import sys
import unicodedata

ROOT = pathlib.Path(__file__).resolve().parents[2]
DECISIONS = ROOT / "docs" / "decisions"
ADR = ROOT / "docs" / "adr"
INDEX = DECISIONS / "README.md"

STATUSES = ("proposed", "accepted", "superseded", "rejected")
_STATUS_ALIASES = {
    "accepted": "accepted",
    "proposed": "proposed",
    "superseded": "superseded",
    "rejected": "rejected",
    "đã chấp nhận": "accepted",
    "đề xuất": "proposed",
}


def _fold(text: str) -> str:
    """Lowercase and strip Vietnamese diacritics for search."""
    text = text.replace("đ", "d").replace("Đ", "D")
    normalized = unicodedata.normalize("NFD", text)
    return "".join(c for c in normalized if unicodedata.category(c) != "Mn").lower()


def _slug(title: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", _fold(title)).strip("-")[:60] or "decision"


class Decision:
    def __init__(self, path: pathlib.Path):
        self.path = path
        self.text = path.read_text(encoding="utf-8")
        self.kind = "ADR" if path.parent == ADR else "D"
        number = re.match(r"(?:D-)?(\d{4})", path.name)
        self.number = number.group(1) if number else "????"
        self.id = f"{self.kind}-{self.number}"
        heading = re.search(r"^#\s+(.+)$", self.text, re.M)
        title = heading.group(1).strip() if heading else path.stem
        self.title = re.sub(r"^(ADR\s+\d+|D-\d+)\s*[:—-]\s*", "", title)
        self.status = self._field(("Status", "Trạng thái"), "proposed").lower()
        self.status = _STATUS_ALIASES.get(self.status, self.status)
        self.date = self._field(("Date", "Ngày"), "")
        self.scope = self._field(("Scope", "Phạm vi"), "project" if self.kind == "ADR" else "feature")
        tags = self._field(("Tags",), "")
        self.tags = [t.strip() for t in tags.split(",") if t.strip()]
        self.supersedes = self._field(("Supersedes", "Thay thế"), "")
        self.superseded_by = self._field(("Superseded by", "Bị thay bởi"), "")
        decision = re.search(r"^##\s+(Quyết định|Decision)\s*\n(.+?)(?=^##\s|\Z)", self.text, re.M | re.S)
        body = decision.group(2) if decision else ""
        first = next((l.strip(" -*") for l in body.splitlines() if l.strip()), "")
        self.summary = first[:160]

    def _field(self, names, default):
        for name in names:
            m = re.search(rf"^-?[ \t]*\*?\*?{re.escape(name)}\*?\*?[ \t]*:[ \t]*([^\n]*)$", self.text, re.M | re.I)
            if m:
                return m.group(1).strip() or default
        return default

    @property
    def rel(self) -> str:
        return self.path.relative_to(ROOT).as_posix()


def load() -> list[Decision]:
    files = sorted(DECISIONS.glob("D-[0-9][0-9][0-9][0-9]-*.md"))
    files += sorted(p for p in ADR.glob("[0-9][0-9][0-9][0-9]-*.md"))
    return [Decision(p) for p in files]


def _next_number(paths, pattern) -> int:
    numbers = [int(m.group(1)) for p in paths if (m := re.match(pattern, p.name))]
    return max(numbers, default=0) + 1


def cmd_new(args) -> int:
    today = _dt.date.today().isoformat()
    if args.scope == "project":
        number = _next_number(ADR.glob("*.md"), r"(\d{4})-")
        path = ADR / f"{number:04d}-{_slug(args.title)}.md"
        heading = f"# ADR {number:04d}: {args.title}"
    else:
        DECISIONS.mkdir(parents=True, exist_ok=True)
        number = _next_number(DECISIONS.glob("D-*.md"), r"D-(\d{4})-")
        path = DECISIONS / f"D-{number:04d}-{_slug(args.title)}.md"
        heading = f"# D-{number:04d}: {args.title}"
    template = (DECISIONS / "TEMPLATE.md").read_text(encoding="utf-8")
    body = template.split("\n", 1)[1]
    body = body.replace("<YYYY-MM-DD>", today)
    body = body.replace("<feature|project>", args.scope)
    body = body.replace("<tags>", args.tags or "")
    body = body.replace("<feature-or-none>", args.feature or "")
    path.write_text(f"{heading}\n{body}", encoding="utf-8")
    print(path.relative_to(ROOT).as_posix())
    return 0


def _score(d: Decision, terms) -> int:
    hay_title = _fold(d.title + " " + " ".join(d.tags))
    hay_body = _fold(d.text)
    score = 0
    for t in terms:
        if t in hay_title:
            score += 3
        if t in hay_body:
            score += 1
    return score


def cmd_search(args) -> int:
    terms = [t for t in _fold(args.query).split() if t]
    found = []
    for d in load():
        if not args.all and d.status not in ("accepted", "proposed"):
            continue
        s = _score(d, terms)
        if s:
            found.append((s, d))
    if not found:
        print("Không có quyết định nào khớp. Nếu đây là lựa chọn mới, tạo bằng: "
              f"decisions.py new \"<tiêu đề>\" --tags {'-'.join(terms)}")
        return 0
    for s, d in sorted(found, key=lambda x: (-x[0], x[1].id)):
        print(f"{d.id} [{d.status}] {d.title}")
        if d.summary:
            print(f"    {d.summary}")
        print(f"    {d.rel}")
    return 0


def _row(d: Decision) -> str:
    link = pathlib.Path(d.rel).relative_to("docs/decisions").as_posix() if d.kind == "D" else f"../adr/{d.path.name}"
    tags = ", ".join(d.tags)
    return f"| [{d.id}]({link}) | {d.title} | {d.status} | {d.scope} | {tags} | {d.date} |"


def build_index(decisions) -> str:
    lines = [
        "# Sổ quyết định kỹ thuật",
        "",
        "Trang này được sinh bởi `python3 tool/decisions/decisions.py index`. Không sửa",
        "tay phần bảng; sửa file quyết định rồi chạy lại lệnh.",
        "",
        "Trước khi chọn một cách làm, tìm quyết định cũ:",
        "",
        "```bash",
        "python3 tool/decisions/decisions.py search \"phân trang\"",
        "```",
        "",
        "Quyết định cấp tính năng nằm trong thư mục này (`D-NNNN`). Quyết định ảnh",
        "hưởng toàn dự án là ADR trong `docs/adr/`. Cách viết và vòng đời ở",
        "[HOW-TO.md](HOW-TO.md).",
        "",
    ]
    groups = [("Đang áp dụng", ("accepted",)), ("Đang chờ duyệt", ("proposed",)),
              ("Đã thay thế hoặc bị từ chối", ("superseded", "rejected"))]
    for title, statuses in groups:
        rows = [d for d in decisions if d.status in statuses]
        lines += [f"## {title}", ""]
        if not rows:
            lines += ["Chưa có.", ""]
            continue
        lines += ["| Mã | Quyết định | Trạng thái | Phạm vi | Tags | Ngày |", "|---|---|---|---|---|---|"]
        lines += [_row(d) for d in rows]
        lines.append("")
    tags = sorted({t for d in decisions for t in d.tags if d.status == "accepted"})
    if tags:
        lines += ["## Theo chủ đề", ""]
        for t in tags:
            ids = ", ".join(d.id for d in decisions if t in d.tags and d.status == "accepted")
            lines.append(f"- **{t}**: {ids}")
        lines.append("")
    glossary = DECISIONS / "glossary.md"
    if glossary.exists():
        lines += ["## Thuật ngữ", "", "Tên dùng thống nhất trong code nằm ở [glossary.md](glossary.md).", ""]
    return "\n".join(lines)


def cmd_index(args) -> int:
    INDEX.write_text(build_index(load()), encoding="utf-8")
    print(INDEX.relative_to(ROOT).as_posix())
    return 0


def problems(decisions) -> list[str]:
    out = []
    ids = {d.id for d in decisions}
    for d in decisions:
        if d.status not in STATUSES:
            out.append(f"{d.rel}: trạng thái '{d.status}' không hợp lệ ({', '.join(STATUSES)})")
        if d.kind == "D":
            for section in ("## Bối cảnh", "## Quyết định", "## Hệ quả"):
                if section not in d.text:
                    out.append(f"{d.rel}: thiếu mục '{section}'")
        if d.status == "superseded" and not d.superseded_by:
            out.append(f"{d.rel}: đã superseded nhưng thiếu 'Bị thay bởi:'")
        for ref in re.findall(r"\b(D-\d{4}|ADR-\d{4})\b", d.supersedes + " " + d.superseded_by):
            if ref not in ids:
                out.append(f"{d.rel}: tham chiếu {ref} không tồn tại")
    if INDEX.exists() and INDEX.read_text(encoding="utf-8") != build_index(decisions):
        out.append("docs/decisions/README.md đã cũ; chạy: python3 tool/decisions/decisions.py index")
    return out


def cmd_check(args) -> int:
    found = problems(load())
    for p in found:
        print(p)
    if not found:
        print("Sổ quyết định hợp lệ.")
    return 1 if found else 0


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)
    p_new = sub.add_parser("new", help="tạo quyết định mới ở trạng thái proposed")
    p_new.add_argument("title")
    p_new.add_argument("--scope", choices=("feature", "project"), default="feature")
    p_new.add_argument("--tags", default="")
    p_new.add_argument("--feature", default="")
    p_new.set_defaults(func=cmd_new)
    p_search = sub.add_parser("search", help="tìm quyết định theo từ khoá, có dấu hoặc không dấu")
    p_search.add_argument("query")
    p_search.add_argument("--all", action="store_true", help="gồm cả superseded và rejected")
    p_search.set_defaults(func=cmd_search)
    sub.add_parser("index", help="sinh lại docs/decisions/README.md").set_defaults(func=cmd_index)
    sub.add_parser("check", help="kiểm tra định dạng và chỉ mục").set_defaults(func=cmd_check)
    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
