# Năng Lực Tùy Chọn

Base giữ tính hữu dụng bằng cách để infrastructure phụ thuộc sản phẩm ở dạng
tùy chọn.

| Năng lực | Trạng thái | Điều kiện adopt |
|---|---|---|
| GraphQL | Hoãn | Có schema và operation thật cần dùng |
| Deep links | Hoãn | Biết rõ product routes và ownership rules |
| Firebase Messaging | Hoãn | Biết rõ notification contract và navigation |
| HydratedBloc | Hoãn | State có yêu cầu persistence tường minh |
| Freezed state unions | Hoãn | State thủ công chứng minh gây hại correctness |
| VIPER/AI gates nâng cao | Giai đoạn sau | Core base và docs đã ổn định |

Module tùy chọn phải gỡ độc lập được và không làm yếu đường mặc định REST,
Cubit/BLoC, hoặc Clean Architecture.
