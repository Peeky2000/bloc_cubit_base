# Làm việc với The Forge và Designer

Base này là bên **dev Flutter** trong hệ sinh thái The Forge. Bức tranh chung và cách bắt đầu dự án: [the-forge/START-HERE.md](https://github.com/Peeky2000/the-forge/blob/init/START-HERE.md).

| Việc | Ở đâu |
|---|---|
| Cài kit thiết kế thành component `Sli*` | Skill `.agents/skills/sli-kit-from-spec/SKILL.md` |
| Đối chiếu thiết kế với Flutter bằng mắt | `python3 tool/kit/compare.py --kit <the-forge-design>/kits/<tên>/<version> --flutter lib/modules/sli_common/test/goldens/kit` rồi mở `build/kit-compare/index.html` |
| Code màn từ thiết kế của Designer | Luồng thường của base: `/tech-design` đọc `docs/specs/<id>/design/` → PM duyệt → `/build-feature` |

`sli_common` hiện có `KitTokens` và `SliKitButton`, `SliKitTextField`, `SliKitOtpField` từ `trial-kit@1.0.0`, chỉ để chạy thử; thay bằng kit của dự án đầu tiên. Widget cũ trong `sli_common` được bỏ dần khi kit mới có component thay thế.
