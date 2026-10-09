# Thiết kế kỹ thuật: <Tên tính năng>

- Mã: <id>
- Trạng thái: Draft | Approved | Implemented | Superseded
- Tài liệu nguồn: <đường dẫn hoặc link, phiên bản>
- Người duyệt: <PM>, ngày <YYYY-MM-DD>
- Quyết định liên quan: D-0001, ADR-0009, ...

## 1. Yêu cầu nhận vào

Giữ nguyên ý của tài liệu nguồn; không thêm nghiệp vụ.

| Mã | Yêu cầu (trích tài liệu) | Ghi chú kỹ thuật |
|---|---|---|
| R1 | | |

## 2. Quyết định áp dụng

| Chủ đề | Quyết định | Nguồn |
|---|---|---|
| Phân trang | | D-xxxx (accepted) |
| State owner | Cubit | ADR-0002 |

Quyết định mới đề xuất (trạng thái `proposed`, cần duyệt cùng tài liệu này):

| Mã | Tiêu đề | Lý do |
|---|---|---|

## 3. Tái sử dụng

| Thứ dùng lại | Vị trí |
|---|---|
| | |

## 4. Lệnh sinh khung

```bash
derry scaffold -- <feature> [--bloc] [--data=<domain>] --apply
```

## 5. Danh sách file

| Tầng | Đường dẫn | Mới / Sửa | Vai trò |
|---|---|---|---|
| Entity | `lib/domain/entities/<domain>/<name>.dart` | Mới | |
| Model | `lib/data/model/response/<domain>/<name>_response_model.dart` | Mới | |
| Data source | `lib/data/datasource/remote/<domain>_remote_data_source.dart` | Mới | |
| Repository | `lib/domain/repositories/<domain>_repo.dart`, `lib/data/repositories/<domain>_repo_impl.dart` | Mới | |
| Use case | `lib/domain/use_case/<domain>_use_case.dart` | Mới | |
| State | `lib/presentation/<feature>/cubit/` | Mới | |
| Screen | `lib/presentation/<feature>/view/<feature>_screen.dart` | Mới | |
| Route | `lib/core/common/route.dart` | Sửa | |
| DI | `lib/di/register_module.dart` | Sửa | |
| Endpoint | `lib/data/datasource/remote/url_end_point.dart` | Sửa | |
| l10n | `lib/l10n/arb/app_en.arb`, `app_vi.arb` | Sửa | |
| Test | `test/...` | Mới | |

## 6. Domain

```dart
abstract class <Entity> {
  String get id;
  // trường, kiểu, nullable hay không, ý nghĩa
}
```

| Trường | Kiểu | Bắt buộc | Nguồn từ API | Ghi chú |
|---|---|---|---|---|

## 7. API

| Mục | Giá trị |
|---|---|
| Method và path | `GET /orders?page=&perPage=` |
| Request | |
| Response | `BaseListResponseModel<OrderResponseModel>` |
| Lỗi nghiệp vụ | mã lỗi → hành vi |

## 8. Lưu trữ

Không áp dụng | Nơi lưu, khoá, ai sở hữu vòng đời, xoá khi nào
(theo `storage-patterns.md`).

## 9. State và effect

```dart
class <Feature>State extends BaseAppState<Object> {
  // trường, giá trị khởi tạo
}

sealed class <Feature>Effect {}
// <Feature>NavigateXEffect, <Feature>ShowErrorEffect(retryAction)
```

| Hành động của người dùng | Hàm Cubit | State chuyển thế nào | Effect |
|---|---|---|---|

## 10. Giao diện

Ghi widget có sẵn được dùng lại (`sli_common`, `lib/widget/`, feature khác),
hoặc "mới" nếu phải viết. Khoảng cách và bo góc dùng `SliSpacing`/`SliRadii`.

| Thành phần | Widget dùng lại hoặc mới | Key l10n |
|---|---|---|

## 11. Điều hướng

| Route | Path | Tham số | Đi từ đâu |
|---|---|---|---|

## 12. Lỗi, rỗng, tải, ngoại tuyến

| Tình huống | Hiển thị | Hành động thử lại |
|---|---|---|

## 13. Bảo mật và quyền riêng tư

Dữ liệu nhạy cảm, log cần che, quyền hệ thống, deep link.

## 14. Hiệu năng

| Luồng | Loại thao tác | Ngưỡng đề xuất |
|---|---|---|

## 15. Test

| Yêu cầu | Test | Cấp |
|---|---|---|
| R1 | | unit / widget / acceptance |

## 16. Truy vết

| Yêu cầu | Thiết kế | Test |
|---|---|---|

## 17. Câu hỏi nghiệp vụ

Những chỗ tài liệu chưa rõ và ảnh hưởng hành vi. Không tự đoán.

## 18. Lịch sử duyệt

| Ngày | Ai | Thay đổi |
|---|---|---|
