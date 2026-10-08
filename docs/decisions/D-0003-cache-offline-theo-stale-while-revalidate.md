# D-0003: Cache offline theo stale-while-revalidate

- Trạng thái: accepted
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
chưa có mẫu cache dữ liệu màn hình. `connectivity_plus` và `NetworkChecker` đã
có nhưng chỉ dùng để chặn request và hiện thông báo mạng.

## Quyết định

Repository sở hữu cache và network, trả một `Stream<CachedSnapshot<T>>`: giá
trị đã lưu trước (nếu thuộc tài khoản hiện tại và chưa quá hạn), rồi giá trị
mới từ network trừ khi bản lưu còn tươi; Cubit chỉ render snapshot và tự làm
mới khi có mạng lại.

- Ngữ nghĩa theo HTTP `max-age` + `stale-while-revalidate` (RFC 5861):
  `freshFor` (mặc định 5 phút) không gọi mạng; đến `maxStale` (mặc định 7
  ngày) hiện bản lưu và làm mới; quá `maxStale` thì xoá và không hiện, kể cả
  khi offline. Thời điểm lưu ở tương lai (đồng hồ bị chỉnh) không bao giờ là
  tươi.
- `CachedSnapshot<T>{value, source, fetchedAt, revalidating}` tại
  `lib/domain/entities/common/cached_snapshot.dart`.
- Port: `Stream<CachedSnapshot<T>> watch<X>({bool forceRefresh = false})` và
  `Future<void> clearCache()` (vô hiệu hoá sau khi sửa dữ liệu).
- Local data source lưu `CacheEntry{ownerId, fetchedAt, value}` trong
  SharedPreferences, key `cache.<name>.v1`; bản hỏng là miss và bị xoá; đổi
  shape thì tăng `.v2`.
- Không có tài khoản đăng nhập thì không đọc, không ghi; chỉ lần đọc mới nhất
  và cùng tài khoản mới được ghi (revision).
- `UserCacheCleaner.clearAll()` tại
  `lib/data/datasource/local/user_cache_cleaner.dart` xoá mọi key `cache.*`;
  `SessionRepoImpl.end()` gọi nó một lần cho cả đăng xuất và hết hạn.
- State: `summary`, `updatedAt`, getter `showsSavedData` (banner "đang
  offline, cập nhật lúc ..."), là state lâu dài; banner giữ nguyên khi đang
  thử lại và chỉ tắt khi có snapshot từ network.
- Cubit nhận `NetworkChecker`, nghe `connectionChanges`; khi có mạng lại mà
  đang có lỗi thì gọi `refresh()`. Kết nối chỉ là gợi ý thử lại, không bao giờ
  dùng để bỏ qua request.

## Phương án đã cân nhắc

| Phương án | Vì sao không chọn |
|---|---|
| Network-first, cache khi lỗi (Flutter offline-first, cách 1) | Mở màn phải chờ mạng hoặc timeout; dùng cho dữ liệu phải đúng ngay (số dư trước thanh toán), không dùng cho mẫu này |
| Cache-first không làm mới | Dữ liệu cũ có thể hiện mãi như mới; chỉ hợp với dữ liệu đã đồng bộ riêng |
| `HydratedBloc` 11.0.0 | `optional-capabilities.md` hoãn; lưu cả state UI, không gắn chủ sở hữu, khó xoá khi đăng xuất |
| `dio_cache_interceptor` 4.0.7 | Cache ở tầng HTTP, không biết tài khoản, Cubit không biết dữ liệu cũ hay mới |
| drift (cho mẫu nhỏ này) | Hợp với danh sách, truy vấn, migration có kiểu; quá nặng cho một giá trị vài KB. Khi cần: `drift ">=2.34.4 <2.35.0"`, `drift_flutter ^0.3.1`, `drift_dev 2.34.0` vì `injectable_generator ^2.12.1` giữ analyzer < 11; drift 2.35 cần nâng injectable lên 3 |
| isar 3.1.0+1, hive 2.2.3 | isar không phát hành từ 2023-04-25 và yêu cầu SDK < 3.0; hive không phát hành từ 2022 |
| hive_ce 2.20.2 | Đang được duy trì, nhưng không có truy vấn SQL và migration có kiểu; SharedPreferences đủ cho giá trị nhỏ |
| Mỗi repository tự xoá cache ở `end()` | Dễ quên khi thêm tính năng mới; một prefix và một `clearAll()` an toàn hơn (storage rules 1, 4) |
| Chặn request khi `connectivity_plus` báo offline | connectivity_plus ghi rõ không nên dựa vào trạng thái kết nối để quyết định gọi mạng (Wi-Fi có thể không có internet) |
| Cubit tự đọc cache rồi gọi API | Mỗi Cubit lặp lại logic và dễ sai thứ tự, trái quy tắc "một chủ sở hữu" |

## Hệ quả

- Màn cần mở nhanh và đọc offline dùng đúng port này; dữ liệu nhạy cảm không
  cache vào SharedPreferences (không mã hoá, có trong Android Auto Backup).
- Mọi key cache của user bắt đầu bằng `cache.`; feature đầu tiên dùng mẫu này
  thêm `UserCacheCleaner` và lời gọi trong `SessionRepoImpl.end()`.
- Danh sách lớn hoặc cần truy vấn offline dùng drift bằng quyết định riêng,
  với ràng buộc phiên bản ở trên.
- Hướng dẫn: `.agents/skills/flutter-patterns/references/offline_cache.md`.
- Code mẫu và test bảo vệ: `test/patterns/offline_cache_pattern_test.dart`
  (23 test: khởi động lại, còn tươi, ép làm mới, offline, quá `maxStale`, đồng
  hồ lệch, đổi tài khoản, không đăng nhập, phản hồi sau đăng xuất, xoá mọi
  cache khi đăng xuất, bản hỏng, banner khi thử lại, tự làm mới khi có mạng,
  request mới thắng cả trên màn và trong cache).

## Duyệt

PM chấp nhận ngày 2026-10-08 sau khi đối chiếu best practice. Khi tính năng đầu tiên cần cache: thêm `UserCacheCleaner` và gọi nó trong `SessionRepoImpl.end()`. Chỉ dùng drift khi cache lớn; drift 2.35 trở lên cần nâng injectable lên 3.
