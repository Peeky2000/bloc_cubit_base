# Brainstorm: Hệ skill Flutter và Mobile Engineering

**Type:** architecture
**Date:** 2026-09-28

---

## Analysis

### 1. Chúng ta đang giải quyết vấn đề gì?

Hệ skill hiện tại làm tốt việc hướng dẫn agent tạo từng layer của
`bloc_cubit_base`, nhưng mục tiêu mới rộng hơn: agent phải hành xử như một
Flutter/Mobile Engineer giàu kinh nghiệm trong cả vòng đời sản phẩm, không chỉ
sinh code theo template.

Hệ skill cần phục vụ hai phạm vi:

1. **Flutter engineering nói chung:** convention, architecture, state,
   dependency injection, data, navigation, localization, testing và UI reuse.
2. **Mobile engineering chuyên sâu:** performance, lifecycle, memory, network
   resilience, security/privacy, accessibility, source-code review và release
   readiness.

Đây không phải hướng tích hợp VIPER hoặc dựng một AI framework. Skill chỉ là
playbook kỹ thuật giúp phân tích, triển khai và review mobile code nhất quán.

### 2. Những ràng buộc là gì?

**Ràng buộc cứng:**

- Clean Architecture và dependency direction hiện tại phải được giữ.
- Cubit là mặc định, BLoC dùng khi event/concurrency có giá trị rõ ràng.
- `BaseAppState + Equatable + copyWith` vẫn là convention của base.
- `sli_common` là UI toolkit ưu tiên; Shadcn phải nằm sau stable facade.
- Skill phải dùng được trong chính repo này nhưng không được viết cứng đến mức
  vô dụng với một Flutter project khác.
- Mọi kết luận review/performance phải dựa trên code, test hoặc số đo; không
  phán đoán chung chung.
- Skill không được tự mở rộng phạm vi thay đổi hoặc che giấu technical debt có
  sẵn.

**Ràng buộc mềm:**

- Ưu tiên tài liệu tiếng Việt, còn tên API, thuật ngữ và code dùng chuẩn kỹ
  thuật tiếng Anh.
- Có thể thêm công cụ profiling hoặc static gate sau, nhưng không bắt mọi app
  phụ thuộc một bộ tooling nặng.
- Các skill nên nhỏ vừa đủ để trigger chính xác, nhưng không phân mảnh thành
  hàng chục file trùng nội dung.

### 3. Thuộc tính chất lượng nào quan trọng nhất?

Thứ tự ưu tiên:

1. **Tính đúng đắn và an toàn:** review phải phát hiện lỗi lifecycle, race,
   security và boundary chứ không chỉ style.
2. **Khả năng bảo trì:** convention và quyết định phải nhất quán, dễ thay đổi.
3. **Khả năng kiểm thử:** mỗi khuyến nghị phải có cách verify tương ứng.
4. **Khả năng onboarding:** người mới và agent khác biết chọn đúng skill và
   hiểu đầu ra mong đợi.
5. **Hiệu năng:** phải đo trước/sau và dùng đúng công cụ Flutter/mobile.
6. **Tính đơn giản:** tránh một framework AI hoặc quy trình quá nặng cho base.

Không tối ưu “số lượng skill”. Chất lượng workflow và độ chính xác của trigger
quan trọng hơn việc có thật nhiều tên skill.

### 4. Những hướng thiết kế có thể chọn

#### Phương án A — Một skill Flutter tổng hợp

Một `flutter-engineer` skill chứa convention, implementation, review,
performance và release.

#### Phương án B — Nhiều micro-skill độc lập

Mỗi chủ đề có một skill nhỏ: widget, rebuild, memory, image, startup, network,
security, review, test, release và platform lifecycle.

#### Phương án C — Hệ skill phân tầng

Giữ `project-convention` làm nguồn quy tắc nền; các skill layer hiện tại hướng
dẫn implementation; bổ sung một nhóm skill workflow/quality chuyên sâu:

- `flutter-code-review`
- `flutter-performance`
- `flutter-testing`
- `mobile-security-privacy`
- `mobile-platform-lifecycle`
- `mobile-release-readiness`

Accessibility có thể nằm trong `flutter-atomic-design` trước; chỉ tách thành
skill riêng nếu phạm vi kiểm tra thực tế đủ lớn.

### 5. Trade-off của từng phương án

#### Phương án A

- Dễ tìm và dễ gọi.
- File nhanh chóng quá lớn, phải đọc nhiều nội dung không liên quan.
- Review và performance dễ trở thành checklist nông vì một skill ôm quá nhiều
  trách nhiệm.

#### Phương án B

- Trigger rất chính xác và mỗi skill dễ tối ưu riêng.
- Tạo nhiều nội dung trùng lặp, khó biết nên gọi skill nào và khó giữ convention
  nhất quán.
- Chi phí bảo trì cao hơn giá trị mang lại cho một base cá nhân.

#### Phương án C

- Cân bằng giữa nguồn quy tắc chung và chuyên môn sâu.
- Cho phép kết hợp `project-convention + flutter-code-review` hoặc
  `project-convention + flutter-performance` theo đúng task.
- Đòi hỏi mô tả trigger và ranh giới ownership rõ ràng để tránh hai skill đưa ra
  hướng dẫn mâu thuẫn.

Phương án C phù hợp nhất.

### 6. Các điểm tích hợp

- `AGENTS.md` điều hướng task tổng quát và bắt đọc `project-convention` khi sửa
  hoặc review code.
- `project-convention` sở hữu các invariant của repo: layer, naming, DI,
  Cubit/BLoC, UI ownership và anti-pattern.
- Các skill Flutter layer hiện tại sở hữu cách triển khai entity/model/data/
  repository/state/router/l10n/UI.
