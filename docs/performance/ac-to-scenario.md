# Từ AC tới kịch bản đo hiệu năng

Tài liệu này dành cho agent và cho người duyệt. Nó mô tả cách chuyển một
acceptance criterion (AC) bình thường, không có con số hiệu năng, thành một
kịch bản đo và một bộ ngưỡng đề xuất.

## Quy trình

1. **Đọc AC và tách luồng.** Mỗi AC có hành động của người dùng (mở, bấm,
   cuộn, nhập, gửi) là một luồng có thể đo. AC chỉ mô tả quy tắc nghiệp vụ
   hoặc nội dung hiển thị thì không cần kịch bản đo.
2. **Xác định loại thao tác** theo bảng bên dưới. Một AC có thể gồm nhiều loại,
   ví dụ "mở danh sách rồi cuộn" gồm tải màn hình và cuộn.
3. **Tìm màn hình và widget trong code** để viết kịch bản. Không đoán tên nút.
4. **Đo phần quan trọng nhất của AC** trong `measureScenario`. Phần chuẩn bị,
   như đăng nhập hay đi tới màn, nằm ngoài vùng đo.
5. **Đề xuất ngưỡng** theo bảng mặc định, ghi vào `targets` của file JSON với
   `status: "proposed"` và lý do bằng tiếng Việt.
6. **Chạy thử** và báo số đo đầu tiên cạnh ngưỡng đề xuất. PM duyệt bằng cách
   đổi `status` thành `approved`.

## Ngưỡng mặc định theo loại thao tác

Mốc lấy từ [chuẩn và ngưỡng hiệu năng](standards.md). Đây là điểm khởi đầu;
PM có thể chỉnh khi duyệt.

| Loại thao tác | Dấu hiệu trong AC | Đo chỉ số chính | GOOD | POOR |
|---|---|---|---|---|
| Phản hồi tức thì | bấm nút, chuyển tab, bật tắt, chọn | `scenario_ms` | 100 ms | 1000 ms |
| Chuyển màn | mở màn, quay lại, đi tới chi tiết đã có dữ liệu | `scenario_ms` | 1000 ms | 3000 ms |
| Tải màn từ server | hiển thị danh sách, xem chi tiết, tải dữ liệu | `scenario_ms` theo lượng dữ liệu | 1000 ms cho 50 item, +200 ms mỗi 100 item, trần 2500 ms | gấp đôi GOOD |
| Cuộn danh sách | cuộn, kéo, tải thêm, phân trang | `jank_percent`, `frame_p95_ms` | 5%, 16,67 ms | 25%, 33 ms |
| Nhập liệu và tìm kiếm | gõ, tìm kiếm, lọc | `frame_p95_ms`, `scenario_ms` sau khi gõ xong | 16,67 ms, 1000 ms | 33 ms, 3000 ms |
| Gửi dữ liệu | gửi, lưu, đặt đơn, thanh toán, đăng nhập | `scenario_ms` | 1000 ms | 10000 ms |
| Animation | hiệu ứng, chuyển cảnh, bottom sheet | `jank_percent`, `frame_p99_ms` | 5%, 33 ms | 25%, 700 ms |
| Mở app | khởi động, splash, tự đăng nhập | `startup_first_frame_ms` | 1500 ms | 5000 ms |

Quy tắc chung:

- Chỉ đặt ngưỡng cho chỉ số chính của loại thao tác. Các chỉ số khác dùng mốc
  chung trong `config.json`.
- Có lượng dữ liệu thì dùng `data_budgets` và báo `dataSize` trong kịch bản.
- AC nói rõ "nhanh", "ngay lập tức", "không giật" thì dùng loại chặt hơn.
- AC có con số thì dùng con số đó, ghi `status: "approved"` và trích AC.
- Không chắc thuộc loại nào thì chọn loại lỏng hơn và ghi lý do.

## Ví dụ

AC trong spec, không có con số:

> **AC3:** Người dùng mở tab "Đơn hàng" thì thấy danh sách đơn của mình. Cuộn
> xuống cuối thì tải thêm đơn.

Agent tách thành hai luồng:

| Luồng | Loại | Chỉ số chính |
|---|---|---|
| Mở tab và hiện danh sách | Tải màn từ server | `scenario_ms` theo số đơn |
| Cuộn và tải thêm | Cuộn danh sách | `jank_percent`, `frame_p95_ms` |

File `integration_test/performance/scenarios/orders_open.json`:

```json
{
  "id": "orders_open",
  "description": "Mở tab Đơn hàng và chờ danh sách thật hiện ra",
  "routes": ["/orders"],
  "test": "integration_test/performance/orders_open_test.dart",
  "enabled": true,
  "source": {
    "spec": "docs/specs/012-orders/fe.md",
    "ac": "AC3",
    "text": "Người dùng mở tab Đơn hàng thì thấy danh sách đơn của mình."
  },
  "targets": {
    "status": "proposed",
    "rationale": "AC không có con số. Loại tải màn từ server: 1 giây cho 50 đơn, thêm 0,2 giây mỗi 100 đơn, tối đa 2,5 giây.",
    "data_budgets": {
      "scenario_ms": {
        "items_metric": "data_items",
        "base_ms": 1000,
        "base_items": 50,
        "per_unit_ms": 200,
        "unit": 100,
        "cap_ms": 2500,
        "poor_factor": 2
      }
    }
  }
}
```

File `orders_scroll.json` tương tự, với:

```json
"targets": {
  "status": "proposed",
  "rationale": "AC không có con số. Loại cuộn danh sách: giật tối đa 5%, 95% frame trong 16,67 ms.",
  "bands": {
    "jank_percent": [5.0, 25.0],
    "frame_p95_ms": [16.67, 33.0]
  }
}
```

## Duyệt ngưỡng

- Báo cáo ghi `(proposed targets)` cạnh rating khi ngưỡng chưa được duyệt.
  Rating vẫn được tính để PM thấy ngay kết quả.
- PM duyệt bằng cách đổi `"status": "proposed"` thành `"approved"`, hoặc chỉnh
  con số rồi đổi status.
- Agent không được tự đổi status sang `approved`.
- Ngưỡng `targets` chỉ ảnh hưởng rating. Gate PASS/FAIL vẫn dùng `thresholds`
  và baseline chung.
