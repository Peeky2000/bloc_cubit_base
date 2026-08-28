# Điều Kiện Dự Án

Cập nhật file này mỗi khi base được fork hoặc package nền tảng thay đổi.

## Toolchain

- Flutter: pin bằng `.fvmrc` (khuyến nghị dùng FVM, không bắt buộc).
- Dart SDK: `^3.10.0`.
- Derry: `dart pub global activate derry`.
- Git submodules: bắt buộc cho `lib/modules/sli_common`.
- Platforms: Android và iOS.

Bootstrap một clone mới bằng `derry bootstrap`.

Kiểm tra template identity/submodule trước khi tạo app bằng
`derry base doctor`. Workflow create/rename luôn dry-run mặc định và được mô tả
tại [hướng dẫn tạo app](guides/create-app-from-base.md).

Danh mục command và ranh giới giữa build local/Firebase/Store nằm tại
[hướng dẫn Derry và build](guides/use-derry-and-build.md).

## Cấu trúc và chiều dependency

```text
lib/presentation/  UI + Cubit/BLoC
        ↓
lib/domain/        entities, repository contracts, use cases
        ↑
lib/data/          models, data sources, repository implementations

lib/core/          application/infrastructure primitives
lib/di/            injectable composition root và generated graph
```

Flow bắt buộc: `Cubit/BLoC → UseCase → Repository → DataSource`.
Xem [quy tắc dependency](architecture/dependency-rules.md).

## Stack

| Hạng mục | Triển khai |
|---|---|
| State | `flutter_bloc`, `BaseCubit`/`BaseBloc`, `BaseAppState`, Equatable |
| DI | `get_it + injectable`, constructor injection, generated config |
| HTTP | Dio, `ApiHandler` / `ApiClient` |
| Models | `json_serializable` + `build_runner` |
| Local settings | `shared_preferences` qua data sources |
| Secrets/tokens | `flutter_secure_storage` qua `TokenProvider` |
| Navigation | `SLIRouting`, `AppPage` |
| Localization | Flutter gen-l10n, `lib/l10n/arb/` |
| Network inspection | Alice có redaction, chỉ ngoài production |
| Shared UI | Git submodule `sli_common`, adapter Shadcn |

Mặc định có chủ ý: không bắt buộc Freezed, không bắt buộc HydratedBloc, không
dùng `go_router`, không Retrofit, và ưu tiên REST thay vì GraphQL. Các phần này
chỉ nên thêm vào sản phẩm thật sau khi đã ghi rõ nhu cầu và boundary dependency.

## Cấu hình runtime

Entrypoint là `lib/main_{local,dev,staging,prod}.dart`. Cấu hình lấy từ
`AppConfig` có kiểu và `--dart-define`, không dùng file `.env` dạng asset.

Giá trị thường dùng:

- `API_BASE_URL`
- `ENABLE_NETWORK_INSPECTOR`

Không commit production credential, API secret, signing key, provisioning
profile, hoặc file môi trường chứa secret.

## Lệnh kiểm tra chất lượng

```bash
derry get
derry gen
derry analyze
derry test
derry quality
```

Boundary kiến trúc còn được kiểm tra bởi `scripts/check_architecture.sh` và CI.

## Quy trình AI

Bắt đầu từ `/AGENTS.md` và `/ai-process.md`. Tìm artifact đã có bằng:

```bash
python3 .agents/skills/app-memory/scripts/mem_search.py "<keyword>"
```
