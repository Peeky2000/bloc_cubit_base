# D-0001: Phân trang danh sách: kéo để làm mới và tải thêm

- Trạng thái: accepted
- Ngày: 2026-10-08
- Phạm vi: feature
- Tags: pagination,list,load-more
- Tính năng: 
- Thay thế:
- Bị thay bởi:

## Bối cảnh

Hầu hết app có danh sách lấy từ server dài hơn một màn hình (đơn hàng, sản
phẩm, thông báo). Base đã có `ApiHandler.getList` trả `BaseListResponseModel`
(`page`, `perPage`, `totalResults`, `data`) và `LoadingStatus` có `refresh`,
`loadMore`, `noMoreData`, `loadMoreError`. `LoadingListScreen` hiện dựa trên
`pull_to_refresh` 2.0.0, bản cuối phát hành 2021-05-07, không có commit từ đó,
người đăng chưa xác minh. Chưa có cách thống nhất để tính "còn trang", chống
gọi trùng, retry trang lỗi, và xử lý refresh chen ngang load more.

## Quyết định

Phân trang theo số trang qua `ApiHandler.getList` với query `page`/`perPage`,
đọc một lần thành `PageResult` ở domain, Cubit giữ trạng thái, và render bằng
widget có sẵn của Flutter (`RefreshIndicator.adaptive`, `ListView.builder`,
scroll notification) trong một `PaginatedListView` dùng chung, không dùng
package phân trang.

- `PageResult<T>{items, page, hasMore}` tại
  `lib/domain/entities/common/page_result.dart`; trang rỗng luôn là hết, sau
  đó dùng `totalResults` nếu có, nếu không thì "đủ trang là còn".
- State `<Feature>State extends BaseAppState<Object>` với
  `List<T> <items>` (bất biến), `int page`, `bool hasMore`,
  `UiEffect<<Feature>Effect>? effect`; `loading` là trạng thái duy nhất.
- Cubit có `load()`, `refresh()`, `loadMore()`, `retryLoadMore()`; trang bắt
  đầu từ `Pagination.firstPage`, mỗi danh sách một hằng `pageSize` (mặc
  định 20).
- `loadMore()` chỉ chạy khi `complete` và `hasMore`; trang lỗi chỉ thử lại
  bằng nút Retry ở footer (`retryLoadMore()`), không thử lại khi cuộn; mỗi
  lần tải trang đầu tăng `_generation` để bỏ kết quả cũ; nối trang có lọc
  trùng theo `id`.
- `PaginatedListView<T>` tại `lib/widget/paginated_list_view.dart`: tải thêm
  khi còn dưới 250 px phía dưới (cả khi trang đầu không đủ đầy màn), mọi
  trạng thái kéo được để làm mới, spinner có nhãn `Semantics`, lỗi là
  `liveRegion`, nút dùng `SliButton`.
- Screen giữ `GlobalKey<RefreshIndicatorState>` và có action làm mới trên app
  bar (`show()`), là cách thay thế cho thao tác kéo (WCAG 2.5.7).

## Phương án đã cân nhắc

| Phương án | Vì sao không chọn |
|---|---|
| Giữ `LoadingListScreen` + `pull_to_refresh` 2.0.0 | Không phát hành từ 2021-05-07, không commit từ đó, người đăng chưa xác minh, 145 issue mở; bắt Cubit/Screen đồng bộ `RefreshController` bằng tay |
| `infinite_scroll_pagination` 5.1.1 (Flutter Favorite) | Tốt và dùng được với Flutter 3.44.5 (Dart ≥ 3.4), nhưng `PagingState` giữ trang, lỗi và `isLoading` song song với state Cubit; kéo theo `sliver_tools` 0.2.12 và `flutter_staggered_grid_view` 0.7.0, cả hai không phát hành từ 2023; phần ta cần chỉ khoảng 200 dòng widget dùng chung |
| `very_good_infinite_list` 0.9.0 (VGV) | Cách làm gần với ta (state-driven), nhưng bản cuối 2024-10-22 và không có pull-to-refresh |
| `easy_refresh` 4.0.0 | Cần Flutter ≥ 3.47 và Dart ≥ 3.13, không cài được trên 3.44.5; người đăng chưa xác minh |
| Cursor/keyset (`after=<id>`) | Chính xác hơn khi dữ liệu chèn liên tục (AIP-158), nhưng backend hiện trả `page`/`perPage`; khi API có `nextCursor` thì thêm bằng quyết định thay thế |
| Dùng `BaseListCubit` có sẵn | Có `page` và `isHasNexData` mutable, không qua `BaseAppState`, không có UI effect |
| Tải toàn bộ rồi cắt ở client | Tốn băng thông và bộ nhớ, chậm dần theo dữ liệu (`docs/performance/standards.md`) |

## Hệ quả

- Mọi danh sách server có thể dài làm đúng hình dạng trên, cùng tên trường và
  trạng thái, render bằng `PaginatedListView`.
- `LoadingListScreen` và `pull_to_refresh` chỉ còn cho code cũ; gỡ chúng khỏi
  `lib/` và `pubspec.yaml` là việc riêng do PM quyết định.
- Hướng dẫn: `.agents/skills/flutter-patterns/references/pagination.md`.
- Code mẫu để chép và test bảo vệ:
  `test/patterns/pagination_pattern_test.dart` (22 test: `PageResult`, data
  source, Cubit, chống gọi trùng, retry ở footer, refresh thắng load more, lọc
  trùng, widget tải thêm khi cuộn và khi trang ngắn, kéo để làm mới khi rỗng).

## Duyệt

PM chấp nhận ngày 2026-10-08 sau khi đối chiếu best practice. Khi áp dụng lần đầu: thay `LoadingListScreen` và gỡ `pull_to_refresh` (không còn được bảo trì từ 2021) bằng `PaginatedListView` dùng widget có sẵn của Flutter.
