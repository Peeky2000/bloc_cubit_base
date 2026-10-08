# Bắt đầu dự án thật từ base

Trang này là sổ tay khi đem base vào một dự án thật: làm gì trước, gọi lệnh gì
theo thứ tự nào, và những việc đã cố ý để dành tới lúc có dự án thật. Danh sách
đầy đủ mọi lệnh nằm ở [bộ công cụ AI](ai-toolbox.md).

## 1. Chuẩn bị một lần

| Việc | Lệnh hoặc nơi làm | Ghi chú |
|---|---|---|
| Tạo app từ base | `derry create -- --destination ../my_app --display-name "My App" --package-name my_app --bundle-id com.company.my_app` | Chạy không có `--apply` để xem trước. Xem [tạo app từ base](create-app-from-base.md) |
| Cài dependency và sinh code | `derry bootstrap` | |
| Kiểm tra máy | `derry base doctor`, `derry quality` | Phải xanh trước khi làm gì tiếp |
| Đổi địa chỉ server | `lib/core/app/app_config.dart` hoặc `--dart-define=API_BASE_URL=...` | Địa chỉ mẫu `api.dev.example.com` không chạy được |
| Firebase, signing, icon, splash | Theo mục 5 của [tạo app từ base](create-app-from-base.md) | CLI không tự làm phần này |
| Quyết định giữ hay bỏ màn mẫu | Đăng nhập, đăng ký, splash, quên mật khẩu, xác nhận OTP, màn test | Bỏ luồng đăng nhập thì sửa `integration_test/performance/support/perf_app_adapter.dart` |

## 2. Làm một tính năng

Mỗi tính năng đi đúng thứ tự này. Gõ trong Claude Code:

```text
/tech-design <đường dẫn tài liệu nghiệp vụ hoặc dán AC>
```

1. Agent tra sổ quyết định, viết `docs/specs/<id>-<feature>/tech.md` và các
   quyết định mới ở trạng thái đề xuất, rồi dừng.
2. Bạn đọc `tech.md`, trả lời mục "Câu hỏi nghiệp vụ", chỉnh nếu cần, rồi đổi
   `Trạng thái: Draft` thành `Approved`.
3. Gõ tiếp:

   ```text
   /build-feature docs/specs/<id>-<feature>/tech.md
   ```

   Agent dev scaffold, code, chạy `derry quality`. Agent test viết test nghiệm
   thu từ AC, kiểm tra convention, bảo mật, hiệu năng khi cần, rồi trả báo
   cáo tiếng Việt.
4. Đọc báo cáo, duyệt các quyết định đề xuất, rồi bảo agent đẩy nhánh và mở PR.

Làm thủ công thì thay bước 3 bằng:

```bash
derry scaffold -- <feature> [--bloc] [--data=<domain>] --apply
derry gen
derry quality
```

## 3. Việc định kỳ

| Khi nào | Gõ |
|---|---|
| Trước mỗi lần phát hành | `/security-audit` và `kiểm tra release readiness cho bản prod Android và iOS` |
| Sau khi sửa phần nặng về hiệu năng | `/perf-check <màn hoặc luồng>` |
| Review nhánh trước khi merge | `@.agents/agents/reviewer.md review nhánh <tên nhánh> so với main` |
| Hỏi đã quyết thế nào | `/decision <chủ đề>` hoặc `derry decision search "<chủ đề>"` |
| Ghi một quyết định mới | `/decision ghi quyết định: <nội dung>` |
| Thêm thuật ngữ nghiệp vụ mới | Sửa [docs/decisions/glossary.md](../decisions/glossary.md) |

## 4. Việc để dành tới dự án thật

Những việc này cố ý chưa làm trong base vì cần tài liệu, server hoặc thiết bị
thật. Làm chúng ở tuần đầu của dự án thật, rồi đánh dấu ở đây.

