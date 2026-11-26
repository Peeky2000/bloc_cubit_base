# 2. Cài và chạy

## Cần có

- Flutter đúng bản trong `.fvmrc` (3.50.1). Nên dùng [FVM](https://fvm.app).
- Java 17+ cho Android (JDK đi kèm Android Studio là đủ).
- Xcode cho iOS. Không cần CocoaPods: plugin đi qua Swift Package Manager.
- Derry: `dart pub global activate derry`.

## Clone và chạy

```bash
git clone --recurse-submodules https://github.com/Peeky2000/bloc_cubit_base.git
cd bloc_cubit_base
derry bootstrap        # submodule, pub get, sinh code
derry quality          # phải xanh trước khi làm gì tiếp
derry run dev          # chạy app môi trường dev
```

Quên `--recurse-submodules` thì chạy `git submodule update --init --recursive`
rồi `derry bootstrap`.

App mở màn splash rồi sang đăng nhập. Server mẫu không có thật, nên đăng nhập
chỉ để thấy luồng lỗi; đổi `API_BASE_URL` (xem dưới) để gọi server của mình.

## Môi trường

| Môi trường | Lệnh | Entrypoint | Network inspector (Alice) |
|---|---|---|---|
| local | `derry run local` | `lib/main_local.dart` | bật |
| dev | `derry run dev` | `lib/main_dev.dart` | bật |
| staging | `derry run staging` | `lib/main_staging.dart` | bật |
| prod | `derry run prod` | `lib/main_prod.dart` | tắt, bắt buộc HTTPS |

Cấu hình qua `--dart-define`, không dùng file `.env`: `API_BASE_URL`,
`ENABLE_NETWORK_INSPECTOR`. Ngoài prod, lắc máy để mở Alice xem request.

## Khi có lỗi

| Hiện tượng | Làm |
|---|---|
| `derry quality` đỏ ngay sau clone | Thiếu submodule hoặc chưa `derry bootstrap` |
| Android báo AGP/Gradle quá cũ | Dùng đúng Flutter trong `.fvmrc`; đừng hạ AGP |
| iOS lỗi package | Mở `ios/Runner.xcworkspace` một lần để Xcode tải Swift package, hoặc `flutter clean` rồi build lại |
| Lần build Android đầu rất lâu | Bình thường: Gradle 9.5 tải khoảng 1 GB một lần |

Chi tiết: [điều kiện dự án](../prerequisites.md) ·
[Derry và build](../guides/use-derry-and-build.md).

Tiếp: [Kiến trúc](03-kien-truc.md).
