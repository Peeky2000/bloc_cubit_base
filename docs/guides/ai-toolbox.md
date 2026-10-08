# Bộ công cụ AI trong repo

Trang này tổng hợp mọi lệnh, agent và skill dành cho AI có trong repo, kèm
cách gọi. Khi thêm hoặc đổi một công cụ, cập nhật trang này trong cùng thay
đổi.

## Cách gọi nhanh

Có ba cách gọi công cụ AI. Không cần nhớ hết; chọn một cách là đủ.

| Cách | Gõ ở đâu | Ví dụ | Dùng khi |
|---|---|---|---|
| Gõ lệnh có dấu `/` | Khung chat Claude Code | `/perf-check` | Việc có quy trình cố định: đo hiệu năng, audit bảo mật |
| Nhắc tên agent | Khung chat của bất kỳ AI agent nào | `@.agents/agents/reviewer.md review nhánh này` | Muốn chọn đúng vai trò |
| Nói bằng lời | Khung chat | `review code nhánh feature/login so với main` | Agent tự chọn skill phù hợp |
| Chạy derry | Terminal | `derry quality` | Lệnh cho người chạy trực tiếp, không cần AI |

### Các câu gọi mẫu

Chép nguyên câu và thay phần trong ngoặc nhọn.

| Muốn làm | Gõ |
|---|---|
| Đo hiệu năng cả app | `/perf-check` |
| Đo một màn | `/perf-check màn danh sách đơn` |
| Viết kịch bản đo từ AC | `/perf-scenario docs/specs/<mã spec>/fe.md AC3` |
| Viết kịch bản đo từ mô tả | `/perf-scenario mở danh sách đơn, cuộn tới cuối, mở đơn cuối` |
| Audit bảo mật cả app | `/security-audit` |
| Audit bảo mật một phần | `/security-audit đăng nhập và token` |
| Audit bảo mật thay đổi trên một nhánh | `/security-audit nhánh <tên nhánh>` |
| Review code thay đổi | `@.agents/agents/reviewer.md review nhánh <tên nhánh> so với main` |
| Review chuẩn code và đúng yêu cầu (skill của Matt Pocock) | `dùng skill code-review của Matt review từ <commit hoặc nhánh> tới HEAD, spec ở <đường dẫn>` |
| Tìm điểm cải thiện kiến trúc (skill của Matt Pocock) | `dùng skill improve-codebase-architecture của Matt cho repo này` |
| Viết spec từ thiết kế | `viết spec cho màn <tên màn> từ <link Figma hoặc ảnh>` |
| Lên plan | `viết plan cho spec docs/specs/<mã spec>/fe.md` |
| Code theo spec | `implement spec docs/specs/<mã spec>` |
| Phân tích trước khi làm | `brainstorm <vấn đề>` |
| Viết test | `viết test cho <file hoặc tính năng>` |
| Chuẩn bị phát hành | `kiểm tra release readiness cho bản prod Android và iOS` |

## Lệnh gõ trong Claude Code

Gõ lệnh trong khung chat của Claude Code. Các lệnh này nằm ở
[.claude/commands/](../../.claude/commands/).

| Lệnh | Dùng khi | Cần chuẩn bị | Kết quả |
|---|---|---|---|
| `/perf-check` | Muốn đo và tối ưu hiệu năng cả app | Máy thật, tài khoản test, địa chỉ server, 10 GB ổ đĩa | Báo cáo tiếng Việt trong `docs/performance/` |
| `/perf-check <màn hoặc luồng>` | Chỉ đo một màn hoặc một luồng | Như trên | Như trên, tự viết kịch bản nếu chưa có |
| `/perf-scenario <AC, spec hoặc mô tả>` | Có AC hoặc mô tả luồng, cần kịch bản đo | Máy thật để chạy thử, không bắt buộc | Kịch bản và ngưỡng đề xuất chờ duyệt |
| `/security-audit` | Kiểm tra bảo mật cả app | Không cần gì | Báo cáo tiếng Việt trong `docs/reviews/` |
| `/security-audit <phạm vi>` | Kiểm tra một phần, ví dụ "đăng nhập và token" hoặc "nhánh feature/login" | Không cần gì | Như trên, chỉ cho phạm vi đó |

Claude Code còn có sẵn các lệnh chung như `/code-review` và `/security-review`.
Hai lệnh đó không biết quy ước riêng của repo. Ưu tiên dùng các lệnh ở bảng
trên, hoặc nhờ bằng lời để agent dùng skill của repo.

## Lệnh derry

Chạy trong terminal. Danh sách đầy đủ: `derry ls -d`.

| Lệnh | Việc |
|---|---|
| `derry quality` | Format, analyzer, kiểm tra kiến trúc và test, cho cả app lẫn `sli_common` |
| `derry gen` | Sinh code: DI, model, asset |
| `derry review plan` | Liệt kê file đã thay đổi cần review và luật áp cho từng file |
| `derry perf run` | Đo hiệu năng trên máy thật |
| `derry perf diagnose` | Đo kèm chẩn đoán widget chậm nhất |
| `derry perf approve` | Đo lại và lưu kết quả làm mốc |

## Agent

Gọi bằng cách nhắc tên file trong câu yêu cầu, ví dụ
`@.agents/agents/reviewer.md review nhánh này`. Danh sách cũng có trong
[AGENTS.md](../../AGENTS.md).

