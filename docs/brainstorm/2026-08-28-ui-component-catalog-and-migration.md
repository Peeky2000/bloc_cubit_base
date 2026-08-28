# Brainstorm: Component catalog và chiến lược đồng bộ UI toolkit

**Type:** architecture
**Date:** 2026-08-28

---

## Phân tích

### 1. Vấn đề cần giải quyết là gì?

Vấn đề trước mắt không phải chọn widget nào để migrate, mà là khả năng khám phá
và đánh giá công cụ UI đang quá thấp. Developer biết `sli_common` “có
BottomSheet” nhưng không biết:

- public class/function chính xác là gì;
- component stable, legacy, deprecated hay experimental;
- hình dạng và variants ra sao;
- khi nào nên dùng và khi nào không nên dùng;
- constructor/API quan trọng gồm những gì;
- có hỗ trợ loading, disabled, safe area, keyboard, accessibility và theme hay
  không;
- source, demo, test và migration replacement nằm ở đâu;
- phiên bản trong app, `sli_common`, V2/`commons` và design system khác nhau thế
  nào.

Không giải quyết discoverability trước thì migration dễ biến thành copy theo tên
file, không đảm bảo behavior parity và tiếp tục tạo drift.

### 2. Các ràng buộc là gì?

Ràng buộc cứng:

- `sli_common` là repository độc lập và được base pin bằng Git submodule.
- App chỉ consume public barrel `package:sli_common/sli_common.dart`; API mới ổn
  định dùng prefix `Sli*`.
- Shadcn chỉ là implementation detail phía sau facade.
- Widget product-specific vẫn nằm trong app; không đưa Cubit, route, branding
  hay business copy vào shared package.
- Không migrate hàng loạt trước khi có behavior matrix và test parity.
- Shared change phải verify riêng trong repo `sli_common`, commit/push trước rồi
  mới cập nhật submodule pointer ở base.

Ràng buộc mềm:

- README cần đủ nhanh để người mới tìm công cụ bằng mắt.
- Example app nên nhẹ và không ép thêm framework catalog ngay từ đầu.
- Ảnh preview phải có cách tái tạo để tránh drift khỏi code.
- Catalog phải hữu ích cho cả con người lẫn AI agent.

### 3. Quality attributes nào quan trọng nhất?

Thứ tự ưu tiên:

1. **Discoverability:** tìm theo nhu cầu như bottom sheet, dialog, input hoặc
   loading và thấy ngay tên API/preview.
2. **Correctness/trust:** tài liệu, ảnh và code demo phải khớp component thật.
3. **Maintainability:** thêm component không phải sửa nhiều danh sách rời rạc.
4. **Simplicity/onboarding:** người mới không cần đọc source để biết cách dùng.
5. **Testability/accessibility:** component stable có test cho behavior, theme và
   semantics.

Performance runtime không phải concern chính của catalog, nhưng example và
golden generation không được kéo dependency không cần thiết vào app consumer.

### 4. Những phương án kiến trúc nào có thể dùng?

#### Phương án A — Chỉ mở rộng README tĩnh

Một bảng lớn gồm ảnh, tên class và code snippet ngay trong README.

#### Phương án B — README index + per-component docs + interactive example

README là gallery/tìm kiếm nhanh. Mỗi component có tài liệu chi tiết; example
app là showroom chạy được với category, variants và states. Ảnh README lấy từ
golden/screenshot của chính example hoặc widget test.

#### Phương án C — Dùng framework catalog kiểu Widgetbook ngay

Đưa component stories, knobs/controls, themes và device frames vào một công cụ
chuyên dụng.

#### Phương án D — Catalog manifest/code generation ngay từ đầu

Dùng YAML/JSON/registry làm source of truth, sinh README/index và validate mọi
public export tự động.

### 5. Trade-off của từng phương án là gì?

| Phương án | Điểm mạnh | Điểm yếu |
|---|---|---|
| A. README tĩnh | Nhanh, ít dependency, xem tốt trên GitHub | Dễ drift, file rất dài, không thử interaction/variants được |
| B. README + docs + example | Cân bằng giữa discoverability, demo thật và chi phí; không khóa vào tool ngoài | Cần kỷ luật registry/docs/golden; phải xây navigation showroom nhỏ |
| C. Framework catalog | Controls, viewport, theme, story organization mạnh | Thêm dependency/workflow, migration và maintenance riêng; quá nặng khi stable surface hiện mới có ít component |
| D. Manifest/codegen | Một source of truth, phù hợp automation/AI | Chi phí thiết kế generator cao; metadata dễ trở thành hệ thống thứ hai trước khi contract component ổn định |

