# D-0004: Upload ảnh có tiến trình

- Trạng thái: proposed
- Ngày: 2026-10-08
- Phạm vi: feature
- Tags: upload,image,progress
- Tính năng: 
- Thay thế:
- Bị thay bởi:

## Bối cảnh

Nhiều tính năng cần chọn hoặc chụp ảnh rồi tải lên (ảnh đại diện, hoá đơn,
ảnh sản phẩm). `ApiHandler` chưa có hàm multipart; `ApiClient` đặt
`sendTimeout` 30 giây, mà Dio áp cho toàn bộ body nên file lớn trên mạng chậm
sẽ lỗi. `sli_common` có `MultiImagePicker` dựa trên `photo_manager` nhưng nhận
`BuildContext` và tự điều hướng. `image_picker` chưa có trong pubspec.

## Quyết định

Chọn ảnh qua port `MediaPickerRepo` trả một `Future<PickImageOutcome>`; tải lên
qua port `ImageUploadRepo` trả `Stream<UploadEvent>` (tiến trình rồi đúng một
sự kiện kết thúc), xây trên Dio multipart với `onSendProgress` và
`CancelToken`.

- Plugin chọn ảnh đề xuất: `image_picker` (adapter `ImagePickerMediaRepo`,
  thu nhỏ 2048px, chất lượng 85).
- Đề xuất thêm `ApiHandler.upload<T>(path, {FormData data, parser,
  onSendProgress, cancelToken})`, cài trong `ApiClient` qua `_dio` và
  `_remapError`, `sendTimeout` 2 phút cho riêng upload.
- Domain: `LocalImage`, `UploadedImage`, `PickImageOutcome`
  (`ImagePicked`/`PickCancelled`), `UploadEvent` (`UploadProgress`,
  `UploadCompleted`, `UploadSuperseded`), `MediaPickFailure`, `UploadFailure`.
- Upload mới cùng `slot` thay thế upload cũ; huỷ subscription huỷ request;
  tiến trình tối đa một lần mỗi phần trăm; kiểm tra kích thước (10 MB) và
  loại file trong UseCase.
- Cubit giữ `photo`, `pending` (xem trước), `progress`; lỗi giữ `pending` để
  thử lại không cần chọn lại.

## Phương án đã cân nhắc

| Phương án | Vì sao không chọn |
|---|---|
| `MultiImagePicker` của `sli_common` | Cần `BuildContext`, tự push route, trả `File`; Cubit không test được |
| `photo_manager` trực tiếp | Cần quyền thư viện ảnh và tự dựng UI chọn; `image_picker` dùng picker hệ thống, thường không cần quyền |
| `file_picker` | Hợp với tài liệu; chọn ảnh/camera kém hơn `image_picker` |
| Một `Future` cho upload kèm callback tiến trình | Trái quy tắc "Stream cho nhiều kết quả" của `async-flow-patterns.md` |
| Upload nền (WorkManager/BGTask) hoặc tus | Phức tạp hơn mức cần; đề xuất riêng khi sản phẩm yêu cầu |

## Hệ quả

- Mọi luồng chọn và tải ảnh dùng hai port này; thêm `image_picker` và
  `ApiHandler.upload` khi tính năng đầu tiên cần và quyết định được duyệt.
- Hướng dẫn: `.agents/skills/flutter-patterns/references/image_upload.md`.
- Code mẫu và test bảo vệ: `test/patterns/image_upload_pattern_test.dart`
  (15 test, gồm Dio thật với `HttpClientAdapter` giả: body multipart, tiến
  trình, `sendTimeout`, huỷ, HTTP 413).
