# Năng Lực Tùy Chọn

Base giữ tính hữu dụng bằng cách để infrastructure phụ thuộc sản phẩm ở dạng
tùy chọn.

| Năng lực | Trạng thái | Điều kiện adopt |
|---|---|---|
| GraphQL | Hoãn | Có schema và operation thật cần dùng |
| Deep links | Hoãn | Biết rõ product routes và ownership rules |
| Firebase Messaging | Hoãn | Biết rõ notification contract và navigation |
| Version Health / Firebase Observability | Phase cuối | Core base zero-debt; có metric, privacy, rollout và rollback contract |
| HydratedBloc | Hoãn | State có yêu cầu persistence tường minh |
| Freezed state unions | Hoãn | State thủ công chứng minh gây hại correctness |

Version Health gồm bốn nguồn dữ liệu tách biệt: Analytics cho adoption,
Crashlytics cho stability, Firebase Performance cho startup/screen/network và
Remote Config cho staged rollout/kill switch. Chỉ tổng hợp chúng thành quyết
định continue/hotfix sau khi có threshold, owner và rollback policy rõ ràng.

Không adopt VIPER hoặc một AI process framework vào runtime/base architecture.
Thư mục `.agents` chỉ chứa playbook phục vụ Flutter/mobile engineering như code
convention, source review, performance, testing, security, lifecycle và release.

Module tùy chọn phải gỡ độc lập được và không làm yếu đường mặc định REST,
Cubit/BLoC, hoặc Clean Architecture.
