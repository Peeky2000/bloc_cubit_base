# 5. Agent, skill và luật

## Ba lớp

| Lớp | Là gì | Ở đâu |
|---|---|---|
| Luật | Điều code phải theo: kiến trúc, ADR, quyết định, convention | `AGENTS.md`, `docs/architecture/`, `docs/adr/`, `docs/decisions/`, `.agents/skills/project-convention/` |
| Skill | Cách làm một loại việc cụ thể (viết Cubit, repository, phân trang…) | `.agents/skills/<tên>/SKILL.md` |
| Agent | Vai trò dùng skill để làm việc (dev, tester, reviewer…) | `.agents/agents/<tên>.md` |

Agent luôn đọc `AGENTS.md` trước. Đổi luật làm thay đổi cách viết code thì tăng
`rulesVersion` trong `forge-base.json`.

## Agent

| Agent | Việc |
|---|---|
| `pm` | Đọc tài liệu nghiệp vụ, chia việc |
| `flutter-dev` | Viết tính năng và sửa lỗi theo luật |
| `flutter-tester` | Kiểm tra độc lập code của dev |
| `reviewer` | Review thay đổi |
| `perf-tester`, `perf-engineer` | Đo và sửa hiệu năng |

## Lệnh `/` trong Claude Code

| Lệnh | Việc |
|---|---|
| `/tech-design <tài liệu>` | Viết thiết kế kỹ thuật, dừng chờ duyệt |
| `/build-feature <tech.md>` | Làm trọn tính năng: code, test, kiểm tra |
| `/decision <câu hỏi>` | Tra hoặc ghi quyết định kỹ thuật |
| `/perf-check [màn]` | Đo, tìm nguyên nhân, sửa, đo lại hiệu năng |
| `/perf-scenario <AC>` | Viết kịch bản đo hiệu năng từ AC |
| `/security-audit [phạm vi]` | Audit bảo mật mobile |

Không dùng Claude Code: gọi `@.agents/agents/flutter-dev.md <việc>` trong AI
agent khác.

## Skill chính theo tầng

`flutter-model-entity`, `flutter-datasource`, `flutter-repository`,
`flutter-bloc-cubit`, `flutter-router`, `flutter-translations`, `flutter-di`,
`flutter-error-handling`, `flutter-atomic-design` (widget), `flutter-testing`,
`flutter-patterns` (8 mẫu kỹ thuật), `project-convention` (luật xuyên tầng).

## Đọc thêm

Danh sách đầy đủ kèm câu gọi mẫu: [bộ công cụ AI](../guides/ai-toolbox.md) ·
[AGENTS.md](../../AGENTS.md) · [The Forge](../guides/forge-design.md).

Tiếp: [Lệnh và công cụ](06-lenh-va-cong-cu.md).
