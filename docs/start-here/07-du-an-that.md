# 7. Dự án thật và việc còn mở

## Tạo app mới từ base

Không code thẳng trong repo base. Tạo app mới:

```bash
# Xem trước những gì sẽ đổi
derry new -- --destination ../my_app --display-name "My App" \
  --package-name my_app --bundle-id com.company.my_app

# Đồng ý thì chạy thật
derry new -- --destination ../my_app --display-name "My App" \
  --package-name my_app --bundle-id com.company.my_app --apply
```

App mới có một commit đầu sạch, đã đổi package, bundle id, tên app, và giữ
`sli_common` là submodule.

## Việc trong tuần đầu của app mới

| # | Việc | Ở đâu |
|---|---|---|
| 1 | Đổi địa chỉ server | `lib/core/app/app_config.dart` hoặc `--dart-define=API_BASE_URL=...` |
| 2 | Firebase của app (3 flavor), signing, icon, splash | [Tạo app từ base](../guides/create-app-from-base.md) |
| 3 | Thay luồng đăng nhập mẫu bằng luồng thật | Sửa luôn `integration_test/performance/support/perf_app_adapter.dart` |
| 4 | Chạy thử trên máy thật, chạy `build_store` của fastlane một lần | [Sổ tay dự án thật](../guides/start-real-project.md) |

## Việc còn mở trong base

Chỉ ghi ở một nơi: [sổ tay dự án thật, mục 5](../guides/start-real-project.md#5-việc-còn-mở-trong-base).
Xong việc nào thì đánh dấu và ghi commit ở đó. Lịch sử thay đổi:
[CHANGELOG](../../CHANGELOG.md).

Quay lại: [mục lục Bắt đầu từ đây](README.md).
