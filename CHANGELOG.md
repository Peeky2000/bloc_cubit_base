# Changelog

## Unreleased

- Thêm bootstrap đa môi trường có kiểu rõ ràng và validation.
- Chuyển dependency injection sang `get_it + injectable` với constructor
  injection và cấu hình sinh mã.
- Thêm convention state: Cubit mặc định, vẫn hỗ trợ BLoC.
- Gia cố network inspection, session refresh, redaction, và token storage.
- Thay cây `sli_common` nhúng bằng Git submodule thật và thêm nền tảng toolkit
  ổn định có facade Shadcn.
- Thêm automation FVM/Derry/CI, architecture gates, tests, ADRs, guides, và
  đồng bộ hướng dẫn AI agent.
- Phân tách Derry thành build local, Firebase distribution và Store release;
  chuẩn hóa lại `build.sh` với dry-run, Store confirmation và Git tag opt-in.
- Thêm Dart Base CLI phía sau Derry cho `doctor/create/rename`, dry-run mặc
  định, validation trước mutation và test cho plan/apply guard.
- Thêm catalog `sli_common` với inventory 45/45 export, maturity status,
  showroom, BottomSheet pilot và golden preview có thể tái tạo.
- Gia cố session refresh: single-flight concurrent 401, token revision guard,
  cross-origin bearer protection, safe replay và coalesced terminal expiry.
- Thêm test network/session/token cho terminal và transient refresh failure,
  account race, multipart replay, retry 401/500, 403 và offline contract; full
  application suite hiện có 44 tests.
- Thêm typed session-expired flow từ data coordinator → AppCubit →
  `BlocListener`, cùng lifecycle-safe `NetworkChecker` có monitor seam và
  generated singleton disposal.
- Ghi future scope Version Health gồm Analytics, Crashlytics, Firebase
  Performance và Remote Config; không đưa VIPER vào base architecture.
