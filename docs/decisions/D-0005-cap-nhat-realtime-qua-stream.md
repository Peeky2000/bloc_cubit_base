# D-0005: Cập nhật realtime qua Stream

- Trạng thái: accepted
- Ngày: 2026-10-08
- Phạm vi: feature
- Tags: realtime,websocket,polling,stream
- Tính năng: 
- Thay thế:
- Bị thay bởi:

## Bối cảnh

Màn theo dõi đơn, trạng thái giao hàng hay tiến độ công việc cần cập nhật khi
đang mở. Backend có thể có WebSocket hoặc chỉ có REST. `web_socket_channel`
mới là phụ thuộc gián tiếp. Chưa có quy tắc kết nối lại, xử lý mất mạng, hay
dừng khi app vào nền.

## Quyết định

Port domain là một `Stream<<Feature>RealtimeEvent>`: kết nối khi listen, ngắt
khi cancel, phát snapshot hiện tại sau mỗi lần (kết nối lại), kết nối lại với
backoff mũ có trần và full jitter; adapter WebSocket (`web_socket_channel`
^3.0.3) khi backend có socket, adapter polling khi không, cùng một Cubit.

- Sự kiện: `<X>Changed{..., updatedAt}`,
  `RealtimeConnectionChanged(connecting | live | reconnecting)`; lỗi chỉ là
  `RealtimeFailure{unauthorized | notFound}` khi thử lại vô ích.
- `RealtimeBackoff`: full jitter, ngẫu nhiên trong [0, min(30 giây,
  1 giây·2ⁿ)]; reset khi nhận snapshot.
- Plugin: `web_socket_channel` ^3.0.3 (tools.dart.dev, bản mới nhất, đã là
  phụ thuộc gián tiếp 3.0.1), thêm trực tiếp; không cần cấu hình native.
- WebSocket: `wss://`; mỗi lần kết nối lấy ticket ngắn hạn dùng một lần qua
  `POST /realtime/tickets` (đi qua `ApiClient` nên `SessionInterceptor` làm
  mới token trước) và gửi ở header `Authorization` lúc bắt tay, không bao giờ
  ở query; `pingInterval` 20 giây, `connectTimeout` 10 giây; đóng bằng mã
  1000.
- Close 4401 khi đã live là phiên hết hạn phía server: kết nối lại với ticket
  mới. 4401 ngay sau ticket mới, ticket bị từ chối (401/403), 4404 là lỗi
  cuối.
- Polling: mặc định 15 giây, chỉ phát khi đổi, 401/403/404 là lỗi cuối.
- Cubit bỏ sự kiện cũ hơn `updatedAt` đang hiển thị; Screen gọi `pause()`/
  `resume()` qua `AppLifecycleListener`; `resume` chỉ chạy lại cái `pause`
  đã dừng, không chạy lại stream đã lỗi cuối.
- Thay đổi khi app ở nền đi qua push (D-0007), không giữ socket ở nền.
- Adapter dựng stream bằng `StreamController`, không dùng `async*` quanh nguồn
  vô hạn.

## Phương án đã cân nhắc

| Phương án | Vì sao không chọn |
|---|---|
| `web_socket_client` (felangel, 0.2.1) | Có sẵn reconnect và trạng thái kết nối, nhưng header cố định lúc tạo nên token làm mới không được dùng khi kết nối lại, và 4401/4404 vẫn bị thử lại; ít phát hành |
| `socket_io_client` | Chỉ khi backend dùng Socket.IO; giao thức riêng, nặng hơn |
| Firestore/Realtime Database listener | Đổi nguồn dữ liệu và mô hình bảo mật (Security Rules), cần quyết định dự án (ADR-0004 REST mặc định) |
| Server-Sent Events | Một chiều, Dart không có client chuẩn của Dart team, proxy/mobile hỗ trợ không đều; có thể làm adapter thứ ba cùng port |
| Token trong query (`?token=`) | Lọt vào log proxy và server (OWASP WebSocket Cheat Sheet) |
| Token gửi ở message đầu tiên | Hợp lệ (OWASP), nhưng server phải giữ trạng thái chưa xác thực; ticket ở header từ chối ngay lúc bắt tay |
| Backoff jitter ±20% (bản trước) | Client vẫn dồn quanh cùng mốc; full jitter tốn ít công nhất (AWS Architecture Blog) |
| Giữ socket khi app ở nền | Doze ngắt mạng, tốn pin; Android khuyên dùng FCM |
| Push để cập nhật màn đang mở | Không đảm bảo thứ tự và thời gian; push dành cho lúc app ở nền |
| Polling cố định không backoff | Dồn tải khi server lỗi |

## Hệ quả

- Mọi dữ liệu realtime đi qua port Stream này; đổi WebSocket và polling chỉ
  đổi binding DI.
- Backend cần: endpoint ticket, kiểm quyền mỗi subscribe, snapshot trước sau
  mỗi lần subscribe, close 4401/4404, trả pong.
- Hướng dẫn: `.agents/skills/flutter-patterns/references/realtime.md`.
- Code mẫu và test bảo vệ: `test/patterns/realtime_pattern_test.dart`
  (20 test: backoff full jitter, subscribe, bỏ message lạ, mất kết nối và kết
  nối lại, 4401 trước/sau live, ticket bị từ chối, huỷ, polling, Cubit
  pause/resume, resume sau lỗi). Adapter `WebSocketChannelFactory` trong file
  đã được analyze với `web_socket_channel` 3.0.3.

## Duyệt

PM chấp nhận ngày 2026-10-08 sau khi đối chiếu best practice. Cần backend có endpoint cấp vé `POST /realtime/tickets` và mã đóng kết nối 4401, 4404 trước khi dùng.
