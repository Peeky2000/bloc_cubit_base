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
| Flutter dev (feature và sửa lỗi) | `@.agents/agents/flutter-dev.md` |
| Flutter tester (kiểm tra độc lập) | `@.agents/agents/flutter-tester.md` |
| Reviewer | `@.agents/agents/reviewer.md` |
| Performance tester | `@.agents/agents/perf-tester.md` |
| Performance engineer | `@.agents/agents/perf-engineer.md` |

`coder` và `flutter-engineer` đã được thay bằng `flutter-dev`. Vòng giao việc
giữa dev và tester nằm trong
[docs/agents/delivery-loop.md](docs/agents/delivery-loop.md).

Toàn bộ lệnh, agent và skill được tổng hợp trong
[docs/guides/ai-toolbox.md](docs/guides/ai-toolbox.md).

Vòng đo và sửa hiệu năng giữa hai agent performance được mô tả trong
[docs/performance/agent-loop.md](docs/performance/agent-loop.md).

Trước khi chọn cách làm, tìm quyết định kỹ thuật đã chốt:

```bash
python3 tool/decisions/decisions.py search "phân trang"
```

Tính năng mới đi qua `tech.md` (skill `tech-design`) và chờ PM duyệt trước khi
code.

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
- Tạo feature mới bằng `dart run tool/scaffold/feature.dart <feature> --apply`
  thay vì tự viết khung. Convention được kiểm tra tự động bởi
  `test/convention/convention_test.dart`; không thêm dòng vào
  `tool/convention/baseline.txt`.
