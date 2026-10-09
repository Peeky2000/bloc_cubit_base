# D-0004: Upload ảnh có tiến trình

- Trạng thái: accepted
- Ngày: 2026-10-08
- Phạm vi: feature
- Tags: upload,image,progress
- Tính năng: 
- Thay thế:
- Bị thay bởi:

## Bối cảnh

Nhiều tính năng cần chọn hoặc chụp ảnh rồi tải lên (ảnh đại diện, hoá đơn,
ảnh sản phẩm). `ApiHandler` chưa có hàm multipart; `ApiClient` đặt
`sendTimeout` 30 giây, mà IO adapter của Dio áp cho toàn bộ body nên file lớn
trên mạng chậm sẽ lỗi. Ảnh chụp mang EXIF có toạ độ GPS. Google Play cấm
`READ_MEDIA_IMAGES` cho nhu cầu chọn ảnh một lần. `sli_common` có
`MultiImagePicker` dựa trên `photo_manager` nhưng nhận `BuildContext` và tự
điều hướng. `image_picker` chưa có trong pubspec.

## Quyết định

Chọn ảnh qua port `MediaPickerRepo` trả một `Future<PickImageOutcome>`;
adapter dùng picker hệ thống (`image_picker`) rồi mã hoá lại một lần bằng
`flutter_image_compress` (cạnh ngắn 1600 px, JPEG 85, xoay đúng chiều, bỏ
toàn bộ EXIF gồm GPS); tải lên qua port `ImageUploadRepo` trả
`Stream<UploadEvent>` (tiến trình rồi đúng một sự kiện kết thúc) trên Dio
multipart qua `ApiClient`.

- Package (thêm cùng tính năng đầu tiên): `image_picker: ^1.2.4`,
  `image_picker_android: ^0.8.13+22`, `image_picker_platform_interface:
  ^2.11.0`, `flutter_image_compress: ^2.5.1`; `dio: ^5.10.0` (có
  `FormData.clone()` đúng). Đã resolve cùng đồ thị phụ thuộc của app trên
  Flutter 3.44.5.
- Android: bật `useAndroidPhotoPicker` (Photo Picker, không cần quyền, bản
  backport qua Play services do manifest của plugin khai báo); không khai báo
  `READ_MEDIA_*`, gỡ các quyền mà `alice`→`open_filex` và
  `sli_common`→`photo_manager` merge vào bằng `tools:node="remove"`.
  iOS: `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`;
  `requestFullMetadata: false` (PHPicker không hỏi quyền).
- Adapter `ImagePickerMediaRepo`: gộp lần chọn đang mở, `retrieveLostImage()`
  cho trường hợp Android huỷ activity khi mở camera, xoá file gốc (còn GPS),
  map mã lỗi plugin sang `MediaPickFailureCode`.
- Đề xuất thêm `ApiHandler.upload<T>(path, {FormData data, parser,
  onSendProgress, cancelToken})`, cài trong `ApiClient` qua `_dio` và
  `_remapError`; `sendTimeout` theo kích thước body (30 s + body ở 32 KB/s);
  map `connectionError`, `sendTimeout` và `NetworkIssueException` từ
  `NetworkInterceptor` thành `NetworkIssueException`.
- Mỗi lần thử tạo `FormData` và `MultipartFile.fromFile` mới; không tự retry,
  người dùng bấm thử lại.
- Domain: `LocalImage`, `UploadedImage`, `PickImageOutcome`
  (`ImagePicked`/`PickCancelled`), `UploadEvent` (`UploadProgress`,
  `UploadCompleted`, `UploadSuperseded`), `MediaPickFailure`, `UploadFailure`.
- Upload mới cùng `slot` thay thế upload cũ; huỷ subscription huỷ request;
  tiến trình tối đa một lần mỗi phần trăm; kiểm tra kích thước (10 MB) và
  loại file trong UseCase.
