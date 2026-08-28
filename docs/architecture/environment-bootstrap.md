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
