# D-0001: Phân trang danh sách: kéo để làm mới và tải thêm

- Trạng thái: proposed
- Ngày: 2026-10-08
- Phạm vi: feature
- Tags: pagination,list,load-more
- Tính năng: 
- Thay thế:
- Bị thay bởi:

## Bối cảnh

Hầu hết app có danh sách lấy từ server dài hơn một màn hình (đơn hàng, sản
phẩm, thông báo). Base đã có `ApiHandler.getList` trả `BaseListResponseModel`
(`page`, `perPage`, `totalResults`, `data`), `LoadingStatus` có `refresh`,
`loadMore`, `noMoreData`, `loadMoreError`, và `LoadingListScreen` +
`LoadingListModel` dùng `pull_to_refresh`. Nhưng chưa có cách thống nhất để
tính "còn trang", chống gọi trùng, và xử lý refresh chen ngang load more.

## Quyết định

Phân trang theo số trang qua `ApiHandler.getList` với query `page`/`perPage`,
đọc một lần thành `PageResult` ở domain, Cubit giữ `LoadingListModel` và render
bằng `LoadingListScreen` có sẵn.

- `PageResult<T>{items, page, hasMore}` tại
  `lib/domain/entities/common/page_result.dart`; `hasMore` lấy từ
  `totalResults` nếu có, nếu không thì "đủ trang là còn".
- State `<Feature>State extends BaseAppState<Object> implements
  BaseAppListState<T>` với `LoadingListModel<T> <items>`, `int page`,
  `bool hasMore`, `UiEffect<<Feature>Effect>? effect`; `loading` luôn bằng
  `<items>.loading`.
- Cubit có `load()`, `refresh()`, `loadMore()`; trang bắt đầu từ
  `Pagination.firstPage`, mỗi danh sách một hằng `pageSize` (mặc định 20).
- `loadMore()` chỉ chạy khi trạng thái `complete`/`loadMoreError` và
  `hasMore`; mỗi lần tải trang đầu tăng `_generation` để bỏ kết quả cũ; nối
  trang có lọc trùng theo `id`.
- `RefreshController` nằm ở Screen; `syncRefreshController` đồng bộ header và
  footer từ state.

## Phương án đã cân nhắc

| Phương án | Vì sao không chọn |
|---|---|
| Cursor/keyset (`after=<id>`) | Chính xác hơn khi dữ liệu chèn liên tục, nhưng backend hiện trả `page`/`perPage`; dùng cho timeline/chat bằng quyết định riêng |
| `infinite_scroll_pagination` | Thêm package và controller riêng song song với `LoadingListScreen` + `pull_to_refresh` đã có |
| Dùng `BaseListCubit` có sẵn | Có `page` và `isHasNexData` mutable, không qua `BaseAppState`, không có UI effect; giữ cho code cũ |
| Tải toàn bộ rồi cắt ở client | Tốn băng thông và bộ nhớ, chậm dần theo dữ liệu (xem `docs/performance/standards.md`) |

## Hệ quả

- Mọi danh sách server có thể dài làm đúng hình dạng trên, cùng tên trường và
  trạng thái.
- Hướng dẫn: `.agents/skills/flutter-patterns/references/pagination.md`.
- Code mẫu để chép và test bảo vệ:
  `test/patterns/pagination_pattern_test.dart` (19 test: `PageResult`, data
  source, Cubit, chống gọi trùng, refresh thắng load more, lọc trùng, widget).
