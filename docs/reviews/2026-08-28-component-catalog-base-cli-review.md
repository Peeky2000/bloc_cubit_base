# Review Component Catalog Và Dart Base CLI — 2026-08-28

## Kết luận

Hai foundation đã hoàn tất đúng phạm vi được duyệt:

1. `sli_common` trở thành toolbox có thể khám phá bằng README/catalog/showroom,
   không còn buộc developer đoán component từ tên file.
2. Create/rename có một Dart engine testable phía sau Derry, dry-run mặc định và
   validate trước mutation.

Review **không** kết luận widget app đã migrate hoặc sample branding đã trung
lập. BottomSheet vẫn là legacy pilot; `DeliveryGo`, product copy/l10n và
Fastlane artifact/key path được track làm follow-up có chủ ý.

## Revision được review

| Repository | Revision | Trạng thái |
|---|---|---|
| `sli_common` | `3604efd` | Commit trên branch `dev`, đã push origin |
| `bloc_cubit_base` | `a3d7c24` | Checkpoint implementation + native hardening local |

## Catalog evidence

| Gate | Kết quả |
|---|---|
| Public export inventory | 45/45 export có category và maturity status |
| Stable pilot | `SliButton`, `SliSurface` có usage/source/test |
| Legacy pilot | `BottomSheetWidget` ghi rõ frame-vs-presenter và giới hạn |
| README preview | Golden `test/goldens/catalog-pilot.png` dùng font thật |
| Runnable example | 3 tab: stable, BottomSheet, catalog help |
| `flutter analyze lib/src test example/lib` | Pass, 0 finding |
| `flutter test` trong `sli_common` | Pass, 5 tests |

Inventory test buộc public export mới phải có catalog entry. Golden được sinh
từ component thật, không dùng ảnh mock chụp tay làm source of truth.

## Base CLI safety review

- `doctor`, `rename`, `create` dùng chung config
  `tool/base_cli.template.json`.
- `rename` và `create` dry-run nếu thiếu `--apply`.
- Input package/bundle/display name được validate trước lập mutation plan.
- Apply recheck content của mọi file và destination của mọi move trước write.
- Atomic write giữ executable permission; lỗi giữa apply có rollback file edit
  và move đã hoàn thành.
- Scanner không follow symlink; bỏ qua `.git`, build output, Pods và toàn Git
  submodule `lib/modules/sli_common`.
- Native display name được thay theo cấu trúc field; PBX value luôn được quote
  và escape thay vì search-replace mù.
- Create chặn source Git dirty và destination tồn tại/nằm trong source.
- Derry chỉ forward command; logic rename không bị duplicate trong YAML/shell.
- Parser đã được smoke với display name có khoảng trắng qua Derry 1.5.

## Application gates

| Gate | Kết quả |
|---|---|
| `derry base doctor` | Pass; chỉ warning path legacy trước rename |
| `derry quality` | Pass; format 171 file, analyzer 0, boundary pass |
| Application tests | Pass; 18 tests, gồm 7 Base CLI tests |
| `git diff --check` | Pass trước checkpoint commit |
| Derry dry-run rename | Pass; in đầy đủ EDIT/MOVE và không sửa source |

## Create smoke test

Input:

```text
display name = Catalog Smoke
package      = catalog_smoke
bundle       = com.example.catalog_smoke
```

Kết quả:

- recursive local clone và `scripts/bootstrap.sh` pass;
- `derry base doctor` trong generated app pass, không còn warning MainActivity;
- `derry quality` trong generated app pass với 18 tests;
- `sli_common` checkout revision `3604efd` và sạch;
- không còn Dart package cũ trong import code hoặc application ID cũ trong
  native/runtime config;
- Android/iOS display names thành `Catalog Smoke` theo flavor;
- `xcodebuild -list -project ios/Runner.xcodeproj` pass và liệt kê đủ 9 build
  configurations cùng 3 schemes;
- thư mục smoke đã được chuyển vào Trash sau khi thu evidence, có thể recover.

## Debt còn lại, không che giấu

- Firebase file mẫu chỉ được đồng bộ bundle field; client/project config vẫn
  phải thay bằng file thật cho từng flavor.
- Signing và Store credential không được CLI tạo/copy.
- `DeliveryGo`, product l10n/copy, Fastlane artifact/key names, icon/splash và
  sample vertical slice chưa được neutralize.
- BottomSheet chưa có stable `showSliBottomSheet<T>()` contract, keyboard/
  draggable/accessibility parity test.
- Full legacy analyzer của `sli_common` chưa phải zero-debt gate.

Các mục này tiếp tục được track trong
[modernization status](../modernization-status.md) và
[roadmap tổng](../plan/2026-08-26-base-modernization.md).
