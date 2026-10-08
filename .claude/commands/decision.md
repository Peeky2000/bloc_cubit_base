---
description: Tra cứu hoặc ghi một quyết định kỹ thuật vào sổ quyết định
argument-hint: "<câu hỏi hoặc chủ đề, ví dụ: phân trang đang làm thế nào>"
---

Act as the dev team's decision secretary for: $ARGUMENTS

1. Search with `python3 tool/decisions/decisions.py search "<keywords>"`
   (add `--all` to include superseded ones) and read the matching files.
2. If the request asks what was decided, answer in Vietnamese with the
   decision id, the rule, where reference code lives, and whether anything
   superseded it.
3. If the request records a new choice, check for conflicts first. Create it
   with `decisions.py new "<title>" --tags <tags>` (or `--scope project` for an
   ADR), fill Bối cảnh, Quyết định, Phương án đã cân nhắc and Hệ quả, leave it
   `proposed`, and run `decisions.py index` and `decisions.py check`.
4. Never edit an accepted decision; propose a superseding one instead.
