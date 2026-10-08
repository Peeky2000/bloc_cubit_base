# Flutter Bloc/Cubit Base

Base Flutter cá nhân theo hướng production. Base gồm Clean Architecture, môi
trường có kiểu rõ ràng, Cubit/BLoC, dependency injection sinh mã, networking an
toàn, bộ UI toolkit tái sử dụng, công cụ đo hiệu năng trên máy thật và bộ agent,
skill cho AI.

Người mới bắt đầu tại **[mục lục tài liệu](docs/README.md)**. Người dùng AI agent
bắt đầu tại **[bộ công cụ AI](docs/guides/ai-toolbox.md)**.

## Có gì trong base

| Phần | Nội dung | Bắt đầu tại |
|---|---|---|
| Kiến trúc | Clean Architecture, Cubit mặc định, BLoC khi cần, `get_it + injectable` | [Kiến trúc](docs/architecture/README.md) |
| Môi trường | local, dev, staging, prod với `bootstrap()` tập trung | [Environment và bootstrap](docs/architecture/environment-bootstrap.md) |
| Networking | Dio qua `ApiHandler`, refresh token single-flight, redaction log | [Networking](docs/architecture/networking.md) |
| Lưu trữ và phiên | `SessionRepo` nắm token và tài khoản, secure storage cho bí mật | [Mẫu lưu trữ](.agents/skills/flutter-datasource/references/storage-patterns.md) |
| UI toolkit | Submodule `sli_common` với API `Sli*`, Shadcn nằm sau facade | [Dùng sli_common](docs/guides/use-sli-common.md) |
| Đo hiệu năng | Mở app, độ mượt, bộ nhớ, mạng trên máy thật với dữ liệu thật | [Đo hiệu năng app](docs/guides/measure-performance.md) |
| Review và bảo mật | Chọn file và luật review theo tầng, audit bảo mật mobile | [Bộ công cụ AI](docs/guides/ai-toolbox.md) |
| AI agent | Agent PM, dev, tester, reviewer, đo và sửa hiệu năng, cùng 24 skill | [AGENTS.md](AGENTS.md) |
| Sổ quyết định | Mọi lựa chọn kỹ thuật được ghi và tra cứu, để các tính năng làm giống nhau | [docs/decisions](docs/decisions/README.md) |
| Build và phát hành | Derry, `build.sh`, Fastlane, Firebase App Distribution | [Derry và build](docs/guides/use-derry-and-build.md) |

## Kiến trúc

```text
Screen → Cubit/BLoC → UseCase → Repository interface → RepositoryImpl
       → Remote/Local DataSource → Dio / platform service
```

- Cubit là lựa chọn mặc định. BLoC dùng khi cần nhiều event, xử lý đồng thời
  hoặc cần audit rõ.
- State dùng `BaseAppState + Equatable + copyWith`. Hành động một lần như điều
  hướng hay hiện dialog đi qua `UiEffect` có kiểu, Screen xử lý.
- Class nhận dependency qua constructor. Chỉ composition root mới lấy từ
  `getIt`.
- Domain không phụ thuộc Flutter, data hay SDK nền tảng. SDK dùng callback được
  bọc trong data adapter và trả về một kết quả duy nhất
  ([mẫu luồng](.agents/skills/flutter-repository/references/async-flow-patterns.md)).
- Dữ liệu sống chết cùng nhau có đúng một module quản lý. Đăng xuất và hết
  phiên xoá cả token lẫn tài khoản.
- Routing dùng `SLIRouting / AppPage`. REST là mặc định, GraphQL là tuỳ chọn.

Quyết định kiến trúc: [ADR](docs/adr/README.md) · quy trình làm việc với AI:
[ai-process.md](ai-process.md).

## Bắt đầu nhanh

Yêu cầu môi trường nằm trong [docs/prerequisites.md](docs/prerequisites.md).
Phiên bản Flutter được pin trong `.fvmrc`. Script dùng FVM nếu có, nếu không thì
dùng Flutter trên `PATH`.

```bash
git clone --recurse-submodules <repository-url>
cd bloc_cubit_base
dart pub global activate derry
derry bootstrap
derry base doctor
derry run dev
```

Với clone đã có sẵn:

```bash
git submodule sync --recursive
git submodule update --init --recursive
derry get
derry gen
```

Build Android cần Java 17 trở lên, Gradle 8.14 và khoảng 10 GB ổ đĩa trống.
App hỗ trợ Android 7.0 (minSdk 24) trở lên. iOS dùng CocoaPods.

## Môi trường

| Môi trường | Entrypoint | Network inspector |
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

