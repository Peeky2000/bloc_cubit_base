# D-0003: Cache offline theo stale-while-revalidate

- Trạng thái: proposed
- Ngày: 2026-10-08
- Phạm vi: feature
- Tags: cache,offline
- Tính năng: 
- Thay thế:
- Bị thay bởi:

## Bối cảnh

Một số màn cần mở ngay và vẫn đọc được khi mất mạng (tổng quan, hồ sơ, cấu
hình). Base chỉ có lưu phiên và cài đặt; `storage-patterns.md` yêu cầu dữ liệu
của user bị xoá khi đăng xuất và ghi có revision khi có thể tranh chấp, nhưng
chưa có mẫu cache dữ liệu màn hình.

## Quyết định

Repository sở hữu cache và network, trả một `Stream<CachedSnapshot<T>>`: giá
trị đã lưu trước (nếu thuộc tài khoản hiện tại), rồi giá trị mới từ network trừ
khi bản lưu còn tươi; Cubit chỉ render snapshot.

- `CachedSnapshot<T>{value, source, fetchedAt, revalidating}` tại
  `lib/domain/entities/common/cached_snapshot.dart`.
- Port: `Stream<CachedSnapshot<T>> watch<X>({bool forceRefresh = false})` và
  `Future<void> clearCache()`.
- Local data source lưu `CacheEntry{ownerId, fetchedAt, value}` trong
  SharedPreferences, key `cache.<name>.v1`; bản hỏng là miss và bị xoá.
- `freshFor` mặc định 5 phút; repository có `now` inject được để test.
- Revision trong repository: chỉ lần đọc mới nhất được ghi cache.
- `clearCache()` được gọi từ đường kết thúc phiên.
- State: `summary`, `updatedAt`, getter `showsSavedData` (banner "đang
  offline, cập nhật lúc ..."), là state lâu dài, không phải effect.

## Phương án đã cân nhắc

| Phương án | Vì sao không chọn |
|---|---|
| `HydratedBloc` | `optional-capabilities.md` hoãn; lưu cả state UI, không gắn chủ sở hữu, khó xoá khi đăng xuất |
| `dio_cache_interceptor` | Cache ở tầng HTTP, không biết tài khoản, Cubit không biết dữ liệu cũ hay mới |
| Drift/Isar/Hive | Hợp với dữ liệu lớn hoặc cần truy vấn; thêm bằng quyết định riêng khi cần |
| Cubit tự đọc cache rồi gọi API | Mỗi Cubit lặp lại logic và dễ sai thứ tự, trái quy tắc "một chủ sở hữu" |

## Hệ quả

- Màn cần mở nhanh và đọc offline dùng đúng port này; dữ liệu nhạy cảm không
  cache vào SharedPreferences.
- Hướng dẫn: `.agents/skills/flutter-patterns/references/offline_cache.md`.
- Code mẫu và test bảo vệ: `test/patterns/offline_cache_pattern_test.dart`
  (15 test: khởi động lại, còn tươi, ép làm mới, offline, đổi tài khoản, xoá,
  bản hỏng, request mới thắng cả trên màn và trong cache).
