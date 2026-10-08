# Đo hiệu năng app

Hướng dẫn này dành cho người muốn đo hiệu năng app mà không cần biết code đo
chạy thế nào. Tài liệu kỹ thuật đầy đủ nằm ở [PERFORMANCE.md](../../PERFORMANCE.md)
và [tool/performance/README.md](../../tool/performance/README.md).

## Repo đang có gì

| Thành phần | Dùng để làm gì | Vị trí |
|---|---|---|
| Lệnh `derry perf run` | Đo thời gian mở app và từng kịch bản trên điện thoại thật | [tool/performance/run.dart](../../tool/performance/run.dart) |
| Lệnh `derry perf diagnose` | Đo kèm một lần chẩn đoán, chỉ ra widget nào tốn thời gian nhất | Cùng runner |
| Lệnh `derry perf approve` | Đo lại và lưu kết quả làm mốc so sánh | Cùng runner |
| Cấu hình ngưỡng | Mốc GOOD/POOR, ngưỡng theo lượng dữ liệu, số lần đo, đo lại khi lỗi mạng | [tool/performance/config.json](../../tool/performance/config.json) |
| Kịch bản đo | Mỗi kịch bản là một luồng thao tác tự động trên app thật | [integration_test/performance/](../../integration_test/performance/) |
| Kịch bản mặc định `app_start` | Mở app, khôi phục phiên hoặc đăng nhập tài khoản test, tới màn đầu tiên | [app_start_test.dart](../../integration_test/performance/app_start_test.dart) |
| Agent đo hiệu năng | Đo, tìm nguyên nhân, viết phiếu bàn giao, kiểm tra lại sau khi sửa | [perf-tester.md](../../.agents/agents/perf-tester.md) |
| Agent sửa hiệu năng | Đọc phiếu, sửa đúng một nguyên nhân, tự kiểm tra | [perf-engineer.md](../../.agents/agents/perf-engineer.md) |
| Quy trình hai agent | Cách hai agent trao đổi và mẫu báo cáo cho PM | [agent-loop.md](../performance/agent-loop.md) |

## Đo những gì

| Nhóm | Chỉ số | Ý nghĩa dễ hiểu |
|---|---|---|
| Mở app | Thời gian tới frame đầu tiên | Bấm icon bao lâu thì thấy app |
| Độ mượt | Frame p95, p99, tỉ lệ jank | Cuộn và chuyển màn có bị giật không |
| Tốc độ thao tác | Thời gian chạy hết kịch bản | Một luồng thao tác mất bao lâu |
| Bộ nhớ | Bộ nhớ cuối kịch bản và mức tăng | Dùng lâu có bị phình bộ nhớ, rò rỉ không |
| Mạng | Số request, request lỗi, thời gian p95, dung lượng tải về, API chậm nhất | App chậm do app hay do server |
| Chẩn đoán | Widget tốn thời gian nhất | Lỗi nằm ở đoạn giao diện nào |

Mỗi lần đo được chấm hai kiểu:

- **Gate PASS/FAIL**: có tệ hơn mốc đã duyệt hoặc vượt ngưỡng cứng không.
- **Rating GOOD / NEEDS_IMPROVEMENT / POOR**: trải nghiệm tốt đến đâu, dựa trên
  chuẩn công khai của Android vitals và Nielsen. Bảng mốc và giải thích bằng
  tiếng Việt nằm trong [chuẩn và ngưỡng hiệu năng](../performance/standards.md).

Chưa đo: CPU, hiệu năng trên máy người dùng thật sau khi phát hành.

## Chuẩn bị một lần cho mỗi máy

1. **Cài đặt project như bình thường.** Làm theo
   [điều kiện dự án](../prerequisites.md) rồi chạy `derry bootstrap`. Kiểm tra
   máy bằng `derry quality`.
2. **Để trống ít nhất 10 GB ổ đĩa.** Build bản profile cho Android cần nhiều
   chỗ trống. Thiếu chỗ thì build dừng với lỗi `No space left on device`.