| Agent | Vai trò |
|---|---|
| [pm](../../.agents/agents/pm.md) | Phân tích yêu cầu, viết plan, điều phối coder và reviewer |
| [coder](../../.agents/agents/coder.md) | Code tính năng theo đúng kiến trúc |
| [flutter-engineer](../../.agents/agents/flutter-engineer.md) | Sửa nhanh một việc nhỏ |
| [reviewer](../../.agents/agents/reviewer.md) | Review code, ghi báo cáo vào `docs/reviews/` |
| [perf-tester](../../.agents/agents/perf-tester.md) | Đo hiệu năng, tìm nguyên nhân, kiểm tra lại sau khi sửa |
| [perf-engineer](../../.agents/agents/perf-engineer.md) | Sửa lỗi hiệu năng theo phiếu bàn giao |

Theo [plan agent dev và agent test](../plan/2026-10-07-flutter-dev-and-test-agents.md),
`coder` và `flutter-engineer` sẽ được gộp thành `flutter-dev`, còn
`perf-tester` sẽ mở rộng thành `flutter-tester`.

## Skill

Skill là hướng dẫn làm việc mà agent tự nạp khi gặp việc phù hợp. Bạn không
cần gọi trực tiếp; chỉ cần mô tả việc cần làm. Các skill nằm ở
[.agents/skills/](../../.agents/skills/).

### Quy trình

| Skill | Agent nạp khi bạn nói |
|---|---|
| `brainstorm` | "phân tích", "suy nghĩ kỹ", "brainstorm" trước khi làm |
| `spec-analyze` | Đưa ảnh thiết kế, Figma hoặc mô tả yêu cầu để viết spec |
| `spec-checklists` | Tách spec thành checklist kỹ thuật |
| `spec-implement` | Code theo checklist của spec |
| `plan-writer` | "viết plan", "lên kế hoạch" |
| `app-memory` | Tự dùng để tìm widget, model, route đã có trước khi tạo mới |
| `skill-creator` | Tạo hoặc sửa skill |

### Kiến trúc và từng tầng

| Skill | Phụ trách |
|---|---|
| `project-convention` | Quy ước chung của repo, luôn được nạp khi code hoặc review |
| `flutter-model-entity` | Entity và model |
| `flutter-datasource` | Gọi API, lưu trữ local |
| `flutter-repository` | Repository |
| `flutter-di` | Dependency injection |
| `flutter-bloc-cubit` | Cubit, BLoC và state |
| `flutter-router` | Điều hướng |
| `flutter-atomic-design` | Widget và `sli_common` |
| `flutter-translations` | Đa ngôn ngữ |
| `flutter-error-handling` | Xử lý lỗi |

### Chất lượng

| Skill | Agent nạp khi bạn nói | Lệnh liên quan |
|---|---|---|
| `flutter-code-review` | "review code", "review nhánh" | `derry review plan` |
| `flutter-testing` | "viết test" | |
| `flutter-performance` | "app giật", "đo hiệu năng" | `/perf-check`, `/perf-scenario` |
| `mobile-security-privacy` | "kiểm tra bảo mật", "audit bảo mật" | `/security-audit` |
| `mobile-platform-lifecycle` | Background, foreground, platform channel | |
| `mobile-release-readiness` | "chuẩn bị phát hành" | |

Chi tiết nên chọn skill nào cho việc gì nằm ở
[chọn skill Flutter/mobile](mobile-engineering-skills.md).

## Skill bên ngoài repo

Bộ skill của Matt Pocock nằm ở `~/Documents/Personal/skills` (clone từ
`github.com/mattpocock/skills`), chưa được cài vào Claude Code. Agent đọc trực
tiếp file `SKILL.md` khi được nhắc tên.

| Skill | Làm gì | Ghi chú khi dùng với repo này |
|---|---|---|
| `code-review` | Review thay đổi theo hai trục độc lập: chuẩn code của repo, và đúng yêu cầu | Chuẩn code lấy từ `project-convention` và `AGENTS.md`. Cần chỉ rõ spec hoặc PR làm yêu cầu |
| `improve-codebase-architecture` | Tìm module nông, đề xuất gộp cho sâu, xuất báo cáo HTML | Repo chưa có `CONTEXT.md`; đọc ADR trong `docs/adr/` để không đề xuất trái quyết định cũ |
| `codebase-design` | Bộ từ vựng thiết kế module dùng chung cho hai skill trên | |

Báo cáo lần chạy đầu: [review ngày 2026-10-08](../reviews/2026-10-08-09-00-00-matt-code-review-and-architecture.md).

## Tài liệu theo chủ đề

| Chủ đề | Bắt đầu tại |
|---|---|
| Đo hiệu năng | [Đo hiệu năng app](measure-performance.md) |
| Chuẩn và ngưỡng hiệu năng | [Chuẩn và ngưỡng](../performance/standards.md) |
| Từ AC tới kịch bản đo | [Từ AC tới kịch bản](../performance/ac-to-scenario.md) |
| Vòng agent hiệu năng | [Agent loop](../performance/agent-loop.md) |
| Quy trình làm việc với AI | [ai-process.md](../../ai-process.md) |
