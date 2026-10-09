# Môi Trường và Bootstrap

Entry point chọn một environment có kiểu rõ ràng rồi chuyển ngay cho
`bootstrap(...)`. Entry point không initialize plugin hoặc register dependency
feature.

Thứ tự bootstrap:

1. Ensure Flutter bindings.
2. Cài guarded error reporting và `BlocObserver`.
3. Validate immutable environment configuration.
4. Configure dependency graph, gồm các plugin dependency pre-resolved.
5. Áp dụng device policy.
6. Khởi động diagnostics tùy chọn ngoài production.
7. Gọi `runApp`.

Giá trị môi trường là input compile-time `--dart-define` với placeholder local
an toàn. Secret không được lưu trong `.env` hoặc commit trong flavor file. Base
URL không hợp lệ phải fail trước network request đầu tiên.

## Thêm một môi trường

1. Chỉ thêm value vào `AppEnvironment` khi nó có vòng đời deploy và config
   riêng, không chỉ là một URL dev khác.
2. Định nghĩa default và validation trong `lib/core/app/app_config.dart`.
3. Thêm `lib/main_<environment>.dart` tối giản: chỉ chọn environment và gọi
   `bootstrap()`.
4. Thêm lệnh Derry run/build tương ứng, cập nhật CI hoặc release nếu cần.
5. Để cấu hình Firebase/native có secret hoặc signing ngoài source control.
6. Test URL không hợp lệ, production bắt buộc HTTPS và ràng buộc inspector.

Không đọc cấu hình tuỳ tiện từ Widget, Cubit, repository hay data source.
