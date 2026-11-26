# Thiết kế kỹ thuật: Danh sách thông báo

- Mã: 002-notifications
- Trạng thái: Approved
- Tài liệu nguồn: [spec.md](spec.md)
- Người duyệt: PM, ngày 2026-11-26 (demo sinh code có gọi API)
- Quyết định liên quan: D-0001, ADR-0002, ADR-0005, ADR-0009

## 1. Yêu cầu nhận vào

| Mã | Yêu cầu (trích tài liệu) | Ghi chú kỹ thuật |
|---|---|---|
| AC1 | Từ Tài khoản có mục "Thông báo" mở danh sách | Hàng bấm được trong màn Tài khoản, `SLIRouting.toNamed` |
| AC2 | Tải từ server, 20/trang, mới nhất trước; tiêu đề, nội dung 1 dòng, thời gian, chấm chưa đọc | `GET /notifications?page&perPage`; thứ tự do server trả |
| AC3 | Kéo để tải lại, cuộn tới cuối tải trang tiếp, hết thì "Đã hết" | Mẫu phân trang D-0001 |
| AC4 | Không có thì "Chưa có thông báo" | Trạng thái rỗng của `PaginatedListView` |
| AC5 | Lỗi lần đầu: lỗi + Thử lại; lỗi trang tiếp: giữ danh sách, Thử lại ở cuối | `error` và `loadMoreError` của D-0001 |

## 2. Quyết định áp dụng

| Chủ đề | Quyết định | Nguồn |
|---|---|---|
| Phân trang | `page`/`perPage`, `PageResult`, `PaginatedListView`, chống trùng theo `id` | D-0001 (accepted) |
| State owner | Cubit | ADR-0002 |
| Effect | `UiEffect<NotificationListEffect>` | ADR-0009 |
| Route | `SLIRouting` + `AppPage` | ADR-0005 |

Quyết định mới đề xuất: không có.

## 3. Tái sử dụng

| Thứ dùng lại | Vị trí |
|---|---|
| Gọi API dạng danh sách | `ApiHandler.getList` |
| Hợp đồng danh sách | `BaseListResponse`, `BaseListResponseModel` |
| Trang đầu | `Pagination.firstPage` |
| Trạng thái danh sách | `LoadingStatus` (`refresh`, `loadMore`, `noMoreData`, `loadMoreError`) |
| Đọc thời gian ISO 8601 | `TimeIso8601JsonConverter` |
| Thông báo lỗi | `ErrorMapper.parse`, `handleErrorResponse` |
| Nút, token, icon | `SliButton`, `SliSpacing`, `SliIcons` |

Lần đầu app dùng phân trang nên thêm hai mảnh dùng chung theo D-0001:
`lib/domain/entities/common/page_result.dart` và
`lib/widget/paginated_list_view.dart`.

## 4. Lệnh sinh khung

```bash
derry scaffold -- notification_list --data=app_notification --apply
```

Domain là `app_notification` vì Flutter đã có lớp `Notification`.

## 5. Danh sách file

| Tầng | Đường dẫn | Mới / Sửa | Vai trò |
|---|---|---|---|
| Entity | `lib/domain/entities/app_notification/app_notification.dart` | Mới | `AppNotification` |
| Entity dùng chung | `lib/domain/entities/common/page_result.dart` | Mới | `PageResult<T>` |
| Model | `lib/data/model/response/app_notification/app_notification_response_model.dart` | Mới | JSON |
| Data source | `lib/data/datasource/remote/app_notification_remote_data_source.dart` | Mới | `getList` |
| Repository | `lib/domain/repositories/app_notification_repo.dart`, `lib/data/repositories/app_notification_repo_impl.dart` | Mới | |
| Use case | `lib/domain/use_case/app_notification_use_case.dart` | Mới | Trả `PageResult` |
| State | `lib/presentation/notification_list/cubit/` | Mới | Cubit, state, effect |
| Widget dùng chung | `lib/widget/paginated_list_view.dart` | Mới | Theo D-0001 |
| Screen | `lib/presentation/notification_list/view/notification_list_screen.dart` | Mới | |
| Màn Tài khoản | `lib/presentation/account/view/account_screen.dart` | Sửa | Hàng "Thông báo" |
| Route | `lib/core/common/route.dart` | Sửa | `notificationList` |
| DI | `lib/di/register_module.dart` | Sửa | `AppNotificationUseCase` |
| Endpoint | `lib/data/datasource/remote/url_end_point.dart` | Sửa | `/notifications` |
| l10n | `lib/l10n/arb/app_en.arb`, `app_vi.arb` | Sửa | |
| Test | `test/domain/page_result_test.dart`, `test/data/datasource/remote/app_notification_remote_data_source_test.dart`, `test/presentation/notification_list_cubit_test.dart`, `test/presentation/notification_list_screen_test.dart` | Mới | |

## 6. Domain

```dart
abstract class AppNotification {
  String get id;
  String get title;
  String get body;
  DateTime? get createdAt;
  bool get isRead;
}
```

| Trường | Kiểu | Bắt buộc | Nguồn từ API | Ghi chú |
|---|---|---|---|---|
| `id` | `String` | Có | `id` | Khoá chống trùng |
| `title` | `String` | Có | `title` | |
| `body` | `String` | Không, mặc định `''` | `body` | Hiển thị 1 dòng |
| `createdAt` | `DateTime?` | Không | `createdAt` (ISO 8601) | Thiếu thì không hiện giờ |
| `isRead` | `bool` | Không, mặc định `false` | `isRead` | Chấm chưa đọc |

