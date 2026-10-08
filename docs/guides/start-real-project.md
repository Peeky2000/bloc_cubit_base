# Bắt đầu dự án thật từ base

Trang này là sổ tay khi đem base vào một dự án thật: làm gì trước, gọi lệnh gì
theo thứ tự nào, và những việc đã cố ý để dành tới lúc có dự án thật. Danh sách
đầy đủ mọi lệnh nằm ở [bộ công cụ AI](ai-toolbox.md).

## 1. Chuẩn bị một lần

| Việc | Lệnh hoặc nơi làm | Ghi chú |
|---|---|---|
| Tạo app từ base | `derry new -- --destination ../my_app --display-name "My App" --package-name my_app --bundle-id com.company.my_app` | Chạy không có `--apply` để xem trước. App mới có một commit đầu tiên. Xem [tạo app từ base](create-app-from-base.md) |
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

- [x] **Hai golden test của `sli_common` fail trên CI Linux.** Đã thêm bộ so
  sánh chấp nhận lệch tối đa 2% do khác cách khử răng cưa giữa macOS và
  Linux; thay đổi thật vẫn bị bắt. `sli_common` PR #1, 2026-10-08.
- [x] **Review kiến trúc mục 4:** PM quyết định **giữ** `Injector` làm điểm
  truy cập DI tại composition root (ADR-0011). Chỉ sửa `AppColor` và
  `NoInternetScreen` để không tự tra dependency. 2026-10-08.
- [ ] **Review kiến trúc mục 5:** gộp use case chỉ chuyển tiếp. Cố ý không làm
  vì trái với thứ tự tầng template đang dạy. Xem
  [báo cáo review](../reviews/2026-10-08-09-00-00-matt-code-review-and-architecture.md).
- [x] **Dọn danh sách ngoại lệ convention.** `tool/convention/baseline.txt` đã
  trống: thêm 42 test cho Cubit `reset_password`, `sign_up`, `splash`; xoá màn
  `test` không dùng; `SuccessScreen` chuyển vào `lib/widget/`. 2026-10-08.
- [x] **Lệnh tạo app mới.** `derry new -- --destination ../my_app ...` tạo app
  với một commit đầu tiên, giữ `sli_common` là submodule. Xem
  [tạo app từ base](create-app-from-base.md). 2026-10-08.
- [x] **Migrate widget trùng với `sli_common`.** Sáu widget giống hệt chuyển
  sang `sli_common`, hai widget không còn ai dùng đã xoá, `InkWellButton` khác
  layout nên giữ thành `AppInkWellButton`. Xem
  [widget family matrix](../plan/2026-10-01-widget-family-migration-matrix.md). 2026-10-08.
- [x] **Gỡ branding mẫu trong code.** `DeliveryGoButton` thành
  `AppPrimaryButton`, chữ hiển thị trung tính, log route không còn tên mẫu.
  Bundle id, tên app native và file Firebase cố ý giữ lại vì `derry new` hoặc
  `derry rename` đổi theo từng app; icon, splash và endpoint đổi khi tạo app
  thật. 2026-10-08.
- [x] **Eval định tuyến skill.** 90 câu hỏi, đúng tăng từ 93,8% lên 99,5%.
  Xem [báo cáo eval](../reviews/2026-10-08-skill-routing-eval.md). Eval trên
  task thật vẫn nên làm cùng lần chạy thử vòng agent ở mục 4. 2026-10-08.
- [x] **Version Health, phần khung.** Có sẵn giao diện báo lỗi, analytics, đo
  hiệu năng, feature flag, mặc định tắt. Bật Firebase theo
  [hướng dẫn](enable-version-health.md) khi có dự án thật. 2026-10-08.
- [x] **Mẫu kỹ thuật trong kho skill.** Phân trang, form và validate, cache
  offline, upload ảnh, realtime, deep link, push notification, quyền hệ thống:
  skill `flutter-patterns`, code mẫu có test trong `test/patterns/`, quyết
  định D-0001 đến D-0008 đang chờ duyệt. 2026-10-08.
- [ ] **Duyệt các quyết định D-0001 đến D-0008** trong
  [sổ quyết định](../decisions/README.md): đổi trạng thái sang `accepted` hoặc
  chỉnh nội dung. Các mẫu dùng plugin (push, deep link, quyền, chọn ảnh) mới
  chỉ chốt hình dạng cổng và tên plugin đề xuất.
- [ ] **Bật Version Health với Firebase thật** khi dự án có Firebase project
  cho từng flavor.

Khi xong một mục, đánh dấu `[x]` và ghi ngày hoặc link PR bên cạnh.
