# ADR 0007: Dart Base CLI Phía Sau Derry Facade

- Trạng thái: Accepted
- Ngày: 2026-08-28

## Bối cảnh

Base cần một workflow tạo/đổi tên application có thể kiểm tra và dùng lại trên
macOS, Linux và CI. Nếu đặt logic thay file, validate identifier và điều phối
Git trực tiếp trong `derry.yaml` hoặc nhiều shell script, hành vi sẽ khó test,
dễ lệch giữa các lệnh và khó rollback khi validation thất bại.

## Quyết định

- `tool/base_cli.dart` là source of truth cho workflow `doctor`, `rename` và
  `create` của base.
- Derry chỉ là facade ngắn, ổn định để gọi Dart CLI; không chứa lại business
  logic đổi tên hoặc tạo project.
- Lệnh có khả năng sửa filesystem phải **dry-run mặc định**. Chỉ `--apply` mới
  được phép ghi file hoặc tạo project.
- Mọi input, source tree, destination và replacement plan phải được validate
  đầy đủ trước khi mutation đầu tiên xảy ra.
- CLI chỉ tự động hóa dữ liệu deterministic. Firebase, signing và secret theo
  từng sản phẩm phải được báo rõ trong post-create checklist, không được đoán
  hoặc copy credential cá nhân một cách im lặng.

## Hệ quả

- Contributor có UX đơn giản qua `derry`, trong khi logic lõi vẫn unit-test
  được bằng Dart.
- Dry-run có thể dùng trong review và CI mà không tạo side effect.
- Việc thêm trường branding/native mới phải cập nhật cùng validator, test và
  guide; không thêm một script rename cạnh tranh.
- `build.sh`/Fastlane tiếp tục phụ trách build và delivery, không phụ trách tạo
  hoặc đổi identity của project.
