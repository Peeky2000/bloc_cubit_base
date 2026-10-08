# Chọn skill Flutter/mobile cho đúng việc

Skill là hướng dẫn làm việc cho AI agent, không thay thế kiến trúc, test hay
review của con người. Bắt đầu từ `project-convention` khi tạo/sửa/review code
trong base này, sau đó chỉ đọc skill khớp với phần việc đang làm.

## Bản đồ nhanh

| Nhu cầu | Skill chính | Kết quả cần nhận |
|---|---|---|
| Review PR hoặc source Flutter (bắt đầu bằng `derry review plan`) | [`flutter-code-review`](../../.agents/skills/flutter-code-review/SKILL.md) | Finding theo mức độ, đường dẫn/dòng, điều kiện gây lỗi, bằng chứng và test gap |
| Chẩn đoán jank, startup chậm, memory tăng ([cách đo](measure-performance.md)) | [`flutter-performance`](../../.agents/skills/flutter-performance/SKILL.md) | Scenario profile, số đo trước/sau, nguyên nhân được kiểm chứng hoặc giả thuyết có giới hạn |
| Chọn cấp test, viết regression test | [`flutter-testing`](../../.agents/skills/flutter-testing/SKILL.md) | Test nhỏ nhất chứng minh hành vi, gồm failure/concurrency path liên quan |
| Token, PII, permission, log, Firebase data | [`mobile-security-privacy`](../../.agents/skills/mobile-security-privacy/SKILL.md) | Data-flow/threat finding, tác động và cách xác minh, không lộ secret |
| Resume/background, dispose, platform channel | [`mobile-platform-lifecycle`](../../.agents/skills/mobile-platform-lifecycle/SKILL.md) | Ownership/transition audit, test đúng cấp và khoảng trống device verification |
| Chuẩn bị bản build/phân phối/release | [`mobile-release-readiness`](../../.agents/skills/mobile-release-readiness/SKILL.md) | GO/CONDITIONAL/NO-GO kèm artifact, blocker, owner và rollback path |

Các skill layer hiện có (`flutter-model-entity`, `flutter-datasource`,
`flutter-repository`, `flutter-di`, `flutter-bloc-cubit`, `flutter-router`,
`flutter-atomic-design`, `flutter-translations`, `flutter-error-handling`)
sở hữu **cách triển khai** từng layer. Sáu skill trên sở hữu **workflow đánh
giá chất lượng**. Có thể kết hợp khi task thật sự chạm cả hai; không cần tải
tất cả cho mọi yêu cầu.

## Ví dụ yêu cầu nên đưa cho agent

- “Review diff refresh token này; kiểm tra concurrent 401, account switch,
  replay và test. Chỉ báo finding, chưa sửa code.” → `flutter-code-review` +
  `mobile-security-privacy` + `flutter-testing`.
- “Màn danh sách bị giật trên thiết bị Android tầm trung. Đây là timeline
  profile; tìm nguyên nhân và so sánh trước/sau.” → `flutter-performance`.
- “Thêm test cho BottomSheet khi keyboard mở và khi route bị pop; chọn cấp test
  tối thiểu.” → `flutter-testing` + `flutter-atomic-design`.
- “Kiểm tra stream connectivity có bị leak khi app resume/logout và màn hình
  dispose không.” → `mobile-platform-lifecycle`.
- “Audit bản `prod` Android/iOS để phát hành, nhưng chưa upload.” →
  `mobile-release-readiness` + `mobile-security-privacy` nếu có data/secret.

Nếu chỉ hỏi cách đặt tên một widget, không tự động chạy audit release/performance.
Nếu chỉ nhờ review, không tự ý sửa code, upload Store, xoay credential hay bật
Firebase production. Một kết luận performance thiếu profile data phải được ghi
là giả thuyết, không phải cải thiện đã đo.

## Kiểm chứng skill

Frontmatter được kiểm tra bằng YAML parser cho tên, mô tả và cấu trúc. Các ví
dụ trên dùng để review thủ công ranh giới trigger/output; chưa phải benchmark
độc lập về tỉ lệ trigger. Khi có tập task thật, bổ sung eval có baseline và
chấm false positive/false negative trước khi tối ưu mô tả skill.

Nguồn quyết định: [ADR-0008](../adr/0008-mobile-engineering-skills-no-viper.md),
[brainstorm Flutter/mobile skills](../brainstorm/2026-09-28-flutter-mobile-engineering-skills.md).
