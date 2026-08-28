# AI Agents — Flutter Base Template

## Bắt đầu

Đọc các nguồn sau theo đúng thứ tự trước khi thay đổi code:

1. [ai-process.md](ai-process.md)
2. [docs/prerequisites.md](docs/prerequisites.md)
3. [architecture rules](docs/architecture/README.md)
4. [.agents/skills/project-convention/SKILL.md](.agents/skills/project-convention/SKILL.md)

## Agents

| Agent | Invoke |
|---|---|
| PM | `@.agents/agents/pm.md` |
| Coder | `@.agents/agents/coder.md` |
| Reviewer | `@.agents/agents/reviewer.md` |
| Quick fix | `@.agents/agents/flutter-engineer.md` |

Tìm artifact đã được index trước khi tạo bản trùng:

```bash
python3 .agents/skills/app-memory/scripts/mem_search.py "auth"
```

## Quy tắc không thoả hiệp

- Thứ tự layer: Entity → Model → DataSource → Repository → UseCase → Cubit/BLoC
  → Screen → Route → l10n → generated DI.
- Chiều dependency: presentation → domain ← data. Domain không phụ thuộc
  Flutter, data, presentation, service locator, hoặc UI.
- Class nhận dependency qua constructor. Chỉ composition root mới resolve từ
  `getIt` (`bootstrap`, route/screen builder, DI module).
- Dùng `@injectable` cho feature Cubit/BLoC, `@lazySingleton` cho service không
  giữ state, và binding interface như `@LazySingleton(as: AuthRepo)`.
- Không sửa `lib/di/injection.config.dart`; chạy `derry gen`.
- Cubit là mặc định. Chỉ chọn BLoC khi named event, event transformer, hoặc
  concurrency semantic mang lại giá trị cụ thể.
- Tái sử dụng `sli_common` trước khi thêm reusable widget trong app. Import API
  ổn định của nó; không rải direct `shadcn_flutter` import khắp app.
- Chạy `derry quality` và báo debt có sẵn tách biệt với regression mới.
