# Làm việc với The Forge và Designer

Base này là bên **dev Flutter** trong hệ The Forge. Bức tranh chung và cách bắt
đầu dự án: [the-forge README (mục Hệ sinh thái)](https://github.com/Peeky2000/the-forge/blob/init/README.md).
Thiết kế luồng: `the-forge/forge-src/plans/2026-10-12-base-contract-va-luong-kit.md`.

## Ai làm gì

| Repo | Việc |
|---|---|
| `the-forge-design` | Chỉ thiết kế: hướng, token, danh sách component, ảnh thiết kế, prototype |
| `the-forge` | Đặt hàng thiết kế, gen code component theo luật base, trang duyệt, giữ chữ ký duyệt |
| Base này | Giữ luật, gate, skill gen component; nhận kit đã duyệt vào `sli_common` |

Không dùng Forge vẫn code được: luật, gate, scaffold, skill gen component đều nằm
trong base.

## Hợp đồng với Forge

[`forge-base.json`](../../forge-base.json) ở gốc repo cho Forge biết:

- luật nằm ở đâu, và `rulesVersion` hiện tại;
- lệnh tạo app (`derry new`) và lệnh gate;
- `commands` (schemaVersion 2): lệnh `check`, `test`, `doctor`, `dev`. Lúc gắn Forge vào
  app, Forge nối các lệnh này vào `make check/test/doctor/dev`, không cần sửa tay Makefile;
- `sourceRoots`: thư mục code production (`lib/`); `skillsRoot`: nơi để skill của base,
  để `scripts/forge doctor` biết skill nào đã có;
- skill gen component, chỗ cất kit, chỗ cất ảnh golden, cách vẽ ảnh golden.

Có file này thì Forge không dùng luật Flutter riêng của nó (`stack-flutter`) mà
theo luật base. Đổi luật làm thay đổi cách viết code thì tăng `rulesVersion`.

## Luồng kit

1. Designer làm kit. Bạn duyệt thiết kế, kit chuyển `design-approved` và bị khoá.
2. Forge gen code bằng skill [`sli-kit-from-spec`](../../.agents/skills/sli-kit-from-spec/SKILL.md)
   trên nhánh `kit/<tên>-<version>` của `sli_common`, chạy gate base.
3. Ảnh golden được vẽ trên Linux (`lib/modules/sli_common/scripts/update_goldens.sh`).
4. Forge dựng trang duyệt: ảnh thiết kế cạnh ảnh code. Bạn duyệt.
5. Đạt thì merge vào `sli_common` `dev`, ghi `KIT-RECEIPT.json`, nâng submodule ở app.

Mỗi kit một thư mục theo version:

| Thứ | Chỗ |
|---|---|
| Code | `sli_common/lib/src/kit/<tên_snake>/v<version_snake>/` |
| Ảnh golden | `sli_common/test/goldens/kit/<tên>/<version>/` |
| Biên nhận | `KIT-RECEIPT.json` trong thư mục code |

## Ảnh golden chỉ vẽ và so trên Linux

Mac và Linux vẽ mép chữ khác nhau, nên ảnh chụp trên Mac làm CI Linux báo lệch
dù giao diện không đổi. Vì vậy:

- Trên Mac, `flutter test` vẫn dựng mọi widget nhưng không so ảnh;
  `--update-goldens` bị chặn.
- Muốn vẽ lại ảnh sau khi cố ý đổi giao diện: đẩy nhánh lên rồi chạy
  `lib/modules/sli_common/scripts/update_goldens.sh`. Script chạy workflow
  "Update goldens" trên GitHub và kéo commit ảnh mới về.

## Kit hiện có

`trial-kit@1.0.0` (`KitTokens`, `SliKitButton`, `SliKitTextField`,
`SliKitOtpField`) chỉ để chạy thử luồng, chưa từng được duyệt. Thay bằng kit của
dự án đầu tiên. Widget cũ trong `sli_common` được bỏ dần khi kit mới có
component thay thế.
