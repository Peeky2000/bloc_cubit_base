# Brainstorm: Bổ sung Version Health và Firebase observability cho Flutter base

**Type:** feature
**Date:** 2026-10-07

---

## Analysis

### 1. Tính năng giải quyết vấn đề gì?

Ảnh đề xuất theo dõi sức khỏe từng app version qua adoption, stability và
performance, rồi dùng Remote Config để can thiệp khi cần. Base hiện chỉ có
`firebase_core` và `firebase_auth`; Version Health được ghi là future scope trong
`docs/architecture/optional-capabilities.md`. Benchmark `dart run perf` là phép
đo profile trên thiết bị theo yêu cầu, không thay thế telemetry từ người dùng
thật và không cung cấp adoption/crash-free.

### 2. Ai hưởng lợi?

Developer và người phụ trách release có dữ liệu để đánh giá phiên bản và quyết
định tiếp tục rollout, dừng, hoặc hotfix. Người dùng hưởng lợi gián tiếp khi
lỗi/hiệu năng xấu được phát hiện sớm. Quyền xem dashboard và ra quyết định
release cần được giao cho owner của sản phẩm sau khi fork base.

### 3. Use case chính là gì?

- **Bắt buộc:** ghi app version/platform/OS/device cùng Analytics; thu crash và
  non-fatal bằng Crashlytics; theo dõi app start/network và trace có chủ đích
  bằng Firebase Performance; cấu hình flag với default an toàn qua Remote
  Config; định nghĩa ngưỡng, owner, cửa sổ quan sát và cách rollback.
- **Bổ sung sau:** dashboard tổng hợp Version Health, cảnh báo và tự động hóa
  quyết định. Không tự động rollout/hotfix khi chưa có chính sách được duyệt.
- **Giới hạn kỹ thuật:** Firebase Performance Flutter không tự đo render của
  từng Flutter screen; cần custom trace hoặc benchmark profile riêng.

### 4. Edge case nào cần xét?

Lần mở đầu chưa có mạng; Remote Config fetch lỗi/throttled; flag chưa được
publish; crash trước khi Firebase khởi tạo; user từ chối consent; app chạy trên
flavor/Firebase project sai; phiên bản mới chưa đủ mẫu để kết luận; cùng version
trên thiết bị/OS khác có kết quả khác nhau. Không gửi PII, token, URL chứa dữ
liệu cá nhân hoặc payload request/response vào event, trace và crash log.

### 5. Ràng buộc là gì?

Giữ `presentation → domain ← data`, constructor injection và bootstrap hiện có.
Mỗi app fork phải cấu hình Firebase Android/iOS và flavor của chính nó. Dự án
đang ghim Flutter 3.44.5, còn máy hiện chỉ có 3.35.3; phải có toolchain đúng
trước khi resolve dependency/verify. Firebase Performance tự thu app start và
HTTP/S request sau khi thêm SDK, nhưng không tự thu per-screen rendering của
Flutter. Dashboard Firebase có thể hiển thị dữ liệu trễ và tỷ lệ mẫu khác nhau;
không nên coi mọi nhóm chỉ số là cùng một cohort.

### 6. Phương án nào được cân nhắc?

1. **Chỉ dùng benchmark local:** rẻ và lặp lại được, nhưng không thấy adoption,
   crash hoặc thiết bị người dùng thật.
2. **Gắn cả bốn SDK vào base và bật mặc định:** thuận tiện nhưng gắn base với
   Firebase project, consent, chi phí vận hành và chính sách sản phẩm.
3. **Khuyến nghị:** giữ benchmark opt-in; xây adapter/cấu hình observability
   tách được để app fork bật theo nhu cầu, rồi triển khai từng nhóm dữ liệu.
   Product owner định nghĩa metric và quyết định rollout.

### 7. Tương tác với tính năng hiện tại thế nào?

