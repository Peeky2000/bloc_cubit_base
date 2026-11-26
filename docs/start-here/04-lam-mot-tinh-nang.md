# 4. Làm một tính năng

## Với AI (cách chính)

```text
Spec/PRD ─▶ /tech-design ─▶ tech.md ─▶ bạn duyệt ─▶ /build-feature ─▶ code + test
```

1. Trong Claude Code: `/tech-design docs/prd/<tính năng>.md` (hoặc dán AC).
   Agent tra sổ quyết định, viết `docs/specs/<id>-<tính năng>/tech.md` cùng
   các quyết định mới ở trạng thái đề xuất, rồi **dừng lại**.
2. Bạn đọc `tech.md`, trả lời mục câu hỏi nghiệp vụ, đổi
   `Trạng thái: Draft` thành `Trạng thái: Approved`.
3. `/build-feature docs/specs/<id>-<tính năng>/tech.md`. Agent dev sinh khung,
   viết code theo thứ tự tầng và test; agent test kiểm tra độc lập; lỗi quay
   về dev tới khi qua. Kết quả là một nhánh mới và báo cáo tiếng Việt.

Bạn chỉ duyệt `tech.md` và đọc báo cáo. Code sinh ra theo đúng luật ở trang 3,
nên đọc và sửa tay được như code người viết.

## Bằng tay

```bash
derry scaffold -- payment --data --apply   # Cubit, kèm tầng data
derry scaffold -- chat --bloc --apply      # BLoC
```

Khung sinh ra đã qua test convention. Viết tiếp theo thứ tự tầng rồi
`derry gen` và `derry quality`.

## Tính năng có mẫu sẵn

Phân trang, form và validate, cache offline, upload ảnh, realtime, deep link,
push, xin quyền: agent đọc luật trong skill `flutter-patterns` và sinh code;
`test/patterns/<mẫu>_pattern_test.dart` là chuẩn để so. Quyết định gốc:
D-0001 tới D-0009 trong [sổ quyết định](../decisions/README.md).

## Đọc thêm

[Thêm feature](../guides/add-feature.md) ·
[vòng dev–tester](../agents/delivery-loop.md) ·
[quy trình AI](../../ai-process.md).

Tiếp: [Agent, skill và luật](05-agent-skill-luat.md).
