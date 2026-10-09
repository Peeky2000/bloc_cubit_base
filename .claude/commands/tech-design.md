---
description: Đọc tài liệu và viết thiết kế kỹ thuật tech.md cho PM duyệt, không code
argument-hint: "<đường dẫn tài liệu, link hoặc nội dung AC>"
---

Write the technical design for this document, without writing feature code:
$ARGUMENTS

Use the `tech-design` skill (`.agents/skills/tech-design/SKILL.md`).

1. Give every requirement an id and keep its wording. Do not change business
   behavior; list ambiguities as business questions.
2. Search past decisions with `python3 tool/decisions/decisions.py search` for
   each technical topic, and reuse code found through app-memory,
   `sli_common`, `lib/widget/` and sibling features. Mark a widget as new
   when nothing fits.
3. Write `docs/specs/<id>-<feature>/tech.md` from the template, filling every
   section with exact paths, class and field names, state, effects, API,
   storage, UI components, l10n keys, tests and performance targets.
4. Create new decisions with `python3 tool/decisions/decisions.py new` as
   `proposed`, link them in `tech.md`, and run `decisions.py index`.
5. Run `python3 tool/decisions/decisions.py check`.
6. Reply in Vietnamese with: requirement count, files to create or change,
   decisions reused, decisions proposed, business questions, and the path to
   review. Stop there.