- `app-memory` kiểm tra artifact đã tồn tại trước khi tạo mới.
- Nhóm skill quality mới sở hữu workflow kiểm tra và bằng chứng:
  - review source code;
  - performance profiling;
  - test strategy;
  - security/privacy;
  - lifecycle/platform integration;
  - release readiness.
- `sli_common` và catalog là nguồn tra cứu component cho UI implementation và
  UI review.
- Derry/CI là nơi chạy verification, không đặt logic orchestration trong skill.

### 7. Dòng dữ liệu qua hệ thống

```text
Yêu cầu của người dùng
  → phân loại task
  → project-convention
  → app-memory nếu tạo/sửa artifact
  → skill implementation hoặc quality chuyên biệt
  → inspect code / profiler / test / native config
  → finding hoặc thay đổi có đường dẫn và mức độ ưu tiên
  → focused verification
  → derry quality
  → tài liệu/review evidence khi thay đổi kiến trúc
```

Với code review, đầu ra chính là finding có bằng chứng, mức độ ảnh hưởng và vị
trí chính xác. Với performance, đầu vào bắt buộc là measurement hoặc profiling;
đầu ra phải có baseline, bottleneck, target và kết quả trước/sau. Với
implementation, đầu ra là code đúng convention cùng test tương ứng.

### 8. Hệ skill sẽ được kiểm thử thế nào?

- Kiểm tra trigger bằng các prompt đại diện và prompt gần nghĩa để tránh gọi
  sai skill.
- Mỗi skill có scenario tối thiểu cho happy path, legacy code, false positive
  và task ngoài phạm vi.
- `flutter-code-review` được thử trên code có chủ đích chứa boundary violation,
  race, resource leak và UI/state coupling; finding phải ưu tiên lỗi hành vi hơn
  style.
- `flutter-performance` phải từ chối kết luận bottleneck khi chưa có số đo và
  hướng người dùng tới DevTools/profile mode phù hợp.
- `flutter-testing` phải chọn đúng cấp test, không biến mọi thứ thành widget/E2E
  test.
- Security, lifecycle và release skill cần fixture cho secret leak, token race,
  subscription không dispose, background transition và signing/config sai.
- Sau khi ổn định mới dùng eval của `skill-creator` để đo trigger accuracy và
  chất lượng đầu ra.

### 9. Những rủi ro chính

- **Checklist theater:** skill liệt kê rất nhiều mục nhưng không kiểm tra code
  hoặc không đưa bằng chứng.
- **Trùng ownership:** `project-convention`, code review và performance cùng lặp
  quy tắc, rồi drift theo thời gian.
- **Tối ưu cảm tính:** khuyến nghị `const`, cache hoặc isolate mà không đo tác
  động thực tế.
- **Quá phụ thuộc base:** skill chỉ hoạt động với cấu trúc thư mục hiện tại,
  không dùng được khi review Flutter package/app khác.
- **Scope creep:** biến hệ skill thành quy trình AI/VIPER mới thay vì công cụ hỗ
  trợ mobile engineering.

Worst case là agent tạo cảm giác review rất kỹ nhưng bỏ sót lỗi race, token,
lifecycle hoặc regression thực tế. Vì vậy mọi skill quality phải yêu cầu bằng
chứng và nêu rõ phần chưa kiểm chứng.

### 10. Lộ trình chuyển đổi

Thực hiện tăng dần, không big-bang:

1. Audit skill hiện tại, lập ma trận `skill → ownership → trigger → output`.
2. Giữ các skill layer tốt; loại nội dung trùng và sửa mô tả trigger.
3. Xây `flutter-code-review` trước vì mang lại giá trị trên mọi thay đổi.
4. Xây `flutter-performance` với workflow đo bằng DevTools/profile mode.
5. Bổ sung `flutter-testing`, sau đó mới đến security/privacy,
   platform-lifecycle và release-readiness.
6. Chạy eval, thử trên code thật và cập nhật tài liệu mục lục skill.
7. Chỉ tách thêm skill nếu có use case lặp lại và ownership riêng rõ ràng.

Rollback đơn giản: mỗi skill là artifact độc lập; skill mới chưa đạt chất lượng
có thể bỏ khỏi routing mà không ảnh hưởng runtime Flutter app.

---

## Synthesis

### Key Insight

Skill cần mô hình hóa cách một senior Flutter/Mobile Engineer **suy nghĩ, đo,
review và xác minh**, không chỉ mô tả cách sinh từng file. Phần Flutter
convention hiện có là nền tốt; khoảng trống lớn nhất là các workflow chất lượng
cross-cutting như source review, performance, testing, lifecycle, security và
release.

### Recommended Approach

Chọn hệ skill phân tầng. Giữ `project-convention` làm nguồn invariant, giữ các
skill layer hiện có cho implementation, rồi bổ sung nhóm quality workflow theo
thứ tự: `flutter-code-review` → `flutter-performance` → `flutter-testing` →
security/lifecycle/release. Mọi skill mới phải evidence-first, có ranh giới
ownership, cách verify và eval trigger rõ ràng.

### Risks to Watch

- Skill biến thành checklist hình thức, không có bằng chứng.
- Quy tắc bị copy sang nhiều skill và drift.
- Performance optimization được đề xuất khi chưa đo.
- Skill quá gắn với `bloc_cubit_base`, không còn giá trị Flutter/mobile chung.

### Open Questions

- Code-review skill nên chỉ báo finding hay hỗ trợ luôn chế độ tự sửa sau khi
  người dùng yêu cầu?
- Performance baseline mặc định cần bao gồm những budget nào: startup, frame,
  memory, network payload và app size?
- Có cần tách accessibility thành skill riêng ngay, hay tiếp tục để trong
  `flutter-atomic-design` đến khi catalog trưởng thành hơn?