3. **Chuẩn bị một tài khoản test riêng** trên server `dev` hoặc `staging`. Các
   kịch bản dùng dữ liệu thật, không dùng dữ liệu giả. Đừng dùng tài khoản này
   cho việc khác để dữ liệu ổn định giữa các lần đo.
4. **Khai báo tài khoản test trong terminal.** Giá trị không nằm trong repo và
   hiện thành `***` trong mọi log, báo cáo.

   ```bash
   export PERF_USERNAME=0900000000
   export PERF_PASSWORD='mat-khau-tai-khoan-test'
   ```

   Muốn giữ lâu dài thì thêm hai dòng trên vào `~/.zshrc`.
5. **Kiểm tra địa chỉ server.** `lib/core/app/app_config.dart` cần trỏ tới
   server thật của flavor `dev`. Địa chỉ mẫu `api.dev.example.com` sẽ làm đăng
   nhập thất bại.

## Đo lần đầu

1. **Cắm một điện thoại Android hoặc iPhone thật** và mở khoá màn hình.
   Emulator và simulator không cho số liệu đáng tin. Nên dùng máy Android tầm
   trung, gần với máy người dùng.
2. **Kiểm tra máy đã được nhận.**

   ```bash
   fvm flutter devices
   ```

   Nếu cắm nhiều máy, chọn một máy:

   ```bash
   export FLUTTER_PERF_DEVICE=<id-của-máy>
   ```

3. **Chạy đo.**

   ```bash
   derry perf run
   ```

   Lần đầu mất vài phút vì phải build bản profile. Điện thoại sẽ tự mở app, tự
   bấm, tự cuộn. Không cần chạm vào máy trong lúc đo.
4. **Đọc kết quả** trong `performance/latest/summary.md`. File này có bảng PASS
   hoặc FAIL, rating, request lỗi theo từng bên, API chậm nhất và các kịch bản
   cần đo lại.
5. **Lưu mốc khi thấy kết quả ổn.** Những lần đo sau sẽ so với mốc này.

   ```bash
   derry perf approve
   ```

   Sau đó commit thư mục `performance/baselines/` nếu muốn cả team dùng chung
   mốc.

## Các lần đo sau

| Bạn muốn | Chạy |
|---|---|
| Đo lại toàn bộ | `derry perf run` |
| Đo một kịch bản | `dart run tool/perf.dart --scenario=app_start` |
| Biết widget nào làm chậm | `derry perf diagnose` |
| Chạy lại kịch bản bị lỗi mạng hôm trước | Xem lệnh trong mục "Waiting for a re-run" của `summary.md` |
| Lưu kết quả mới làm mốc | `derry perf approve` |

Chỉ so sánh được khi dùng cùng điện thoại, cùng flavor và cùng phiên bản
Flutter. Runner tự từ chối nếu mốc được đo trong môi trường khác.

## Để agent làm thay

Trong Claude Code có sẵn hai lệnh:

| Lệnh | Agent làm gì |
|---|---|
| `/perf-check` | Kiểm tra điều kiện, chạy đo, tìm nguyên nhân, sửa, đo lại và viết báo cáo tiếng Việt cho PM |
| `/perf-check màn danh sách đơn` | Như trên nhưng chỉ cho màn hoặc luồng được nêu, tự viết kịch bản nếu chưa có |
| `/perf-scenario mở danh sách đơn, cuộn tới cuối, mở đơn cuối` | Chỉ viết kịch bản đo từ mô tả bằng lời rồi chạy thử |
| `/perf-scenario docs/specs/012-orders/fe.md AC3` | Đọc AC trong spec, tách luồng, viết kịch bản và đề xuất ngưỡng theo loại thao tác |

Với agent khác, bạn chỉ cần làm phần chuẩn bị, cắm máy, rồi nói:

```text
Kiểm tra performance app
```

hoặc

```text
Đo lại màn danh sách đơn hàng
```

