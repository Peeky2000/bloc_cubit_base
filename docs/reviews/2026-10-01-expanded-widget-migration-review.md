# Review — ExpandedWidget migration (2026-10-01)

## Quyết định

`ExpandedWidget` là widget trùng nhỏ nhất có caller nội bộ thật. App và
`sli_common` cùng constructor/defaults, nhưng shared căn đáy cả hai trục còn
app căn phải khi `Axis.horizontal`. Chỉnh shared về behavior app, giữ class
app làm adapter deprecated và đổi `CommonTextField` sang public package export.
Không đánh dấu shared widget là stable `Sli*`: API legacy này chưa có gallery,
semantics contract hoặc golden riêng.

## Evidence

- Test toolkit chạy mở/đóng ở cả trục dọc/ngang và kiểm tra alignment; focused
  command `fvm flutter test --no-pub test/legacy/expanded_widget_test.dart`
  pass **2/2**.
- Test app kiểm tra adapter truyền `expand`, `axis`, `duration`, alignment và
  kích thước; focused command
  `fvm flutter test --no-pub test/core/widget/expanded_widget_test.dart`
  pass **1/1**.
- `CommonTextField` app không còn import bản `ExpandedWidget` cục bộ.
- Public catalog có [cách dùng và giới hạn](../../lib/modules/sli_common/docs/catalog/expanded-widget.md);
  [family matrix](../plan/2026-10-01-widget-family-migration-matrix.md) ghi
  chín file khác chưa thể swap theo tên.

## Gate cuối

- `sli_common` revision `d4da18d` trên `dev` đã push; base pin đúng revision
  này trong commit chứa review.
- `derry quality` pass: app format 195 file, analyzer 0, 65 tests; toolkit
  analyzer 0, 20 tests. `git diff --check` pass.
- App-memory đã index shared `ExpandedWidget`, tránh tạo thêm bản trùng.
