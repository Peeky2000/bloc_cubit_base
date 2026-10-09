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

Stable surface hiện có `SliButton`, `SliSurface` và BottomSheet tách đôi:
`showSliBottomSheet<T>` điều phối modal/keyboard, còn `SliBottomSheetFrame`
render anatomy. App-local BottomSheet cũ chỉ là compatibility adapter.

## Dùng lại trước, viết mới khi cần

Trước khi viết widget, quét `sli_common`, `lib/widget/` và feature lân cận.
Có cái vừa thì dùng; không có thì viết mới trong app. `sli_common` là nơi tìm
đầu tiên, không phải nơi bắt buộc phải lấy. Chỉ đưa widget vào `sli_common`
khi nó thật sự dùng được cho nhiều app.

Khoảng cách và bo góc dùng token, không co giãn theo màn hình:

| Loại | Token |
|---|---|
| Padding, khoảng trống giữa phần tử | `SliSpacing.xxs` (2) · `xs` (4) · `sm` (8) · `md` (12) · `lg` (16) · `xl` (24) · `xxl` (32) · `xxxl` (48) |
| Bo góc | `SliRadii.sm` (6) · `md` (10) · `lg` (14) · `pill` |

Luật `ui-tokens` trong test convention chặn số ghi thẳng trong `EdgeInsets`,
`SizedBox(height:/width:)` làm khoảng trống và `Radius.circular` ở
`lib/presentation` và `lib/widget`. Kích thước của phần tử (icon, ảnh, chiều
cao ô nhập) không thuộc luật này. Chữ hiển thị lấy từ l10n.

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
