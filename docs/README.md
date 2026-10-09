# Mục lục tài liệu

Đọc [README gốc](../README.md) trước. Trang này chỉ là bản đồ: mỗi thư mục
làm gì và tài liệu nào trả lời câu hỏi nào.

## Theo việc cần làm

| Tôi muốn | Đọc |
|---|---|
| Cài máy và chạy lần đầu | [Điều kiện dự án](prerequisites.md) → [Derry và build](guides/use-derry-and-build.md) |
| Đem base vào dự án thật | [Sổ tay dự án thật](guides/start-real-project.md) |
| Tạo app mới từ base | [Tạo app từ base](guides/create-app-from-base.md) |
| Thêm tính năng | [Thêm feature](guides/add-feature.md) → [quy tắc dependency](architecture/dependency-rules.md) |
| Làm Cubit/BLoC, state, điều hướng một lần | [Quản lý state](architecture/state-management.md) → [UI effect](guides/handle-ui-effects.md) |
| Thêm hoặc sửa DI | [Dependency injection](architecture/dependency-injection.md) |
| Gọi API, token, refresh 401 | [Networking](architecture/networking.md) |
| Làm widget | [UI toolkit](architecture/ui-toolkit.md) → [dùng sli_common](guides/use-sli-common.md) |
| Thêm môi trường hoặc flavor | [Environment và bootstrap](architecture/environment-bootstrap.md#thêm-một-môi-trường) |
| Build, phân phối Firebase, lên Store | [Derry và build](guides/use-derry-and-build.md) |
| Đo hiệu năng | [Đo hiệu năng app](guides/measure-performance.md) → [chuẩn và ngưỡng](performance/standards.md) → [từ AC tới kịch bản](performance/ac-to-scenario.md) |
| Bật báo lỗi, analytics, feature flag | [Version Health](guides/enable-version-health.md) |
| Làm việc với AI agent | [Bộ công cụ AI](guides/ai-toolbox.md) → [AGENTS.md](../AGENTS.md) → [quy trình AI](../ai-process.md) |
| Biết vì sao chọn công nghệ này | [ADR](adr/README.md) và [sổ quyết định](decisions/README.md) |

## Các thư mục

| Thư mục | Chứa gì | Ai viết |
|---|---|---|
| [`architecture/`](architecture/README.md) | Kiến trúc và convention hiện hành | Cập nhật cùng code |
| [`adr/`](adr/README.md) | Quyết định kiến trúc ảnh hưởng cả base. Đã accepted thì không sửa, chỉ thay bằng ADR mới | PM duyệt |
| [`decisions/`](decisions/README.md) | Quyết định kỹ thuật cấp tính năng (D-NNNN) và [thuật ngữ](decisions/glossary.md). Tra bằng `derry decision search` | Agent đề xuất, PM duyệt |
| [`guides/`](guides/) | Cách làm một việc cụ thể | |
| [`performance/`](performance/) | Chuẩn đo, ngưỡng và vòng agent hiệu năng | |
| [`agents/`](agents/delivery-loop.md) | Vòng giao việc giữa agent dev và agent test | |
| `specs/` | Mỗi tính năng một thư mục `NNN-<tên>/` gồm `tech.md`, checklist | `/tech-design` sinh ra |
| `handoffs/` | Phiếu giao việc giữa dev và tester | Agent |
| `reviews/` | Báo cáo review, audit bảo mật, eval. Tên có ngày giờ | Agent reviewer |
| `brainstorm/`, `plan/` | Phân tích phương án và kế hoạch triển khai khi cần. Tên có ngày | Skill `brainstorm`, `plan-writer` |

Các thư mục `specs/`, `handoffs/`, `brainstorm/`, `plan/` để trống trong base;
dự án thật sẽ lấp dần. Tài liệu lịch sử của đợt hiện đại hoá base đã được dọn,
xem lại trong git history nếu cần.

## Khi hai tài liệu mâu thuẫn

Ưu tiên theo thứ tự: architecture và ADR, rồi quality gate chạy được, rồi
guide, rồi review, cuối cùng là brainstorm. Nếu code khác architecture, xác
định đó là nợ cũ hay tài liệu đã cũ, rồi sửa cả hai trong cùng một thay đổi.

## Quy tắc giữ tài liệu gọn

- Tài liệu mới phải được link từ trang này hoặc từ một index con.
- Một chủ đề chỉ có một nơi là nguồn chính. Khi thay tài liệu, xoá bản cũ và
  sửa link, không để hai bản song song.
- Đổi kiến trúc thì cập nhật architecture, ADR, guide liên quan trong cùng PR.
- Việc còn mở chỉ ghi ở [sổ tay dự án thật](guides/start-real-project.md#5-việc-còn-mở-trong-base).