- Cubit giữ `photo`, `pending` (xem trước), `progress`; lỗi giữ `pending` để
  thử lại không cần chọn lại; `recoverLostPick()` gọi một lần khi mở Screen.

## Phương án đã cân nhắc

| Phương án | Vì sao không chọn |
|---|---|
| `maxWidth/maxHeight/imageQuality` của `image_picker` (bản trước) | Giữ EXIF: `ExifDataCopier` trên Android chép cả GPS, iOS chép metadata gốc; iOS không nén HEIC/PNG |
| Gửi ảnh gốc, server xử lý | Ảnh 12–48 MP nặng 3–15 MB trên mạng di động, dễ vượt 10 MB; GPS đã rời máy |
| `flutter_image_compress` với `keepExif: true` | Mang theo GPS |
| Package `image` (Dart thuần, 4.10.1) để resize và bỏ EXIF | Giải mã ảnh 12 MP+ bằng Dart chậm và tốn bộ nhớ, phải chạy isolate; encoder native nhanh hơn |
| `MultiImagePicker` của `sli_common` / `photo_manager` | Cần `BuildContext`, tự push route; cần quyền thư viện ảnh, `READ_MEDIA_IMAGES` trái chính sách Play cho dùng một lần |
| `file_picker` | Hợp với tài liệu; chọn ảnh/camera kém hơn `image_picker` |
| Một `Future` cho upload kèm callback tiến trình | Trái quy tắc "Stream cho nhiều kết quả" của `async-flow-patterns.md` |
| `sendTimeout` cố định 2 phút (bản trước) | 10 MB ở 256 kbit/s cần khoảng 5,5 phút; theo kích thước thì đủ cho file lớn mà không treo lâu với file nhỏ |
| Repo tự retry | Upload không idempotent khi server đã nhận; `FormData` chỉ gửi được một lần; để người dùng thử lại |
| Presigned URL hoặc resumable (S3, GCS) | Hợp cho file lớn hoặc video, cần backend cấp và xác nhận URL; ảnh đã nén ≤1 MB thì một request là đủ. Đề xuất riêng khi cần |
| Upload nền (`background_downloader` 9.6.4: URLSession/WorkManager) hoặc tus | Phức tạp hơn mức cần; đề xuất riêng khi sản phẩm yêu cầu |

## Hệ quả

- Mọi luồng chọn và tải ảnh dùng hai port này; thêm các package trên và
  `ApiHandler.upload` khi tính năng đầu tiên cần và quyết định được duyệt.
- Thay đổi base cần duyệt: `ApiHandler.upload` trong
  `lib/data/datasource/remote/api_client.dart`; sửa
  `_apiErrorToInternalError` (hôm nay lỗi offline `connectionError` của
  `NetworkInterceptor` thành `ServerException`, hiện thông báo chung thay vì
  "mất mạng"); gỡ `READ_MEDIA_*` trong `android/app/src/main/AndroidManifest.xml`.
- Hướng dẫn và nguồn: `.agents/skills/flutter-patterns/references/image_upload.md`.
- Code mẫu và test bảo vệ: `test/patterns/image_upload_pattern_test.dart`
  (18 test, gồm Dio thật với `NetworkInterceptor` và `HttpClientAdapter` giả:
  body multipart dù interceptor đặt JSON, tiến trình, `sendTimeout` theo kích
  thước, offline, thử lại, huỷ, HTTP 413; Cubit khôi phục ảnh bị mất). Adapter
  `ImagePickerMediaRepo` đã chạy `flutter analyze` sạch trên 3.44.5.

## Duyệt

PM chấp nhận ngày 2026-10-08 sau khi đối chiếu best practice. Khi áp dụng lần đầu: thêm `ApiHandler.upload` với timeout theo dung lượng file và sửa ánh xạ lỗi ngoại tuyến trong `api_client.dart`. Kích thước 1600 px và việc xoá vị trí GPS khỏi ảnh là mặc định; sản phẩm cần khác thì ghi quyết định thay thế.