`bootstrap.dart` đã gọi `Firebase.initializeApp()` và hiện log Flutter/zone
errors. Crashlytics phải được nối vào các handler này mà vẫn giữ diagnostics
redaction. Analytics screen event có thể nối tại route observer/presentation
boundary. Performance custom trace đặt quanh hành vi cần đo; network trace
phải xét Dio interceptor/redaction hiện có. Remote Config tác động qua typed
feature flag service, không để UI/UseCase gọi Firebase trực tiếp.

### 8. Phụ thuộc vào gì?

Firebase project/app Android/iOS tương ứng từng flavor, quyền console, chính
sách consent/data retention và release owner. Thêm `firebase_analytics`,
`firebase_crashlytics`, `firebase_performance`, `firebase_remote_config`; chạy
`flutterfire configure` theo đúng flavor/project và xác minh native config.
Analytics được khuyến nghị cho Crashlytics breadcrumbs và cần cho Remote Config
targeting theo audience/user properties. Nguồn: [FlutterFire setup](https://firebase.google.com/docs/flutter/setup),
[Analytics](https://firebase.google.com/docs/analytics/flutter/get-started),
[Crashlytics](https://firebase.google.com/docs/crashlytics/flutter/get-started),
[Performance](https://firebase.google.com/docs/perf-mon/flutter/get-started),
[Remote Config](https://firebase.google.com/docs/remote-config/flutter/get-started).

### 9. Rủi ro là gì?

Trộn dữ liệu local benchmark với production telemetry; kết luận từ phiên bản ít
mẫu; PII trong event/log; flag thiếu default làm app lỗi offline; mapping flavor
sai làm bẩn production dashboard. Cần schema event/trace, mẫu tối thiểu và
ngưỡng được duyệt, canary rollout, kill switch có default, và audit quyền
publish Remote Config. Không coi Remote Config là nơi giữ secret.

### 10. Điều kiện nghiệm thu nào xác minh được?

- Mỗi flavor gửi đúng Firebase project; SDK có thể bật/tắt theo policy và app
  vẫn chạy khi offline.
- Dashboard nhận Analytics, Crashlytics và Performance từ bản test; một custom
  trace được đối chiếu với thao tác thật; không xuất hiện PII.
- Crash/non-fatal được ghi đúng handler; symbolication của release build được
  xác minh.
- Remote Config có typed default, fetch/activate, fallback và test khi lỗi;
  flag thử nghiệm tác động đúng một hành vi có thể rollback.
- Version Health có metric definition, cohort, ngưỡng, số mẫu tối thiểu, owner,
  quyết định continue/hotfix và đường rollback bằng văn bản.
- `derry quality`, architecture gate và kiểm tra Android/iOS/flavor liên quan
  đạt; debt cũ được tách khỏi regression mới.

---

## Synthesis

### Key Insight

Ảnh mô tả hệ thống observability và điều hành rollout trên người dùng thật.
Benchmark `dart run perf` vừa thêm là công cụ profile opt-in dành cho developer;
hai nguồn dữ liệu phục vụ mục đích khác nhau. Firebase Performance không tự đo
render từng Flutter screen.

### Recommended Approach

Chốt trước Firebase project/flavor, privacy/consent, owner và định nghĩa metric.
Triển khai Analytics → Crashlytics → Performance custom traces → Remote Config
typed flags, xác minh mỗi phần trên build test. Sau khi có dữ liệu đủ mẫu, tạo
Version Health dashboard và policy continue/hotfix/rollback. Giữ các adapter
observability tùy chọn để base vẫn tái sử dụng được.

### Risks to Watch

- Dữ liệu production bị trộn với dev/staging hoặc bị gắn PII.
- Tự tin quá mức vào screen metric/phiên bản ít mẫu.
- Remote Config thiếu default/fail-safe hoặc quyền publish quá rộng.

### Open Questions

- Mỗi flavor sẽ dùng Firebase project nào, và ai quản lý console?
- Chính sách consent, retention và loại dữ liệu được phép ghi là gì?
- Ngưỡng Version Health, cỡ mẫu tối thiểu, owner và rollback path nào được duyệt?
