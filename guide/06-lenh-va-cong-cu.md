# 6. Lệnh và công cụ

Mọi lệnh chạy qua `derry`. Xem đủ bằng `derry ls -d`.

## Hằng ngày

| Lệnh | Việc |
|---|---|
| `derry run dev` | Chạy app môi trường dev (`local`, `staging`, `prod` tương tự) |
| `derry gen` | Sinh code (DI, model JSON, asset) và format |
| `derry quality` | Format, analyzer, gate kiến trúc, test convention, test app và `sli_common` |
| `derry test` | Chỉ chạy test |
| `derry scaffold -- <feature> [--bloc] [--data] --apply` | Sinh khung feature |
| `derry decision search "<chủ đề>"` | Tìm quyết định đã chốt |
| `derry review plan` | Liệt kê file đổi và luật review cho từng file |

## Build và phát hành

Ba luồng tách riêng; luồng ra ngoài đều phải xác nhận.

| Luồng | Lệnh | Ra ngoài? |
|---|---|---|
| Build trên máy | `derry build apk` / `appbundle` / `ipa` | Không |
| Phân phối thử | `derry distribute android` / `ios` / `all` | Firebase App Distribution |
| Lên Store | `derry release android` / `ios` (cần `--confirm-store`) | Google Play, TestFlight |

Chi tiết và cách cấu hình signing: [Derry và build](../docs/guides/use-derry-and-build.md).

## Đo hiệu năng

Chỉ chạy khi cần, trên máy thật với server thật:

| Lệnh | Việc |
|---|---|
| `derry perf run` | Đo mở app và các kịch bản |
| `derry perf diagnose` | Đo kèm chẩn đoán widget chậm |
| `derry perf approve` | Đo lại và lưu làm mốc |

Cần `PERF_USERNAME`, `PERF_PASSWORD` của tài khoản test. Chi tiết:
[đo hiệu năng app](../docs/guides/measure-performance.md) ·
[chuẩn và ngưỡng](../docs/performance/standards.md) ·
[hợp đồng benchmark](../PERFORMANCE.md).

## Công cụ khác

| Công cụ | Việc |
|---|---|
| `derry base doctor` | Kiểm tra identity, native project và `sli_common` của base |
| `derry new -- ...` | Tạo app mới từ base (trang 7) |
| `derry toolkit quality` | Gate riêng của `sli_common` |
| Version Health | Bật báo lỗi, analytics, feature flag khi có Firebase: [hướng dẫn](../docs/guides/enable-version-health.md) |

Tiếp: [Dự án thật và việc còn mở](07-du-an-that.md).
