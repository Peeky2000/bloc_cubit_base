# Tạo Hoặc Đổi Tên App Từ Base

Workflow chính thức là:

```text
Derry facade → tool/base_cli.dart → validate → dry-run plan → --apply
```

`tool/base_cli.dart` là source of truth. Derry chỉ cung cấp tên lệnh dễ nhớ;
không có một bộ logic rename khác trong shell script hoặc `derry.yaml`.

## 1. Kiểm tra base trước

```bash
derry base doctor
```

Doctor kiểm tra:

- `pubspec.yaml`, `derry.yaml` và template identity config;
- Dart package, Android application ID và iOS bundle ID có đồng bộ không;
- `MainActivity` package/path;
- Git submodule `sli_common` đã initialize chưa.

`WARN` là debt cần biết; `ERROR` chặn create/rename. Base hiện có thể cảnh báo
path `MainActivity` legacy; `rename --apply` sẽ move về đúng package path.

## 2. Đổi identity trong repository hiện tại

Dry-run mặc định:

```bash
derry rename -- \
  --display-name "My App" \
  --package-name my_app \
  --bundle-id com.company.my_app
```

Đọc toàn bộ danh sách `EDIT`/`MOVE`. Khi plan đúng mới apply:

```bash
derry rename -- \
  --display-name "My App" \
  --package-name my_app \
  --bundle-id com.company.my_app \
  --apply
```

CLI validate tất cả input và kiểm tra file không đổi kể từ lúc lập plan trước
mutation đầu tiên. Nếu một file bị sửa giữa plan/apply, lệnh hủy thay vì ghi đè.

## 3. Tạo app mới từ base

Source Git tree phải sạch vì `git clone` không mang theo thay đổi chưa commit.

Dry-run:

```bash
derry create -- \
  --destination ../my_app \
  --display-name "My App" \
  --package-name my_app \
  --bundle-id com.company.my_app
```

Apply sau khi review:

```bash
derry create -- \
  --destination ../my_app \
  --display-name "My App" \
  --package-name my_app \
  --bundle-id com.company.my_app \
  --apply
```

Create thực hiện theo thứ tự:

1. validate source, destination, identity và Git status;
2. `git clone --recurse-submodules --local` sang destination chưa tồn tại;
3. apply cùng rename engine trong clone;
4. chạy `scripts/bootstrap.sh` để resolve dependency và sinh code;
5. in checklist Firebase/signing/branding còn lại.

Git history của base được giữ nguyên để không phá metadata của submodule. Owner
app quyết định thời điểm tạo remote/history mới. Khi chỉ muốn smoke-test nhanh,
có thể thêm `--skip-bootstrap`; không dùng cờ này cho handoff app thật.

## 4. CLI tự động đổi gì?

| Hạng mục | Tự động |
|---|---|
| `pubspec.yaml` package name | Có |
| Import `package:<old>/...` trong app/docs/tool | Có |
| Android application ID/manifest/Firebase bundle field | Có |
| Kotlin package và `MainActivity` path | Có |
| iOS product bundle identifier/Firebase bundle field | Có |
| Android/iOS native display name theo flavor | Có |
| `tool/base_cli.template.json` cho lần rename tiếp theo | Có |
| Firebase project/client ID/config hợp lệ cho app mới | **Không** |
| Signing key, certificate, provisioning, Store credential | **Không** |
| Icon, splash, API URL và sample product feature | **Không** |
| Class/key legacy như `DeliveryGo`, `Giao Hàng 247`, `mOrder` | **Không tự đoán** |

CLI có thể đổi bundle field nằm trong file Firebase mẫu để native project đồng
bộ, nhưng việc đó **không biến file mẫu thành Firebase config hợp lệ**. Luôn tải
config mới từ đúng Firebase project/flavor.

## 5. Việc bắt buộc làm sau apply

1. Thay Firebase configuration cho `dev`, `staging`, `prod`.
2. Cấu hình signing bằng secret local hoặc CI; không commit secret.
3. Chọn sample vertical slice nào giữ/xóa và xử lý đủ route, l10n, DI, test,
   asset, memory index.
4. Thay icon, splash, color/typography và product copy.
5. Review API URL cùng inspector policy của từng environment.
6. Tìm branding còn lại có chủ ý:

   ```bash
   rg -n "Giaohang247|Giao Hàng 247|DeliveryGo|mOrder" . \
     -g '!lib/modules/sli_common/**' -g '!.git/**'
   ```

## 6. Verify app sinh ra

```bash
derry base doctor
derry gen
derry quality
git submodule status
```

Sau đó chạy từng entrypoint cần dùng và ít nhất một Android/iOS native debug
build. `create --apply` thành công không phải bằng chứng Firebase, signing hoặc
Store delivery đã sẵn sàng.

## Gọi engine trực tiếp

Khi debug hoặc chạy CI không có Derry:

```bash
dart run tool/base_cli.dart --help
dart run tool/base_cli.dart doctor
dart run tool/base_cli.dart rename \
  --display-name "My App" \
  --package-name my_app \
  --bundle-id com.company.my_app
```

Không thêm script rename thứ hai. Nếu cần hỗ trợ identity mới, cập nhật engine,
test, Derry facade và guide trong cùng thay đổi.
