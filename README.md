# Flutter Bloc/Cubit Base

Base Flutter để bắt đầu app mobile mới: kiến trúc sạch, convention được kiểm
tra tự động, và một bộ agent AI biết cách viết code theo đúng convention đó.

Tài liệu nghiệp vụ (PRD, AC, thiết kế) đến từ bên ngoài. Base lo phần kỹ
thuật: thiết kế kỹ thuật, sinh khung, viết code, viết test, đo hiệu năng,
review. Bạn chỉ cần duyệt.

```text
Tài liệu nghiệp vụ ──▶ /tech-design ──▶ tech.md ──▶ PM duyệt ──▶ /build-feature
                                                                    │
           code đúng convention + test + agent test kiểm tra độc lập ◀┘
```

**Đọc theo thứ tự:** README này → [sổ tay dự án thật](docs/guides/start-real-project.md)
→ [bộ công cụ AI](docs/guides/ai-toolbox.md). Mọi tài liệu khác có trong
[mục lục](docs/README.md).

---

## Mục lục

1. [Có gì trong base](#có-gì-trong-base)
2. [Cài đặt lần đầu](#cài-đặt-lần-đầu)
3. [Bắt đầu một dự án thật](#bắt-đầu-một-dự-án-thật)
4. [Làm một tính năng](#làm-một-tính-năng)
5. [Lệnh hằng ngày](#lệnh-hằng-ngày)
6. [Kiến trúc](#kiến-trúc)
7. [Cấu trúc thư mục](#cấu-trúc-thư-mục)
8. [Tài liệu](#tài-liệu)

---

## Có gì trong base

| Phần | Nội dung |
|---|---|
| Kiến trúc | Clean Architecture, Cubit mặc định, BLoC khi cần, `get_it + injectable` |
| Convention tự kiểm | Lệnh sinh khung feature; test convention và gate kiến trúc chạy trong CI |
| Môi trường | local, dev, staging, prod; một hàm `bootstrap()` duy nhất |
| Networking | Dio qua `ApiHandler`, refresh token chạy một lần cho nhiều request 401, ẩn token trong log |
| Phiên đăng nhập | `SessionRepo` giữ token và tài khoản; đăng xuất xoá cả hai |
| UI toolkit | Submodule [`sli_common`](lib/modules/sli_common) với các widget `Sli*` |
| Mẫu kỹ thuật | Phân trang, form, cache offline, upload, realtime, deep link, push, xin quyền; có code mẫu và test |
| Sổ quyết định | Mọi lựa chọn kỹ thuật được ghi lại để các tính năng làm giống nhau |
| Đo hiệu năng | Mở app, độ mượt, bộ nhớ, mạng; đo trên máy thật với server thật |
| Theo dõi phiên bản | Khung báo lỗi, analytics, feature flag; mặc định tắt, bật khi có Firebase |
| Build và phát hành | Derry, Fastlane, Firebase App Distribution |
| AI | 6 agent, 25 skill, 6 lệnh `/` trong Claude Code |

## Cài đặt lần đầu

Cần Flutter theo `.fvmrc` (khuyên dùng [FVM](https://fvm.app)), Java 17+ cho
Android, CocoaPods cho iOS. Chi tiết: [điều kiện dự án](docs/prerequisites.md).

```bash
git clone --recurse-submodules https://github.com/Peeky2000/bloc_cubit_base.git
cd bloc_cubit_base
dart pub global activate derry
derry bootstrap        # cài dependency, sinh code
derry quality          # phải xanh trước khi làm gì tiếp
derry run dev
```

Clone rồi mà quên submodule:

```bash
git submodule update --init --recursive && derry get && derry gen
```

## Bắt đầu một dự án thật

Không code thẳng trong repo base. Tạo app mới từ nó:

```bash
# Xem trước những gì sẽ đổi
derry new -- --destination ../my_app --display-name "My App" \
  --package-name my_app --bundle-id com.company.my_app

# Đồng ý thì chạy thật
derry new -- --destination ../my_app --display-name "My App" \
  --package-name my_app --bundle-id com.company.my_app --apply
```

App mới có một commit đầu tiên sạch, đã đổi package, bundle id, tên app, và
vẫn giữ `sli_common` là submodule. Sau đó, trong app mới:

| # | Việc | Ở đâu |
|---|---|---|
| 1 | Đổi địa chỉ server | `lib/core/app/app_config.dart` hoặc `--dart-define=API_BASE_URL=...` |
| 2 | Firebase, signing, icon, splash | [Tạo app từ base](docs/guides/create-app-from-base.md), mục 5 |
| 3 | Giữ hay bỏ các màn mẫu (đăng nhập, đăng ký, splash, OTP) | Bỏ đăng nhập thì sửa `integration_test/performance/support/perf_app_adapter.dart` |
| 4 | Làm các việc để dành cho tuần đầu | [Sổ tay dự án thật](docs/guides/start-real-project.md#4-việc-để-dành-tới-dự-án-thật) |

Sổ tay dự án thật là nơi duy nhất ghi việc còn mở. Xong việc nào thì đánh dấu
và ghi link PR ở đó.

## Làm một tính năng

Trong Claude Code:

```text
/tech-design docs/prd/thanh-toan.md
```

1. Agent tra sổ quyết định, viết `docs/specs/<id>-<feature>/tech.md` cùng các
   quyết định mới ở trạng thái đề xuất, rồi **dừng lại**.
2. Bạn đọc `tech.md`, trả lời mục "Câu hỏi nghiệp vụ", đổi
   `Trạng thái: Draft` thành `Trạng thái: Approved`.
3. Gõ `/build-feature docs/specs/<id>-<feature>/tech.md`. Agent dev sinh khung
   bằng `derry scaffold`, viết code theo đúng thứ tự tầng, rồi agent test kiểm
   tra độc lập. Lỗi được trả về cho dev sửa tới khi qua.

Các lệnh `/` khác:

| Lệnh | Việc |
|---|---|
| `/decision <câu hỏi>` | Tra hoặc ghi quyết định kỹ thuật |
| `/perf-check [màn]` | Đo hiệu năng, tìm nguyên nhân, sửa, đo lại, báo cáo |
| `/perf-scenario <AC>` | Viết kịch bản đo và đề xuất ngưỡng từ AC |
| `/security-audit [phạm vi]` | Audit bảo mật mobile |

Không dùng Claude Code? Gọi agent bằng `@.agents/agents/flutter-dev.md <việc>`.
Danh sách agent, skill và câu gọi mẫu: [bộ công cụ AI](docs/guides/ai-toolbox.md).

Tự viết tay cũng được, nhưng sinh khung bằng lệnh để qua test convention:

```bash
derry scaffold -- payment --data --apply          # Cubit, kèm tầng data
derry scaffold -- chat --bloc --apply             # BLoC
```

## Lệnh hằng ngày

| Lệnh | Việc |
|---|---|
| `derry run dev` | Chạy app môi trường dev |
| `derry gen` | Sinh code (DI, model, asset) và format |
| `derry quality` | Format, analyzer, gate kiến trúc, test convention, test app và `sli_common` |
| `derry test` | Chỉ chạy test |
| `derry scaffold -- <feature> [--bloc] [--data] --apply` | Sinh khung feature |
| `derry decision search "<chủ đề>"` | Tìm quyết định đã chốt |
| `derry review plan` | Liệt kê file đổi và luật review cho từng file |
| `derry perf run` / `diagnose` / `approve` | Đo hiệu năng / đo kèm chẩn đoán / lưu làm mốc |

Toàn bộ lệnh: `derry ls -d`. Build local, phân phối Firebase và lên Store là ba
luồng riêng; đọc [Derry và build](docs/guides/use-derry-and-build.md) trước khi
chạy lệnh có tác động ra ngoài.

| Môi trường | Entrypoint | Network inspector |
|---|---|---|
| local | `lib/main_local.dart` | bật |
| dev | `lib/main_dev.dart` | bật |
| staging | `lib/main_staging.dart` | bật |
| prod | `lib/main_prod.dart` | tắt, và bắt buộc HTTPS |

## Kiến trúc

```text
Screen ─▶ Cubit/BLoC ─▶ UseCase ─▶ Repository (interface)
                                         ▲
                     RepositoryImpl ─────┘ ─▶ DataSource ─▶ Dio / SDK

presentation ─▶ domain ◀─ data
```

Năm quy tắc không thoả hiệp, được kiểm tra trong `derry quality`:

1. **Thứ tự tầng:** Entity → Model → DataSource → Repository → UseCase →
   Cubit/BLoC → Screen → Route → l10n → DI.
2. **Domain thuần Dart:** không import Flutter, data, SDK hay DI.
3. **Constructor injection:** chỉ composition root (route builder, `MainApp`,
   `bootstrap`, DI module) mới lấy dependency qua `Injector.getIt.get<T>()`.
4. **Cubit không biết UI:** không `BuildContext`, không điều hướng, không chuỗi
   dịch. Việc một lần đi qua `UiEffect` có kiểu, Screen xử lý.
5. **Không sửa `lib/di/injection.config.dart`:** gắn annotation rồi chạy `derry gen`.

Chi tiết: [kiến trúc](docs/architecture/README.md) ·
[vì sao chọn vậy (ADR)](docs/adr/README.md).

## Cấu trúc thư mục

```text
lib/
  core/            app config, bootstrap, network, observability
  data/            model, data source, repository impl
  domain/          entity, repository interface, use case
  presentation/    screen + Cubit/BLoC theo feature
  widget/          widget riêng của app (dùng sli_common trước)
  di/              Injector và cấu hình get_it
  l10n/            chuỗi dịch ARB
  modules/         sli_common (submodule)
test/              unit, widget, convention, patterns
integration_test/  kịch bản đo hiệu năng
tool/              scaffold, convention, decisions, review, base CLI
docs/              tài liệu (xem mục dưới)
.agents/           agent và skill cho AI
.claude/commands/  lệnh / trong Claude Code
```

## Tài liệu

| Muốn | Đọc |
|---|---|
| Đem base vào dự án thật, việc còn mở | [Sổ tay dự án thật](docs/guides/start-real-project.md) |
| Làm việc với AI | [Bộ công cụ AI](docs/guides/ai-toolbox.md) · [AGENTS.md](AGENTS.md) |
| Thêm feature bằng tay | [Thêm feature](docs/guides/add-feature.md) |
| State, DI, networking, UI | [Kiến trúc](docs/architecture/README.md) |
| Widget | [Dùng sli_common](docs/guides/use-sli-common.md) |
| Đo hiệu năng | [Đo hiệu năng app](docs/guides/measure-performance.md) · [chuẩn và ngưỡng](docs/performance/standards.md) · [PERFORMANCE.md](PERFORMANCE.md) |
| Build, phát hành | [Derry và build](docs/guides/use-derry-and-build.md) |
| Báo lỗi, analytics | [Version Health](docs/guides/enable-version-health.md) |
| Mọi thứ còn lại | [Mục lục tài liệu](docs/README.md) |