Khuyến nghị bắt đầu bằng B. Chỉ nâng lên C khi số component stable và nhu cầu
interactive controls đủ lớn. D có thể thêm sau dưới dạng validator/generator nhỏ
khi schema catalog đã ổn qua vài component family.

### 6. Các điểm tích hợp là gì?

```text
sli_common/lib/sli_common.dart       public API được catalog
sli_common/docs/catalog/             tài liệu theo component family
sli_common/example/                  showroom tương tác
sli_common/test/                     behavior, semantics và golden tests
sli_common/docs/assets/components/   ảnh preview có thể tái tạo
sli_common/README.md                 quick gallery + link chi tiết
bloc_cubit_base/docs/guides/         quy tắc consume/migrate
bloc_cubit_base/.agents/memories/    index để AI tìm trước khi tạo widget
```

Nguồn tham khảo ngoài package:

- `bloc_cubit_base/lib/core/widget` và `lib/widget`: behavior/caller hiện tại.
- `/Users/long/Documents/Work/commons/packages/base_ui`: ý tưởng/API tham khảo
  từ enterprise shared package, không phải source để copy nguyên khối.
- `base_flutter_project_v2/design-system-mobile`: spec/tokens/variants từ Figma,
  không phải Flutter implementation.

### 7. Dữ liệu chảy qua hệ thống như thế nào?

```text
Inventory các nguồn
  ↓
Behavior/ownership matrix
  ↓
Quyết định keep app | adopt legacy | thiết kế Sli* | reject
  ↓
Stable Sli* contract + story/example
  ↓
Widget/semantics/golden tests
  ↓
Ảnh preview + README/catalog entry
  ↓
Compatibility adapter + @Deprecated
  ↓
Migrate caller app theo từng component family
```

Code và test là nguồn hành vi. Catalog mô tả public contract và dẫn tới source;
ảnh chỉ là preview, không phải bằng chứng duy nhất về correctness.

### 8. Kiểm thử như thế nào?

Mỗi component được đánh dấu stable cần tối thiểu:

- widget test cho interaction và các state quan trọng;
- semantics/accessibility test cho control tương tác;
- light/dark theme coverage;
- golden cho variants/sizes/state matrix phù hợp;
- example story compile và render được;
- link/source/export trong catalog tồn tại;
- migration adapter có parity test trước khi app bỏ bản local.

Catalog nên có một validation gate kiểm tra mọi stable public `Sli*` component
đều có registry entry, docs, story và test. Legacy export có thể thiếu nhưng phải
được gắn trạng thái rõ ràng thay vì giả vờ stable.

### 9. Rủi ro là gì?

- Copy `commons/base_ui` có thể kéo theo Freezed/BLoC/DI/domain contracts,
  product theme/assets và behavior không phù hợp base cá nhân.
- Design system V2 là TTN-specific, có nhiều component DRAFT; dùng số đo Figma
  như requirement tuyệt đối có thể khóa `sli_common` vào một sản phẩm.
- Ảnh README chụp tay sẽ nhanh lỗi thời.
- Public barrel hiện export cả stable `Sli*` lẫn 39 legacy modules; nếu catalog
  không gắn maturity status, người dùng vẫn chọn nhầm API.
- Một giant README chứa mọi constructor option sẽ khó đọc và khó maintain.
- Dùng framework/catalog generator quá sớm sẽ tốn công hơn giá trị thực tế.

### 10. Migration path là gì?

#### Phase A — Inventory, chưa migrate

- Lập danh mục public exports, callers, screenshots, tests và ownership của cả
  bốn nguồn.
- Tạo matrix: `keep app`, `legacy shared`, `candidate Sli*`, `reference only`,
  `deprecated/reject`.

#### Phase B — Catalog skeleton và BottomSheet pilot

- Tạo README gallery theo category và maturity status.
- Tạo per-component template và showroom navigation.
- Dùng BottomSheet làm pilot vì nó thể hiện đủ vấn đề container vs presenter,
  keyboard/safe area, header/actions, scroll và dismissal.

#### Phase C — Stable component families

- Ưu tiên foundation, button, surface, feedback/overlay, input/form.
- Mỗi family hoàn tất contract, stories, tests và preview trước khi mở rộng.

#### Phase D — Adapter/deprecation

- Viết adapter giữ behavior app hiện tại.
- Thêm `@Deprecated` kèm replacement và changelog.
- Migrate caller theo family; rollback bằng cách giữ adapter trong ít nhất một
  chu kỳ version.

