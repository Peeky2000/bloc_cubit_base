# UI Toolkit

`sli_common` là UI toolkit cá nhân có thể tái sử dụng và được mount làm Git
submodule tại `lib/modules/sli_common`.

## Vị trí đặt code

| Phạm vi | Vị trí |
|---|---|
| Component, utility, hoặc design token dùng chéo app | `sli_common` |
| Composition có branding của app | `lib/core/widget` hoặc `lib/widget` |
| Widget chỉ dùng trong một feature | `lib/presentation/<feature>/view` |

Shadcn Flutter là chi tiết triển khai phía sau wrapper `Sli*` ổn định. App code
không nên rải direct Shadcn import; escape hatch có tài liệu là chấp nhận được
cho thử nghiệm một lần. Public component phải định nghĩa variants,
loading/disabled/error states, semantics, light/dark behavior, và compatibility
khi migrate.

Component legacy được chuyển dần qua adapter và deprecation notice. Không copy
cùng một component vào cả hai repository.

## Catalog là gate trước migration

Public API được tra từ `sli_common/README.md` và `sli_common/docs/catalog`.
Mỗi export phải có category và maturity (`stable`, `legacy`, `experimental`,
`deprecated`). Component stable cần usage, runnable example, behavior/semantics
test và preview/golden phù hợp.

Migration theo flow:

```text
inventory → behavior matrix → stable Sli* contract → tests/preview
          → compatibility adapter → deprecation → migrate caller
```

`base_flutter_project_v2`, `/Work/commons` và design-system-mobile chỉ là nguồn
tham khảo anatomy/variant/token. Không copy nguyên product dependency, DI,
branding hoặc Figma draft vào toolkit.
