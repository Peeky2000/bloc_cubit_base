# ADR 0002: Dùng Cubit Mặc Định và Hỗ Trợ BLoC

- Trạng thái: Accepted
- Ngày: 2026-08-26

## Quyết định

Dùng Cubit cho đa số màn hình. Dùng BLoC cổ điển khi event concurrency,
debounce, nhiều producer, hoặc luồng event cần audit rõ thật sự cải thiện độ
đúng. Cả hai đều phụ thuộc vào use case và được đăng ký theo factory scope.

## Hệ quả

Đường đi phổ biến vẫn gọn mà không mất năng lực BLoC. Guide và template phải
giải thích luật chọn lựa và test cả hai pattern.
