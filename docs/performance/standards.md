# Chuẩn và ngưỡng hiệu năng

Tài liệu này giải thích bằng tiếng Việt các mốc dùng để chấm hiệu năng app,
mỗi mốc lấy từ đâu và chỉnh ở đâu. Giá trị thật nằm trong
[tool/performance/config.json](../../tool/performance/config.json). Khi sửa
config, hãy sửa bảng ở đây cho khớp.

## Hai kiểu chấm

Mỗi lần đo được chấm hai lần, vì hai câu hỏi khác nhau.

| Kiểu | Trả lời câu hỏi | Kết quả | Nằm trong config |
|---|---|---|---|
| Gate | App có tệ hơn lần trước không? | PASS hoặc FAIL | `thresholds` |
| Rating | Trải nghiệm có đạt chuẩn ngành không? | GOOD, NEEDS_IMPROVEMENT hoặc POOR | `bands`, `data_budgets` |

Ví dụ: màn danh sách luôn mất 3 giây. Gate vẫn PASS vì không tệ hơn trước.
Rating là POOR vì 3 giây là quá lâu. Nghĩa là app không tệ đi, nhưng vẫn cần
tối ưu.

## Rating: mốc chuẩn ngành

Giá trị bằng hoặc dưới cột GOOD là đạt. Lớn hơn cột POOR là kém. Ở giữa là
NEEDS_IMPROVEMENT, tức chấp nhận được nhưng nên cải thiện.

| Chỉ số | Đo gì | GOOD | POOR | Lấy từ đâu |
|---|---|---|---|---|
| `startup_first_frame_ms` | Bấm icon tới lúc thấy frame đầu tiên | ≤ 1500 ms | > 5000 ms | Android vitals coi cold start từ 5 giây là quá chậm |
| `frame_p95_ms` | 95% frame vẽ xong trong thời gian này | ≤ 16,67 ms | > 33 ms | 16,67 ms là một frame ở 60 Hz. 33 ms là hai frame, mắt thấy giật |
| `frame_p99_ms` | 99% frame vẽ xong trong thời gian này | ≤ 33 ms | > 700 ms | Android vitals gọi frame trên 700 ms là frame bị đơ |
| `jank_percent` | Tỉ lệ frame chậm hơn 16,67 ms | ≤ 5% | > 25% | Chặt hơn mốc 50% của Google Play cho slow rendering |
| `scenario_ms` | Tổng thời gian một thao tác, gồm cả gọi mạng | ≤ 1000 ms | > 10000 ms | Nielsen: dưới 1 giây người dùng không mất mạch suy nghĩ, trên 10 giây họ bỏ đi làm việc khác |
| `network_p95_ms` | 95% request trả về trong thời gian này | ≤ 1000 ms | > 3000 ms | Áp mốc 1 giây của Nielsen cho từng request |

Ba mốc nền tảng của Nielsen, dùng để suy ra nhiều mốc ở trên:

| Thời gian | Người dùng cảm thấy |
|---|---|
| 0,1 giây | Phản hồi tức thì, như đang chạm trực tiếp |
| 1 giây | Thấy có chờ, nhưng vẫn giữ mạch thao tác |
| 10 giây | Mất tập trung, cần thanh tiến trình và nút huỷ |

## Rating theo lượng dữ liệu

Dữ liệu thật thay đổi theo thời gian. Màn có nhiều dữ liệu hơn được phép chậm
hơn một chút, nhưng có giới hạn. Mỗi kịch bản có thể có ngưỡng riêng trong
`data_budgets`.

Công thức:

```text
Mốc GOOD = mốc gốc + thời gian thêm × (số item vượt mức gốc ÷ đơn vị), không vượt mức trần
Mốc POOR = Mốc GOOD × hệ số
```

Ví dụ mẫu `_example_orders_list` trong config:

| Thiết lập | Giá trị | Nghĩa |
|---|---|---|
| `base_ms` | 1000 | Thời gian cho phần dữ liệu gốc |
| `base_items` | 50 | Phần dữ liệu gốc là 50 đơn |
| `per_unit_ms` | 200 | Mỗi đơn vị dữ liệu thêm được cộng 200 ms |
| `unit` | 100 | Một đơn vị là 100 đơn |
| `cap_ms` | 2500 | Dù nhiều dữ liệu đến đâu cũng không quá 2,5 giây |
| `poor_factor` | 2 | POOR bắt đầu từ gấp đôi mốc GOOD |

| Số đơn tải về | GOOD nếu dưới | POOR nếu trên |
|---:|---:|---:|
| 20 | 1,0 giây | 2,0 giây |
| 250 | 1,4 giây | 2,8 giây |
| 2000 | 2,5 giây | 5,0 giây |

