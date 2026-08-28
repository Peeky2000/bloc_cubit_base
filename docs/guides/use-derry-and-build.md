# Dùng Derry, build.sh và Fastlane

## Mục tiêu

Derry là cửa vào thống nhất cho automation của project. Derry không thay thế
Flutter hoặc Fastlane:

```text
             ┌→ Dart Base CLI → doctor/create/rename
Derry facade ┤
             └→ build.sh/scripts → Flutter/FVM hoặc Fastlane → artifact/delivery
```

- Derry giúp tìm và nhớ lệnh.
- Dart CLI sở hữu identity validation và filesystem mutation của base.
- Shell script kiểm tra toolchain và orchestration build/delivery.
- Flutter/FVM build artifact local.
- Fastlane xử lý signing và phân phối lên Firebase/Store.

Pattern command catalog của Derry được học từ `base_flutter_project_v2`, nhưng
cấu hình ở base này đã được điều chỉnh cho FVM wrapper, architecture gate và
quality gate riêng. Phần Firebase/Store không được bê từ V2: nó tận dụng
`build.sh` + Fastlane vốn đã có trong `bloc_cubit_base` và chuẩn hóa lại cho an
toàn hơn.

Xem toàn bộ command hiện có bằng:

```bash
derry ls -d
```

## Chọn đúng nhóm lệnh

| Nhu cầu | Lệnh | Có side effect từ xa? |
|---|---|---|
| Kiểm tra template identity | `derry base doctor` | Không |
| Xem plan đổi identity | `derry rename -- ...` | Không nếu chưa `--apply` |
| Xem plan tạo app | `derry create -- ...` | Không nếu chưa `--apply` |
| Setup clone mới | `derry bootstrap` | Không, ngoài tải dependency |
| Cập nhật package | `derry get` | Không, ngoài tải dependency |
| Sinh code | `derry gen` | Không |
| Kiểm tra trước commit/PR | `derry quality` | Không |
| Chạy app | `derry run <env>` | Không |
| Tạo artifact production local | `derry build <type>` | Không |
| Gửi bản dev/staging/prod cho tester | `derry distribute <platform>` | Có, Firebase và tùy chọn Git tag |
| Upload Google Play/TestFlight | `derry release <platform>` | Có, bắt buộc xác nhận |

Nguyên tắc: nếu chỉ cần file APK/AAB/IPA trên máy, dùng `build`; không dùng
`distribute` hoặc `release`.

## Base CLI: doctor, create và rename

```bash
derry base doctor
derry rename -- \
  --display-name "My App" \
  --package-name my_app \
  --bundle-id com.company.my_app
derry create -- \
  --destination ../my_app \
  --display-name "My App" \
  --package-name my_app \
  --bundle-id com.company.my_app
```

`create` và `rename` dry-run mặc định. Chỉ thêm `--apply` sau khi review plan.
Logic nằm trong `tool/base_cli.dart`; `derry.yaml` chỉ forward argument. Xem
[hướng dẫn tạo/đổi tên app](create-app-from-base.md) để biết phần CLI tự động và
phần Firebase/signing/branding phải làm thủ công.

## Lệnh phát triển hằng ngày

```bash
derry bootstrap
derry get
derry gen
derry format
derry analyze
derry test
derry quality
```

`quality` chạy format check, analyzer, architecture boundary và test. `gen`
chạy build_runner rồi format source do app sở hữu.

## Chạy từng môi trường

```bash
derry run local
derry run dev
derry run staging
derry run prod
```

`local` dùng Dart entrypoint `main_local.dart` nhưng dùng native flavor `dev`,
vì project chỉ có native flavor `dev`, `staging`, và `prod`.

Truyền thêm `--dart-define` sau dấu `--`:

```bash
derry run dev -- \
  --dart-define=API_BASE_URL=https://dev.example.com \
  --dart-define=ENABLE_NETWORK_INSPECTOR=true
```

## Build artifact local

```bash
derry build apk
derry build appbundle
derry build ipa
```

Ba command này build `prod` và không upload. Có thể truyền option Flutter bổ
sung sau dấu `--`:

```bash
derry build appbundle -- --dart-define=API_BASE_URL=https://api.example.com
```

## Phân phối Firebase bằng build.sh cũ đã chuẩn hóa

Lệnh Derry gọi lại `build.sh`; logic Fastlane hiện có không bị copy sang YAML.

```bash
derry distribute android -- --environment dev --audience tester
derry distribute ios -- --environment staging --audience client
derry distribute all -- --environment prod --audience tester
```

Giá trị hợp lệ:

- `--environment`: `dev`, `staging`, `prod`.
- `--audience`: `tester`, `client`.
- `--platform`: đã được Derry truyền là `android`, `ios`, hoặc `all`.
- `--push-tag`: opt-in tạo và push Git tag sau khi upload thành công.
- `--dry-run`: chỉ in platform, lane và tester group; không build/upload/push.

Luôn dry-run trước khi chạy delivery thật:

```bash
derry distribute android -- \
  --environment dev \
  --audience tester \
  --dry-run
```

Tên group mặc định giữ tương thích với script cũ:

| Audience | Android | iOS |
|---|---|---|
| tester | `tester-android` | `tester-ios` |
| client | `client-android` | `client-ios` |

Group được truyền trực tiếp vào tiến trình Fastlane, không sửa `.env` rồi reset.

## Release lên Store

Store upload bắt buộc cờ xác nhận:

```bash
derry release android -- --confirm-store
derry release ios -- --confirm-store
```

Dry-run không cần credential và không upload:

```bash
derry release android -- --confirm-store --dry-run
```

Chỉ chạy release thật sau khi app đã thay toàn bộ branding, bundle/application
identifier, Firebase config, signing và store credential. Base hiện vẫn giữ
Fastlane sample `Giaohang247`, vì vậy đây là capability để tái sử dụng sau khi
fork, không phải lệnh release an toàn cho mọi clone ngay lập tức.

## Gọi build.sh trực tiếp

Derry là cách khuyến nghị. Khi debug script, có thể gọi engine trực tiếp:

```bash
./build.sh distribute \
  --platform android \
  --environment dev \
  --audience tester \
  --dry-run

./build.sh store \
  --platform ios \
  --confirm-store \
  --dry-run
```

Các flag cũ như `--dev-debug-android --tester` vẫn được map tạm thời và in cảnh
báo deprecated. Code mới và tài liệu mới phải dùng CLI có tên ở trên.

## Chuẩn bị Fastlane cho từng app fork

Trước khi bỏ `--dry-run`:

1. Chạy `bundle install` trong `android/` và `ios/`.
2. Tạo `.env.secret.android` / `.env.secret.ios` từ secret local hoặc CI.
3. Thay key path, application identifier, scheme, provisioning và Firebase app
   ID của sample.
4. Kiểm tra working tree, branch và release notes.
5. Chạy distribution cho một platform/môi trường trước khi chọn `all`.

Không commit token, signing key, provisioning profile hoặc store API key.
