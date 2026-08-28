# Quy Trình AI — Flutter Base

Repository này xem tài liệu kiến trúc và các quality gate chạy được như cùng
một hợp đồng. Trước khi plan hoặc implement, hãy đọc
[prerequisites](docs/prerequisites.md), [architecture index](docs/architecture/README.md),
và `project-convention`.

## Luồng bàn giao

```text
Brainstorm / Spec → cổng quyết định của user → implementation plan
→ implementation → review → tests và architecture gates → cập nhật status/docs
```

| Artifact | Đường dẫn |
|---|---|
| Brainstorm | `docs/brainstorm/YYYY-MM-DD-{topic}.md` |
| Frontend spec | `docs/specs/{NNN}-{name}/fe.md` |
| Checklists | `docs/specs/{NNN}-{name}/checklists/` |
| Plan | `docs/plan/YYYY-MM-DD-{topic}.md` |
| Review | `docs/reviews/YYYY-MM-DD-hh-mm-ss-{topic}.md` |
| Architecture decision | `docs/adr/NNNN-{decision}.md` |

Mọi implementation plan phải có đường dẫn chính xác, owner, điều kiện verify
khách quan, rủi ro, phần ngoài phạm vi, và Definition of Done.

## Thứ tự implement feature

```text
Entity → Model → DataSource → Repository interface/impl → UseCase
→ Cubit hoặc BLoC → Screen → Route → ARB → DI code generation → tests/docs
```

Thứ tự này dựa trên dependency, không phải giấy phép để thêm layer không cần
thiết. Thay đổi chỉ liên quan UI thì giữ đúng phạm vi UI.

## Quyết định công nghệ

| Hạng mục | Chuẩn |
|---|---|
| State | Cubit mặc định, hỗ trợ BLoC; `BaseAppState + Equatable + copyWith` |
| DI | `get_it + injectable`, constructor injection |
| HTTP | Dio qua `ApiHandler`; REST mặc định |
| Route | `SLIRouting`, `AppPage` |
| i18n | Flutter gen-l10n và ARB |
| Shared UI | API public `Sli*` của `sli_common`; Shadcn nằm sau facade |
| Environments | `AppEnvironment` có kiểu + `bootstrap()` tập trung |

## Quy tắc implement

1. Tìm trong app-memory và code tương tự trước khi tạo artifact mới.
2. Giữ domain thuần; model và chi tiết transport nằm ở data.
3. Inject dependency qua constructor. Chỉ resolve `getIt` tại nơi compose object
   graph, không resolve trong Cubit, UseCase, repository, hoặc data source.
4. API/data layer trả lỗi có kiểu và không navigate hoặc hiển thị UI.
5. One-shot UI action nằm ở presentation boundary; widget chịu trách nhiệm dịch
   và render message cho user.
6. Thêm hoặc cập nhật test cho hành vi bị thay đổi.
7. Cập nhật architecture, guide, skill, hoặc ADR khi convention thay đổi.

## Quality gates

```bash
derry gen
derry quality
```

Nếu repository còn analyzer debt, thay đổi mới không được tạo compile error
hoặc warning mới. Ghi rõ baseline và debt còn lại; không báo gate sạch nếu thực
tế chưa sạch.

## Fork base

Làm theo [create-app-from-base](docs/guides/create-app-from-base.md). Tối thiểu
phải đổi Dart/native identifiers, URL môi trường, file Firebase, branding,
signing configuration, và feature ví dụ. Giữ architecture gates, docs, và
submodule `sli_common` trừ khi project mới chủ động chọn hướng khác và ghi ADR.