- [ ] **Chạy thử vòng agent dev và agent test với tài liệu thật.** Đây là bước
  T7 trong [plan agent](../plan/2026-10-07-flutter-dev-and-test-agents.md).
  Chọn một tính năng nhỏ, chạy `/tech-design` rồi `/build-feature`. Ghi lại
  chỗ agent làm tốt, chỗ sai, và sửa hướng dẫn trong `.agents/agents/` hoặc
  `.agents/skills/tech-design/` cho khớp.
- [ ] **Đo hiệu năng lần đầu trên máy thật.** Cần đủ bốn điều kiện:
  - ổ đĩa trống ít nhất 10 GB để build Android;
  - một điện thoại Android tầm trung hoặc iPhone cắm vào và mở khoá;
  - một tài khoản test riêng, khai báo `PERF_USERNAME` và `PERF_PASSWORD`;
  - địa chỉ server thật.

  Sau đó chạy `/perf-check`, duyệt mốc bằng `derry perf approve`. Chi tiết ở
  [đo hiệu năng app](measure-performance.md).
- [ ] **Build Android đầy đủ lần đầu** sau đợt nâng Gradle, AGP, Kotlin và
  minSdk 24. Thử đăng nhập có và không có ghi nhớ, gửi OTP, đăng xuất, hết
  phiên trên máy thật.

## 5. Việc còn mở trong base

Không chặn dự án thật nhưng nên xử lý khi có thời gian.

- [ ] **Hai golden test của `sli_common` fail trên CI Linux** (catalog-pilot
  light và dark, lệch khoảng 1,3%). Cần tạo lại ảnh golden trên Linux trong
  repo `sli_common`. Đây là lý do CI của mọi PR đang đỏ.
- [ ] **Review kiến trúc mục 4:** bỏ lớp `Injector`, truyền dependency qua
  constructor cho `AppColor` và `NoInternetScreen`. Chưa duyệt.
- [ ] **Review kiến trúc mục 5:** gộp use case chỉ chuyển tiếp. Trái với thứ tự
  tầng template đang dạy, chỉ ghi nhận. Xem
  [báo cáo review](../reviews/2026-10-08-09-00-00-matt-code-review-and-architecture.md).
- [ ] **Dọn danh sách ngoại lệ convention** trong
  `tool/convention/baseline.txt`: viết test cho Cubit `reset_password`,
  `sign_up`, `splash`, `test`, và chuyển `presentation/success` vào `view/`.
- [ ] **Lệnh tạo base mới.** Chưa chọn hướng: tạo app mới sạch từ base (bỏ màn
  mẫu, bỏ lịch sử git) hay tạo một base khác hẳn. `derry create` hiện có giữ
  nguyên màn mẫu và lịch sử git.
- [ ] **Migrate 9 widget trùng giữa app và `sli_common`** theo family: dialog,
  form/input, button/action, display. Xem
  [widget family matrix](../plan/2026-10-01-widget-family-migration-matrix.md).
- [ ] **Gỡ branding mẫu** còn sót: `DeliveryGo`, chữ `Giao Hàng 247` trong l10n,
  icon, splash, Firebase client config và endpoint. Làm cùng lúc với bước đổi
  identity ở mục 1 khi tạo app thật.
- [ ] **Chạy eval cho các skill** trên task thật để chỉnh mô tả và cách kích
  hoạt. Có thể gộp với lần chạy thử vòng agent ở mục 4.
- [ ] **Version Health** (Analytics, Crashlytics, Firebase Performance, Remote
  Config) để theo dõi app trên máy người dùng. Kế hoạch ở
  [brainstorm](../brainstorm/2026-10-06-version-health-firebase-observability.md).
- [ ] **Thêm mẫu kỹ thuật vào kho skill** khi dự án cần: phân trang, form và
  validate, cache offline, upload ảnh, realtime, deep link, push notification,
  quyền hệ thống. Mỗi mẫu đi kèm code tham khảo có test và một quyết định trong
  sổ.

Khi xong một mục, đánh dấu `[x]` và ghi ngày hoặc link PR bên cạnh.
