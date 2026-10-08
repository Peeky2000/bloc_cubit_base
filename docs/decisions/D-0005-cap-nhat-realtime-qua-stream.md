# D-0005: Cập nhật realtime qua Stream

- Trạng thái: proposed
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
backoff mũ có trần; adapter WebSocket khi backend có socket, adapter polling
khi không, cùng một Cubit cho cả hai.

- Sự kiện: `<X>Changed{..., updatedAt}`,
  `RealtimeConnectionChanged(connecting | live | reconnecting)`; lỗi chỉ là
  `RealtimeFailure{unauthorized | notFound}` khi thử lại vô ích.
- `RealtimeBackoff`: 1 giây nhân đôi tới 30 giây, jitter 20%, reset khi live.
- WebSocket: plugin đề xuất `web_socket_channel` (thêm trực tiếp), `wss://`,
  token ở header bắt tay, ping 20 giây; close code 4401/4404 là lỗi cuối.
- Polling: mặc định 15 giây, chỉ phát khi đổi, 401/403/404 là lỗi cuối.
- Cubit bỏ sự kiện cũ hơn `updatedAt` đang hiển thị; Screen gọi `pause()`/
  `resume()` qua `AppLifecycleListener`.
- Adapter dựng stream bằng `StreamController`, không dùng `async*` quanh nguồn
  vô hạn.

## Phương án đã cân nhắc

| Phương án | Vì sao không chọn |
|---|---|
| `socket_io_client` | Chỉ khi backend dùng Socket.IO; giao thức riêng, nặng hơn |
| Firestore/Realtime Database | Đổi nguồn dữ liệu, cần quyết định dự án (ADR-0004 REST mặc định) |
| Server-Sent Events | Một chiều, hỗ trợ proxy/mobile kém đồng đều; có thể làm adapter thứ ba cùng port |
| Push để cập nhật màn đang mở | Không đảm bảo thứ tự và thời gian; push dành cho lúc app ở nền |
| Polling cố định không backoff | Dồn tải khi server lỗi |

## Hệ quả

- Mọi dữ liệu realtime đi qua port Stream này; đổi WebSocket và polling chỉ
  đổi binding DI.
- Hướng dẫn: `.agents/skills/flutter-patterns/references/realtime.md`.
- Code mẫu và test bảo vệ: `test/patterns/realtime_pattern_test.dart`
  (17 test: backoff, subscribe, bỏ message lạ, mất kết nối và kết nối lại,
  close code, huỷ, polling, Cubit pause/resume).