Production chặn URL không phải HTTPS và chặn network inspector bị bật nhầm.

## Lệnh hằng ngày

| Lệnh | Việc |
|---|---|
| `derry gen` | Sinh code (DI, model, asset) và format |
| `derry analyze` | Analyzer và kiểm tra ranh giới kiến trúc |
| `derry test` | Test của app |
| `derry quality` | Format, analyzer, kiểm tra kiến trúc và test cho cả app lẫn `sli_common` |
| `derry review plan` | Liệt kê file đã thay đổi cần review và luật cho từng file |
| `derry decision search "<chủ đề>"` | Tìm quyết định kỹ thuật đã chốt |
| `derry scaffold -- <feature> [--bloc] [--data] --apply` | Sinh khung feature đúng convention |
| `derry perf run` | Đo hiệu năng trên máy thật |
| `derry perf diagnose` | Đo kèm chẩn đoán widget chậm nhất |
| `derry perf approve` | Đo lại và lưu kết quả làm mốc so sánh |

Xem toàn bộ lệnh bằng `derry ls -d`. Build local, phân phối Firebase và phát
hành Store là ba luồng khác nhau; đọc [hướng dẫn Derry và build](docs/guides/use-derry-and-build.md)
trước khi chạy lệnh có tác động từ xa.

Không sửa `lib/di/injection.config.dart` bằng tay. Gắn annotation cho class,
inject qua constructor rồi chạy `derry gen`.

## Làm việc với AI

Trong Claude Code có sẵn các lệnh:

| Lệnh | Việc |
|---|---|
| `/tech-design <tài liệu>` | Viết thiết kế kỹ thuật `tech.md` từ tài liệu để duyệt trước khi code |
| `/build-feature <tài liệu>` | Thiết kế, chờ duyệt, code đúng convention, agent test kiểm tra độc lập |
| `/decision <câu hỏi>` | Tra cứu hoặc ghi quyết định kỹ thuật |
| `/perf-check [màn hoặc luồng]` | Đo hiệu năng, tìm nguyên nhân, sửa, đo lại và viết báo cáo tiếng Việt |
| `/perf-scenario <AC, spec hoặc mô tả>` | Viết kịch bản đo và đề xuất ngưỡng, kể cả từ AC không có con số |
| `/security-audit [phạm vi]` | Audit bảo mật mobile, ghi báo cáo vào `docs/reviews/` |

Với agent khác, nói bằng lời là đủ; agent tự nạp skill phù hợp. Câu gọi mẫu,
danh sách agent và skill nằm trong [bộ công cụ AI](docs/guides/ai-toolbox.md).
AI agent phải bắt đầu từ [AGENTS.md](AGENTS.md).

## Đo hiệu năng

Phần đo chạy trên máy thật ở profile mode, với server thật và một tài khoản test
riêng. Mỗi lần đo được chấm hai kiểu: PASS hoặc FAIL so với mốc đã lưu, và GOOD,
NEEDS_IMPROVEMENT hoặc POOR theo chuẩn Android vitals và Nielsen. Request lỗi
được phân loại theo bên phải xử lý: mobile, backend, mạng hay môi trường.

| Tài liệu | Nội dung |
|---|---|
| [Đo hiệu năng app](docs/guides/measure-performance.md) | Chuẩn bị, chạy, đọc kết quả, lỗi thường gặp |
| [Chuẩn và ngưỡng](docs/performance/standards.md) | Từng mốc, nguồn gốc và ý nghĩa |
| [Từ AC tới kịch bản](docs/performance/ac-to-scenario.md) | Ngưỡng mặc định theo loại thao tác |
| [PERFORMANCE.md](PERFORMANCE.md) | Hợp đồng kỹ thuật của runner |

## Tạo app và feature mới

- [Tạo app từ base này](docs/guides/create-app-from-base.md)
- [Thêm feature theo Clean Architecture](docs/guides/add-feature.md); bắt đầu
  bằng `derry scaffold -- <feature> --apply`
- [Chọn Cubit hay BLoC](docs/guides/choose-cubit-or-bloc.md)
- [Thêm môi trường](docs/guides/add-environment.md)
- [Trạng thái modernization](docs/modernization-status.md)

Khi fork, đổi package và application identifier, URL môi trường, file Firebase,
branding và signing. Các màn đăng nhập, đăng ký, splash là ví dụ và có thể thay.
Khi thay luồng đăng nhập, cập nhật
`integration_test/performance/support/perf_app_adapter.dart` để kịch bản đo
hiệu năng vẫn chạy.
