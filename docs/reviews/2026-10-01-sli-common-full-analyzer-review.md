# Review Analyzer Toàn Bộ `sli_common` — 2026-10-01

## Kết luận

Analyzer của **toàn package** đã sạch: 241 finding lịch sử xuống 0. Gate local
`derry quality`, lệnh riêng `derry toolkit quality` và CI đều chạy full-package
analyze thay vì chỉ kiểm tra stable surface.

## Revision và phạm vi

| Repository | Revision | Nội dung |
|---|---|---|
| `sli_common` | `f7c9e88` (`dev`, đã push) | 182 Dart fix được rà lại, sửa API Flutter cũ, bỏ dead code, sửa calendar export, thêm smoke tests |
| `bloc_cubit_base` | Pin `f7c9e88` | Bổ sung local/CI gate và cập nhật tài liệu trong commit cùng review này |

Các sửa có ảnh hưởng hành vi được kiểm tra riêng: `PermissionUtil` kiểm tra
`context.mounted` sau khi xin quyền; calendar giữ public `DateTimeRange` và
export `CalendarDateRangePicker` từ đúng library; text scaling chuyển sang
`TextScaler`; `TextDirection` của calendar Cupertino được phân biệt rõ với type
trong `intl`.

## Gate thực tế

| Lệnh | Kết quả |
|---|---|
| `fvm flutter analyze --no-pub` trong `sli_common` | 0 finding toàn package |
| `fvm flutter test --no-pub` trong `sli_common` | 18/18 pass, gồm 2 calendar smoke tests mới |
| `derry quality` từ base | 194 file app đúng format, app analyzer 0, architecture gate pass, 64/64 app tests; toolkit format/analyzer 0 và 18/18 toolkit tests |
| `git diff --check` | Pass |

## Ngoại lệ tương thích đã ghi tại source

- Ba public enum legacy `BorderType`, `PanelState`, `TrimMode` giữ spelling cũ
  vì đổi tên value sẽ làm gãy caller. Lint `constant_identifier_names` chỉ được
  miễn đúng dòng khai báo.
- `MiniplayerWillPopScope` giữ async veto callback và API route cũ. Chuyển sang
  `PopScope` đòi hỏi parity test riêng cho nested back behavior; chỉ những dòng
  dùng API deprecated này được miễn lint.
- Những ngoại lệ này không áp dụng cho component `Sli*` mới.

## Giới hạn review

Analyzer sạch và smoke tests không chứng minh mọi widget legacy đã ổn định về
UX hay responsive behavior. Migration 10 family còn lại vẫn theo behavior matrix
và parity test; trạng thái maturity trong catalog không tự nâng thành Stable.
