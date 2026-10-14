# Làm việc với The Forge và Designer

Base này là bên **dev Flutter** trong hệ The Forge. Bức tranh chung và cách bắt
đầu dự án: [the-forge README (mục Hệ sinh thái)](https://github.com/Peeky2000/the-forge/blob/init/README.md).
Thiết kế luồng: `the-forge/forge-src/plans/2026-10-12-base-contract-va-luong-kit.md`.

## Ai làm gì

| Repo | Việc |
|---|---|
| `the-forge-design` | Chỉ thiết kế: hướng, token, danh sách component, ảnh thiết kế, prototype, `spec/screens.json`. **Không viết code** |
| `the-forge` | Đặt hàng thiết kế, viết nghiệp vụ (`behaviors[]`), gen code component theo luật base, trang duyệt, giữ chữ ký duyệt |
| Base này | Giữ luật, gate, skill. Agent trong app (theo luật này) là **tác giả duy nhất** của code trong `lib/`: kit vào `sli_common`, màn tính năng vào feature |

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

## Luồng tính năng (contract 0.2)

Giống team bình thường: Designer vẽ, Forge (PO) quyết nghiệp vụ, agent dev viết code.

1. **Trước tiên phải có kit đã hiện thực.** Forge từ chối tạo job tính năng khi kit
   chưa được gen trong `sli_common`, chưa duyệt code, hoặc app chưa nâng submodule tới
   commit đó (mã lỗi báo đúng bước còn thiếu).
2. Designer giao gói thiết kế, không có file Dart. Forge cất ở
   `docs/specs/<request-id>/design/<rev>/`: `spec/screens.json`, ảnh `reference/`
   cho từng trạng thái, `assets/` (chưa vào app), prototype HTML.
3. Bạn bấm thử prototype và duyệt (D4). Forge đóng handoff (D6). Task trong ROADMAP
   ghi `Design: <job>/D6@<rev>`; chưa có D6 thì chưa code.
4. `/tech-design` đọc `screens.json`: component → widget kit trong `sli_common`,
   trạng thái → state của Cubit, `dataBindings` → entity, `effectRef` → behavior của
   Forge (lưu ngay hay chờ server, lỗi thì làm gì). Bảng "Design mapping" trong `tech.md`.
5. `/build-feature` code theo luật base, đưa asset cần dùng vào `assets/` và ghi
   `ASSET-PROMOTION.json`. `./scripts/quality.sh` kiểm hash nguồn và đích.
6. Golden và ảnh màn chạy trên simulator được gửi cho Designer review (D7).

Token: tính năng không đổi token. Cần màu hay khoảng cách mới thì mở design-system job,
ra kit version mới.

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