#### Phase E — Học có chọn lọc từ V2/commons/design system

- Chỉ lấy anatomy, variants, tokens hoặc behavior đã chứng minh hữu ích.
- Không bê dependency architecture hay branding của TTN vào toolkit cá nhân.

## Baseline quan sát được

- App hiện có 12 file trong `lib/core/widget` và 7 file trong `lib/widget`.
- Có 11 filename trùng giữa `lib/core/widget` và `sli_common`; cả 11 hiện khác
  nội dung, chứng minh drift đã xảy ra.
- Public barrel `sli_common` có 45 export: 6 foundation/stable modules và 39
  legacy modules.
- `sli_common` có 30 ảnh/GIF legacy, README hiển thị 29 hàng gallery, nhưng
  không có BottomSheet và chưa có usage theo component.
- Example app chỉ demo `SliSurface` và các variant `SliButton`.
- `sli_common` hiện có test cho button/theme, chưa có catalog/golden cho legacy
  surface.
- `/Work/commons/packages/base_ui` có 101 public exports và khoảng 105 source
  Dart files, nhưng README vẫn là template TODO và không có package test được
  tìm thấy.
- Snapshot `commons` đang pin trong V2 (`a030b90`) khác working repo
  `/Work/commons` (`ffb9526`); so sánh tree `base_ui` có 26 entry khác nhau.
- `design-system-mobile` có 47 file component spec, mô tả 113 component set và
  994 variants; đây là Figma trace/spec của TTN, không phải package Flutter.

## BottomSheet pilot — khác biệt hiện tại

| Nguồn | Vai trò hiện tại | Điểm đáng giữ | Vấn đề |
|---|---|---|---|
| App `lib/core/widget` | Content container đơn giản | Dễ dùng, title + child, max/fixed height | Hard-code màu/spacing, lệ thuộc ScreenUtil, không presenter/safe-area/keyboard contract |
| `sli_common` legacy | Content frame nhiều option | Close/action/header, safe area, margin/radius | API chưa `Sli*`, không có gallery/usage/test; behavior/layout chưa được chứng nhận stable |
| `commons/base_ui` | DI service + modal presenter + `NormalBottomSheet` | Keyboard inset, dismiss/drag/scroll config, left/right action, subtitle | Coupled domain/Injectable/theme/assets; không phù hợp để copy nguyên khối |
| V2 design system | Figma anatomy cho Header/ActionBar/Main | Variant/anatomy/token reference rất chi tiết | TTN-specific, DRAFT, thiếu accessibility và chưa phải code |

BottomSheet stable tương lai nên cân nhắc tách API presenter
`showSliBottomSheet<T>()` khỏi content primitives như frame/header/action bar.
Tên variant phải semantic, không giữ tên Figma `Variant2/Variant3`. Quyết định
cuối chỉ được chốt sau behavior matrix và pilot story/test.

---

## Tổng hợp

### Nhận định chính

`sli_common` đã có nhiều công cụ nhưng chưa phải một “toolbox tự mô tả”. README
gallery cũ là nền tảng tốt nhưng không đủ để chọn component an toàn. Việc đồng
bộ phải bắt đầu bằng catalog + maturity status + behavior matrix, không bắt đầu
bằng di chuyển file.

### Hướng khuyến nghị

Xây mô hình ba lớp: README quick gallery, per-component docs và interactive
example showroom; preview được bảo vệ bằng golden/widget tests. Dùng BottomSheet
làm pilot, sau đó mới quyết định stable `Sli*` contract và adapter migration.
Xem V2/`commons`/Figma như nguồn học hỏi, không phải source of truth để bê nguyên.

### Rủi ro cần theo dõi

- Catalog thủ công drift khỏi code nếu không có validation/golden gate.
- Legacy API và stable API bị trộn trong cùng public barrel.
- Product-specific design/dependency từ V2 lọt vào toolkit cá nhân.

### Câu hỏi mở

- Preview sẽ ưu tiên ảnh light/dark tĩnh hay GIF/video cho interaction?
- Có cần support web để publish showroom, hay example app local là đủ ở giai
  đoạn đầu?
- Sau pilot, có muốn dùng framework kiểu Widgetbook hay tiếp tục custom showroom
  nhẹ?
- Stable BottomSheet cần những variant semantic nào cho phần lớn sản phẩm cá
  nhân: content-only, header, action bar, full-screen, draggable/scrollable?
