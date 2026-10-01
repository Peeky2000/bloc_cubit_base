# Review — Flutter/mobile engineering skills (2026-10-01)

## Scope và quyết định

Thêm sáu skill quality cho những việc không thuộc riêng một Clean Architecture
layer: code review, performance, testing, security/privacy, platform lifecycle,
release readiness. `project-convention` tiếp tục là nguồn quy tắc base; skill
layer hiện có vẫn hướng dẫn implementation. Không đưa VIPER vào quy trình này.

## Evidence

- Sáu `SKILL.md` có tên thư mục/frontmatter khớp nhau, description nêu rõ
  trigger, workflow yêu cầu bằng chứng và output/giới hạn thẩm quyền.
- YAML frontmatter của cả sáu được parser Ruby/Psych (`YAML.safe_load`) kiểm
  tra tên, description không rỗng và độ dài hợp lệ: **6/6 pass**.
- `reviewer` mặc định dùng `flutter-code-review`; `coder` và quick-fix agent
  chỉ thêm skill chuyên biệt khi đúng task. Guide
  [`mobile-engineering-skills.md`](../guides/mobile-engineering-skills.md)
  có ma trận chọn skill và ví dụ yêu cầu cho người mới.
- Review thủ công năm tình huống trong guide: refresh-token PR cần review +
  security + test; jank cần profile performance; BottomSheet regression cần
  testing + atomic design; connectivity leak cần lifecycle; release audit cần
  readiness. Không tình huống nào yêu cầu bật tất cả skill hoặc cho phép upload
  hay sửa code khi chỉ được nhờ audit.
- `derry quality` pass: app format sạch, analyzer 0, 64 tests; `sli_common`
  format sạch, analyzer 0, 18 tests. `git diff --check` pass. Đây là regression
  gate của repository, không phải phép đo chất lượng skill.

Validator `quick_validate.py` trong skill-creator không chạy được vì Python
hiện tại thiếu `PyYAML` (`ModuleNotFoundError: yaml`); kiểm tra cấu trúc bằng
Ruby/Psych là fallback, **không** phải benchmark hành vi agent. Chưa chạy eval
độc lập có baseline để đo tỉ lệ trigger/false positive hoặc chất lượng output
trên PR thật. Follow-up này còn mở trong roadmap.

## Review verdict

**PASS cho việc tạo và tích hợp skill; CONDITIONAL cho hiệu quả trigger.** Skill
có thể dùng ngay, nhưng chưa có bằng chứng định lượng rằng auto-trigger luôn
đúng. Không tuyên bố phần eval đã hoàn tất.
