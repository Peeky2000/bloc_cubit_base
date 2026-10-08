# Cách dùng sổ quyết định

Sổ quyết định giống thư ký của đội dev. Mọi lựa chọn kỹ thuật có thể lặp lại ở
tính năng khác đều được ghi một lần, tìm được, và được làm giống nhau về sau.

## Khi nào ghi

- Chọn một cách làm mà tính năng sau có thể gặp lại: phân trang, form, cache,
  upload, định dạng tiền, cách đặt tên một khái niệm nghiệp vụ.
- Lệch khỏi một quyết định cũ. Khi đó tạo quyết định mới thay thế, không sửa âm
  thầm.
- Không ghi chi tiết chỉ dùng một lần trong một màn; phần đó nằm trong
  `tech.md` của tính năng.

## Hai cấp

| Cấp | Nơi lưu | Ví dụ |
|---|---|---|
| Tính năng (`D-NNNN`) | `docs/decisions/` | "Danh sách đơn dùng phân trang theo trang, 20 item mỗi trang" |
| Dự án (ADR) | `docs/adr/` | "Cubit mặc định, BLoC khi cần" |

Một quyết định tính năng được dùng lại ở nhiều nơi thì nâng thành ADR.

## Vòng đời

```text
proposed → accepted → (superseded | rejected)
```

- `proposed`: agent hoặc dev đề xuất, thường đi kèm một `tech.md`.
- `accepted`: PM duyệt. Từ đây mọi tính năng phải theo.
- `superseded`: có quyết định mới thay thế; ghi `Bị thay bởi:` ở bản cũ và
  `Thay thế:` ở bản mới.
- `rejected`: đã cân nhắc và không chọn; giữ lại để không đề xuất lại.

Không xoá quyết định. Không sửa nội dung một quyết định đã `accepted`; tạo bản
mới thay thế.

## Lệnh

```bash
python3 tool/decisions/decisions.py search "phân trang"     # tìm, có dấu hoặc không dấu
python3 tool/decisions/decisions.py new "Phân trang theo trang" --tags pagination,list --feature order_list
python3 tool/decisions/decisions.py new "Định dạng tiền tệ" --scope project --tags money,format
python3 tool/decisions/decisions.py index                   # sinh lại README.md
python3 tool/decisions/decisions.py check                   # kiểm tra, chạy trong derry quality
```

Hoặc qua derry: `derry decision search "phân trang"`, `derry decision new -- "<tiêu đề>"`,
`derry decision index`, `derry decision check`.

## Thuật ngữ

Tên khái niệm nghiệp vụ dùng thống nhất trong code nằm ở
[glossary.md](glossary.md). Khi tài liệu mới dùng một từ đã có, dùng đúng tên
trong bảng. Khi có từ mới, thêm một dòng.