## 7. API

| Mục | Giá trị |
|---|---|
| Method và path | `GET /notifications?page=&perPage=` |
| Request | Query `page` (từ 1), `perPage` = 20 |
| Response | `BaseListResponseModel<AppNotificationResponseModel>` |
| Lỗi nghiệp vụ | Không có mã riêng; lỗi mạng/server theo `ErrorMapper` |

## 8. Lưu trữ

Không áp dụng: không cache (spec không yêu cầu ngoại tuyến).

## 9. State và effect

Đúng hình dạng D-0001: `NotificationListState{notifications, page, hasMore,
effect}`, `loading` là trạng thái duy nhất của danh sách. Effect duy nhất:
`NotificationListShowErrorEffect` khi tải lại lỗi lúc đang có dữ liệu.

| Hành động của người dùng | Hàm Cubit | State chuyển thế nào | Effect |
|---|---|---|---|
| Mở màn | `load()` | loading → complete / noMoreData / error | |
| Kéo xuống | `refresh()` | refresh → complete / noMoreData | Lỗi khi đang có dữ liệu → ShowError |
| Cuộn gần cuối | `loadMore()` | loadMore → complete / noMoreData / loadMoreError | |
| Bấm Thử lại ở cuối | `retryLoadMore()` | như trên | |
| Bấm Thử lại toàn màn | `load()` | như mở màn | |

## 10. Giao diện

| Thành phần | Widget dùng lại hoặc mới | Key l10n |
|---|---|---|
| Danh sách | `PaginatedListView<AppNotification>` (mới, dùng chung) | `loading`, `loadFail`, `retry`, `noMoreData`, `errGeneral`, `noInternetShort` |
| Dòng thông báo | `_NotificationTile` trong màn (mới) | |
| Rỗng | Text | `notificationEmpty` |
| Tiêu đề, nút tải lại trên app bar | `AppBar` + `SliIcons.refresh` | `notificationTitle`, `retry` |
| Hàng ở màn Tài khoản | `_AccountRow` có `onTap` | `notificationTitle` |

Thời gian hiện `dd/MM/yyyy HH:mm` theo giờ máy (`intl`).

Design mapping: Không áp dụng — demo không có gói design D6.

## 11. Điều hướng

| Route | Path | Tham số | Đi từ đâu |
|---|---|---|---|
| `AppPage.notificationList` | `/notifications` | Không | Màn Tài khoản (`toNamed`) |

## 12. Lỗi, rỗng, tải, ngoại tuyến

| Tình huống | Hiển thị | Hành động thử lại |
|---|---|---|
| Lần đầu đang tải | Spinner giữa màn | |
| Lần đầu lỗi / ngoại tuyến | Thông điệp `ErrorMapper` + Thử lại | `load()` |
| Rỗng | "Chưa có thông báo", kéo được | `refresh()` |
| Trang tiếp lỗi | Giữ danh sách, "Lỗi" + Thử lại ở cuối | `retryLoadMore()` |
| Tải lại lỗi khi có dữ liệu | Giữ danh sách, dialog lỗi có Thử lại | nút tải lại trên app bar |
| Hết dữ liệu | "Đã hết" ở cuối | |

## 13. Bảo mật và quyền riêng tư

API trả thông báo của chính tài khoản (server kiểm tra token); client không
lọc. Không log nội dung thông báo.

## 14. Hiệu năng

| Luồng | Loại thao tác | Ngưỡng đề xuất |
|---|---|---|
| Cuộn danh sách 200 dòng | Cuộn | Theo `docs/performance/standards.md`, đo khi có server thật |

## 15. Test

| Yêu cầu | Test | Cấp |
|---|---|---|
| AC2 | Data source gửi `page`/`perPage`, parse `getList` | unit |
| AC2 | Model đọc đủ trường, thiếu trường dùng mặc định | unit |
| AC3 | `PageResult.fromResponse` có/không `totalResults`, trang rỗng | unit |
| AC3 | Tải tới `noMoreData`, không gửi thêm khi đang tải hoặc đã hết | unit |
| AC3 | Tải lại thay danh sách và thắng load more đang chạy | unit |
| AC3 | Chống trùng theo `id` | unit |
| AC4 | Trang đầu rỗng → rỗng | unit + widget |
| AC5 | Lần đầu lỗi → `error`; Thử lại gọi lại | unit + widget |
| AC5 | Trang tiếp lỗi giữ danh sách; `retryLoadMore` hỏi cùng trang | unit |
| AC2 | Dòng chưa đọc có chấm | widget |
| — | Kết quả sau `close()` bị bỏ qua | unit |

## 16. Truy vết

| Yêu cầu | Thiết kế | Test |
|---|---|---|
| AC1 | §5 Màn Tài khoản, §11 | chạy app |
| AC2 | §6, §7, §10 | data source, model, widget |
| AC3 | §9, D-0001 | Cubit, `PageResult` |
| AC4 | §10, §12 | Cubit, widget |
| AC5 | §9, §12 | Cubit, widget |

## 17. Câu hỏi nghiệp vụ

Không có cho demo. Với sản phẩm thật cần hỏi: bấm vào thông báo thì làm gì,
có đánh dấu đã đọc không.
