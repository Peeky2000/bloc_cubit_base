# Review Shadcn Facade Và BottomSheet Migration — 2026-09-30

## Kết luận

Phase Shadcn facade đã đủ evidence để đóng. BottomSheet là family đầu tiên đi
hết pipeline catalog → behavior matrix → stable contract → tests/golden →
adapter/deprecation → migrate caller. Không có API `shadcn_flutter` bị leak vào
application.

## Revision

| Repository | Revision | Trạng thái |
|---|---|---|
| `sli_common` | `29d1186` | Shadcn accessibility, variant/size và golden light/dark; đã push `dev` |
| `sli_common` | `3bd0dc9` | Stable BottomSheet contract, catalog, tests và deprecated legacy API; đã push `dev` |
| `bloc_cubit_base` | Pin `3bd0dc9` | Compatibility adapter và caller migration trong commit cùng review này |

## Behavior matrix BottomSheet

| Capability | App cũ | `sli_common` cũ | `commons/base_ui` | Contract `Sli*` đã chốt |
|---|---|---|---|---|
| Trách nhiệm | Frame | Frame | Presenter + frame | Presenter và frame tách riêng |
| Modal result generic | Caller tự gọi | Caller tự gọi | `dynamic` | `Future<T?>` |
| Dismiss / drag / root navigator | Caller tự cấu hình | Caller tự cấu hình | Có dismiss/drag | Có cấu hình typed |
| Keyboard inset | Không | Không | Có | Có `AnimatedPadding` |
| Header/title/subtitle | Title trái | Title giữa | Title/subtitle giữa | Title/subtitle, alignment/style tùy biến |
| Leading/trailing/close | Không | Có | Có | Có; close mặc định `maybePop` |
| Fit-content / fixed / max | Có | Có nhưng intrinsic dùng `Expanded` | Flexible/fixed | Có, clamp theo viewport |
| Safe area | Không | Có | Một phần | Content bottom safe area tùy chọn |
| Theme light/dark | Hard-code trắng | Background global nullable | Theme sản phẩm | Semantic `SliColors` |
| Accessibility | Chưa test | Chưa test | Chưa chứng minh | Header semantics, close 48×48 |
| Product coupling | ScreenUtil | Global static | Domain/DI/theme/assets | Không phụ thuộc sản phẩm/DI |

Không copy `BottomSheetImpl`/`NormalBottomSheet` từ `commons` vì chúng mang DI,
domain, asset và theme của sản phẩm. Chỉ học contract keyboard/dismiss/actions.

## Evidence

### Shadcn facade

- `SliButton`: 5 variant × 3 size đều giữ touch target tối thiểu 48×48.
- Loading/disabled và semantic label/enabled state có widget test.
- `SliSurface` có light/dark và borderless tests.
- Golden catalog được sinh riêng cho light và dark.
- Showroom bọc `SliShadcnScope`; app chỉ consume public `Sli*` barrel.

### BottomSheet

- `showSliBottomSheet<T>` quản lý modal, generic result và keyboard inset.
- `SliBottomSheetFrame` quản lý anatomy, viewport-safe sizing, safe area,
  semantic tokens và action slots.
- Legacy `sli_common.BottomSheetWidget` và app-local `BottomSheetWidget` đều có
  deprecation path; app-local class là adapter sang frame stable.
- `SelectionBottomSheet` và `MultiSelectionBottomSheet` đã dùng API stable trực
  tiếp, không còn phụ thuộc implementation app-local.
- Catalog tăng lên 46/46 public export có maturity entry.

## Gate đã chạy

| Command | Kết quả |
|---|---|
| `fvm flutter test` trong `sli_common` | Pass, 16 tests |
| `fvm flutter analyze lib/src test example/lib` | Pass, 0 finding |
| Golden light/dark update + verify | Pass |
| Full `fvm flutter analyze` trong `sli_common` | 241 legacy warning/info, 0 error mới trên stable surface |
| `derry quality` trong base | Pass: format 194 file, analyzer 0, architecture gate pass, 64 tests |

## Debt còn lại

- 10 family/file trùng còn lại chưa được migrate; mỗi family vẫn phải có
  behavior matrix và parity test riêng.
- Full historical `sli_common` còn 241 analyzer findings. Đây là debt thật cần
  burn down theo batch; không exclude legacy tree để làm đẹp số liệu.
- Adapter app-local giữ màu trắng/ScreenUtil để không đổi behavior caller cũ;
  code mới phải dùng contract semantic của `sli_common` trực tiếp.