Khi đã chạm mức trần mà vẫn chậm, cách sửa đúng là phân trang hoặc tải dần,
không phải cho thêm thời gian.

## Ngưỡng riêng cho từng kịch bản

Mỗi kịch bản có thể có `targets` riêng trong file JSON của nó, ghi đè mốc
chung ở trên. Khi AC không có con số, agent đề xuất ngưỡng theo loại thao tác
và để trạng thái `proposed` cho tới khi PM duyệt. Bảng ngưỡng theo loại thao
tác nằm ở [từ AC tới kịch bản](ac-to-scenario.md).

## Gate: chặn app tệ đi

Gate FAIL khi vượt một ngưỡng cứng, hoặc khi tệ hơn mốc đã duyệt quá mức cho
phép.

| Ngưỡng | Mặc định | Lý do |
|---|---|---|
| `max_jank_percent` | 3% | Ngưỡng cứng cho độ mượt |
| `max_frame_p95_ms` | 20 ms | Cho phép dao động nhẹ quanh một frame 60 Hz |
| `max_frame_p99_ms` | 32 ms | Khoảng hai frame |
| `max_scenario_ms` | 15000 ms | Nới rộng vì đo bằng mạng thật |
| `max_first_frame_ms` | 2000 ms | Ngưỡng cứng cho mở app |
| `max_network_failures` | 0 | Có request lỗi thì app đang hiện màn lỗi, số đo không còn đúng |
| `max_regression_percent` | 5% | Tệ hơn mốc trên 5% là FAIL |
| `zero_baseline_regression_delta` | Ví dụ jank +0,5 điểm | Khi mốc bằng 0 thì không tính được phần trăm, nên dùng mức tăng tuyệt đối |
| `min_frame_count` | 20 frame | Ít hơn thì p95 và p99 không còn ý nghĩa |

## Request lỗi: ai phải xử lý

Phân loại theo chuẩn HTTP RFC 9110. Mã 4xx nghĩa là request sai. Mã 5xx nghĩa
là server hỏng.

| Bên | Lỗi thường gặp | Runner làm gì |
|---|---|---|
| Mạng | Timeout, mất kết nối, mã 408 | Bỏ lần đo, chờ `retry.delay_seconds` rồi đo lại |
| Backend | Mã 5xx, mã 429 | Bỏ lần đo và đo lại. Lỗi kéo dài thì ghi vào báo cáo cho backend |
| Mobile | Mã 400, 404, 405, 409, 422, gọi API cần đăng nhập khi chưa đăng nhập | Giữ kết quả FAIL. Giao cho agent dev sửa |
| Môi trường | Mã 401, 403 khi đã đăng nhập, lỗi DNS, lỗi chứng chỉ | Giữ kết quả FAIL. Kiểm tra tài khoản test và địa chỉ server |

Mỗi kịch bản được bỏ tối đa `retry.max_extra_runs` lần đo, mặc định 3 lần.
Nếu vẫn thiếu lần đo hợp lệ, kịch bản được ghi vào `performance/pending.json`
để chạy lại sau.

## Thiết lập khác trong config

| Thiết lập | Mặc định | Ý nghĩa |
|---|---|---|
| `flavor` | `dev` | Môi trường và server được dùng để đo |
| `runs` | 5 | Số lần đo tính kết quả, lấy trung vị |
| `warmup_runs` | 1 | Số lần chạy làm nóng, không tính |
| `startup.runs` | 3 | Số lần đo mở app |
| `retry.delay_seconds` | 30 | Thời gian chờ trước khi đo lại do lỗi mạng |
| `diagnose_on_failure` | true | Tự chạy chẩn đoán widget khi FAIL |

## Khi nào nên đổi ngưỡng

- Đổi khi sản phẩm có lý do rõ: app chạy trên máy rất yếu, màn hình 120 Hz cần
  chặt hơn, hoặc một luồng nghiệp vụ vốn dài.
- Ghi lý do vào commit và cập nhật bảng trong tài liệu này.
- Không đổi để làm một lần đo đang FAIL thành PASS.

## Nguồn

- [Android vitals: thời gian mở app](https://developer.android.com/google/play/vitals/launch-time)
- [Android: slow rendering và frozen frames](https://developer.android.com/topic/performance/vitals/render)
- [Nielsen Norman Group: Response Time Limits](https://www.nngroup.com/articles/response-times-3-important-limits/)
- [RFC 9110: HTTP Semantics](https://httpwg.org/specs/rfc9110.html)
