# Thêm Môi Trường

1. Chỉ thêm value vào `AppEnvironment` nếu nó có lifecycle deploy/config riêng,
   không chỉ là URL dev khác.
2. Định nghĩa default và validation trong `lib/core/app/app_config.dart`.
3. Thêm `lib/main_<environment>.dart` tối giản, chỉ chọn environment và gọi
   `bootstrap()`.
4. Thêm lệnh Derry run/build tương ứng và owner CI/release nếu cần.
5. Đặt cấu hình Firebase/native ngoài source control khi có secret hoặc signing
   material.
6. Test URL không hợp lệ, production HTTPS, và ràng buộc inspector.

Dùng `--dart-define` cho giá trị runtime. Không thêm asset `.env` hoặc đọc cấu
hình tùy tiện từ Widget, Cubit, repository, hoặc data source.
