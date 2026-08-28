# Flutter Bloc/Cubit Base

Base Flutter cá nhân theo hướng production, xây trên Clean Architecture, môi
trường có kiểu rõ ràng, Cubit/BLoC, dependency injection sinh mã, networking an
toàn, và bộ UI toolkit tái sử dụng.

Người mới bắt đầu tại **[Mục lục tài liệu](docs/README.md)** để biết cần đọc gì
cho từng loại công việc và cách truy vết quyết định/roadmap/review.

## Tổng quan kiến trúc

```text
Screen → Cubit/BLoC → UseCase → Repository interface → RepositoryImpl
       → Remote/Local DataSource → Dio / platform service
```

- Cubit là lựa chọn mặc định cho state đơn giản theo màn hình; BLoC cổ điển vẫn
  được hỗ trợ cho luồng nhiều event, concurrency, hoặc cần audit rõ.
- State dùng `BaseAppState + Equatable + copyWith`. Freezed và HydratedBloc
  không phải yêu cầu mặc định của base.
- REST qua `ApiHandler` là mặc định. GraphQL là năng lực mở rộng tùy chọn.
- DI dùng `get_it + injectable`; class feature nhận dependency qua constructor.
- Routing giữ `SLIRouting / AppPage`.
- `sli_common` là Git submodule thật, sở hữu UI tái sử dụng, design token, và
  adapter Shadcn. Code sản phẩm import API toolkit, không phụ thuộc trực tiếp
  vào Shadcn.

Quy tắc chi tiết: [kiến trúc](docs/architecture/README.md) ·
[ADR](docs/adr/README.md) · [quy trình AI](ai-process.md).

## Bắt đầu nhanh

Yêu cầu môi trường nằm trong [docs/prerequisites.md](docs/prerequisites.md).

```bash
git clone --recurse-submodules <repository-url>
cd bloc_cubit_base
dart pub global activate derry
derry bootstrap
derry base doctor
derry run dev
```

Với clone đã tồn tại:

```bash
git submodule sync --recursive
git submodule update --init --recursive
derry get
derry gen
```

Script sẽ dùng FVM nếu có, nếu không sẽ dùng Flutter trên `PATH`. Phiên bản
Flutter được pin trong `.fvmrc`.

## Môi trường

Entrypoint chỉ chọn môi trường có kiểu; `bootstrap()` xử lý toàn bộ khởi tạo ở
một nơi xác định.

| Môi trường | Entrypoint | Inspector |
|---|---|---|
| local | `lib/main_local.dart` | bật |
| development | `lib/main_dev.dart` | bật |
| staging | `lib/main_staging.dart` | bật |
| production | `lib/main_prod.dart` | tắt |

Giá trị runtime truyền qua `--dart-define`:

```bash
./scripts/flutterw.sh run --flavor dev -t lib/main_dev.dart \
  --dart-define=API_BASE_URL=https://dev.example.com \
  --dart-define=ENABLE_NETWORK_INSPECTOR=true
```

Production sẽ chặn URL không phải HTTPS và chặn network inspector bị bật nhầm.
Xem [environment và bootstrap](docs/architecture/environment-bootstrap.md).

## Lệnh hằng ngày

```bash
derry gen       # build_runner + format
derry analyze   # analyzer + kiểm tra boundary kiến trúc
derry test      # test app
derry quality   # format, analyzer, boundary, test
```

Build local, phân phối Firebase và release Store là ba luồng khác nhau. Xem
[hướng dẫn Derry và build](docs/guides/use-derry-and-build.md) trước khi dùng
lệnh có side effect từ xa.

DI sinh mã nằm ở `lib/di/injection.config.dart`. Không sửa file này thủ công.
Gắn annotation cho class, inject dependency qua constructor, rồi chạy
`derry gen`. Dependency runtime/platform vẫn khai báo rõ trong
`lib/di/register_module.dart`.

## UI toolkit

`lib/modules/sli_common` trỏ tới repo độc lập `sli_common`. Dùng API `Sli*` ổn
định cho component và token tái sử dụng. Shadcn chỉ là chi tiết triển khai phía
sau facade này, để app có thể theme hoặc thay thế mà không kéo API bên thứ ba
vào từng màn hình.

Xem [dùng sli_common](docs/guides/use-sli-common.md) và
[kiến trúc UI toolkit](docs/architecture/ui-toolkit.md).

## Tạo feature và app mới

- [Tạo app từ base này](docs/guides/create-app-from-base.md)
- [Thêm feature theo Clean Architecture](docs/guides/add-feature.md)
- [Chọn Cubit hay BLoC](docs/guides/choose-cubit-or-bloc.md)
- [Thêm môi trường](docs/guides/add-environment.md)
- [Dùng Derry, build.sh và Fastlane](docs/guides/use-derry-and-build.md)
- [Trạng thái modernization hiện tại](docs/modernization-status.md)

AI agent phải bắt đầu từ [AGENTS.md](AGENTS.md). Package/application identifier
hiện là giá trị template và phải đổi khi fork base.