Agent đo hiệu năng sẽ chạy đo, viết kịch bản cho màn chưa có, tìm nguyên nhân
và giao cho agent sửa. Sau khi sửa, nó đo lại để xác nhận. Bạn đọc báo cáo
trong `docs/performance/` và quyết định các việc chỉ bạn quyết được: lưu mốc
mới, đánh đổi trải nghiệm, hoặc chuyển lỗi server cho backend. Chi tiết ở
[agent-loop.md](../performance/agent-loop.md).

## Đọc kết quả

| Bạn thấy | Nghĩa là | Việc tiếp theo |
|---|---|---|
| `PASS` và `GOOD` | Đạt chuẩn và không tệ hơn mốc | Không cần làm gì |
| `PASS` nhưng `NEEDS_IMPROVEMENT` hoặc `POOR` | Không tệ hơn trước, nhưng chưa đạt chuẩn trải nghiệm | Lên kế hoạch tối ưu |
| `FAIL` kèm `regression +12%` | Tệ hơn mốc đã duyệt | Chạy `derry perf diagnose` để tìm nguyên nhân |
| `FAIL` kèm `frame_count < 20` | Kịch bản quá ngắn để tính đúng | Kéo dài kịch bản, ví dụ cuộn nhiều hơn |
| Request lỗi thuộc `mobile` | App gửi request sai | Sửa app |
| Request lỗi thuộc `backend` | Server lỗi hoặc giới hạn tần suất | Báo backend, đo lại sau |
| Request lỗi thuộc `environment` | Tài khoản test, địa chỉ server hoặc chứng chỉ sai | Kiểm tra phần chuẩn bị |
| `ERROR` | Không đo được | Đọc `log_tail` trong `summary.json` |
| API có nhãn `(slow)` | Request đó chậm hơn 1 giây | Thường là việc của backend |

## Lỗi thường gặp

| Thông báo | Cách xử lý |
|---|---|
| `No Android/iOS device connected` | Cắm máy thật, mở khoá, chạy `fvm flutter devices` để kiểm tra |
| `Select a device with FLUTTER_PERF_DEVICE` | Đang cắm nhiều máy. Đặt `FLUTTER_PERF_DEVICE` |
| `Nothing to measure` | Chưa có kịch bản nào được bật |
| `Set PERF_USERNAME and PERF_PASSWORD` | Chưa khai báo tài khoản test ở bước chuẩn bị |
| `No space left on device` | Dọn ổ đĩa. Cache Gradle nằm ở `~/.gradle/caches` |
| `baseline ... differs` | Đổi máy, flavor hoặc Flutter từ lần lưu mốc. Đo lại rồi duyệt mốc mới |

## Thêm kịch bản cho màn mới

Bạn không cần tự viết kịch bản, kể cả khi AC không có con số hiệu năng. Agent
phân loại thao tác trong AC và đề xuất ngưỡng; bạn chỉ duyệt. Chi tiết ở
[từ AC tới kịch bản](../performance/ac-to-scenario.md).

Cách khác: Chạy `/perf-scenario` kèm mô tả thao tác, agent
sẽ đọc code màn hình, viết kịch bản, chạy thử và báo số liệu đầu tiên.

Runner luôn in danh sách màn chưa có kịch bản ở dòng `Routes without enabled
scenarios`. Cách viết kịch bản nằm trong
[tool/performance/README.md](../../tool/performance/README.md#add-a-scenario).
Nếu dùng agent, chỉ cần mô tả thao tác, ví dụ "mở danh sách đơn, cuộn tới cuối,
mở đơn cuối cùng". Agent sẽ tự viết kịch bản.

## Quy tắc không được phá

- Không đo sau mỗi lần sửa code. Chỉ đo khi được yêu cầu hoặc khi sửa phần ảnh
  hưởng hiệu năng.
- Không lưu mốc mới để che việc app chậm đi.
- Không nới ngưỡng hay tắt kịch bản để qua bài đo.
- Không đo trên emulator, simulator hay ở chế độ debug.
