# Spec: Danh sách thông báo (demo sinh code có gọi API)

Spec ngắn để chạy thử luồng sinh code với một màn gọi API. Không phải yêu cầu
sản phẩm.

| Mã | Yêu cầu |
|---|---|
| AC1 | Từ màn Tài khoản có mục "Thông báo" mở màn Danh sách thông báo. |
| AC2 | Màn tải thông báo của tài khoản từ server, mỗi trang 20, mới nhất trước. Mỗi dòng có tiêu đề, nội dung một dòng và thời gian; thông báo chưa đọc có chấm đánh dấu. |
| AC3 | Kéo xuống để tải lại; cuộn tới cuối thì tải trang tiếp; hết dữ liệu thì báo "Đã hết". |
| AC4 | Không có thông báo nào thì hiện "Chưa có thông báo". |
| AC5 | Lỗi khi tải lần đầu: hiện lỗi và nút Thử lại. Lỗi khi tải trang tiếp: giữ danh sách đang có, hiện Thử lại ở cuối danh sách. |

API (backend đã có):

`GET /notifications?page=<n>&perPage=<n>` → `{ "data": [ { "id", "title", "body", "createdAt" (ISO 8601), "isRead" } ], "page", "perPage", "totalResults", "message" }`
