# Vòng giao việc giữa agent dev và agent test

Tài liệu này mô tả cách `flutter-dev` và `flutter-tester` phối hợp để biến
một yêu cầu thành code đúng convention, đã được kiểm tra độc lập. PM chỉ đưa
yêu cầu và đọc báo cáo cuối.

```text
PM: đưa tài liệu (spec, AC, PRD, thiết kế)
 └─ flutter-dev
      đọc sổ quyết định → viết tech.md → chờ PM duyệt
 └─ PM duyệt hoặc chỉnh tech.md và các quyết định đề xuất
 └─ flutter-dev
      scaffold → code → derry quality → tự review → cập nhật sổ quyết định
      ghi phần Dev trong phiếu bàn giao
       └─ flutter-tester
            viết test nghiệm thu từ AC trước khi đọc code
            chức năng + convention (+ bảo mật, hiệu năng khi cần)
            FAIL → phiếu quay lại flutter-dev (tối đa 3 vòng)
            PASS → báo cáo cho PM
PM: đọc báo cáo, quyết định đánh đổi nếu có
```

## Thiết kế kỹ thuật trước khi code

Tài liệu đưa vào đã chốt nghiệp vụ. `flutter-dev` chỉ quyết phần kỹ thuật và
ghi vào `docs/specs/<id>-<feature>/tech.md` theo mẫu của skill `tech-design`:
file nào, class và trường tên gì, đặt ở đâu, state và effect, API, lưu trữ,
test, ngưỡng hiệu năng, quyết định dùng lại và quyết định mới. PM duyệt hoặc
chỉnh file này trước khi có dòng code nào. Chỗ tài liệu chưa rõ về nghiệp vụ
được liệt kê để PM trả lời, không tự đoán.

## Sổ quyết định

Mọi lựa chọn kỹ thuật có thể lặp lại được ghi vào `docs/decisions/` (cấp tính
năng) hoặc `docs/adr/` (cấp dự án), và tra bằng
`python3 tool/decisions/decisions.py search "<chủ đề>"`. Tính năng sau phải
làm giống quyết định đã `accepted`; muốn khác thì tạo quyết định mới thay thế.
Tên khái niệm nghiệp vụ thống nhất nằm trong `docs/decisions/glossary.md`.
Cách dùng: [docs/decisions/HOW-TO.md](../decisions/HOW-TO.md).

## Kiểm soát convention

Convention được giữ bằng ba lớp, từ sớm đến muộn:

| Lớp | Cách hoạt động | Ai bị chặn |
|---|---|---|
| Scaffold | `dart run tool/scaffold/feature.dart <feature> --apply` sinh khung feature đã đúng convention | Agent dev không phải tự viết khung |
| Luật tự động | `test/convention/convention_test.dart` quét `lib/`, chạy trong `derry quality` và CI | Mọi code lệch tên file, tên class, vị trí file, annotation DI, cấu trúc state, thiếu test |
| Review có luật | `derry review plan` gắn luật theo tầng cho từng file thay đổi | Những gì luật tự động không đo được, như logic và cách đặt tên biến |

Code cũ có trước luật nằm trong `tool/convention/baseline.txt`. File này chỉ
được bớt dòng khi sửa code cũ, không bao giờ được thêm dòng cho code mới.

## Phiếu bàn giao

Lưu ở `docs/handoffs/YYYY-MM-DD-hh-mm-<topic>.md`.

```markdown
# <topic>

Status: OPEN | DEV_DONE | PASS | FAIL | ESCALATED
Round: 1
Spec: docs/specs/<id>/fe.md

## Dev (flutter-dev)
- Files: danh sách đường dẫn
- Scaffold: lệnh đã chạy
- derry quality: kết quả
- Tự review: số file đã review / tổng
- Ghi chú cho tester

## Test (flutter-tester)
### Chức năng
| AC | Test | Kết quả |
|---|---|---|
### Convention
- derry quality, độ phủ review, baseline có tăng không
### Bảo mật / Hiệu năng (nếu chạy)
### Findings
- F1 file:line, luật hoặc test fail, điều kiện "xong khi"
### Kết luận: PASS | FAIL
```

## Báo cáo cho PM

Viết bằng tiếng Việt, ngắn:

```markdown
# <tính năng>: PASS | FAIL | CẦN QUYẾT ĐỊNH

| AC | Trạng thái |
|---|---|
| AC1 ... | Đạt |

Đã làm: một câu mỗi phần chính.
Cần bạn quyết: đánh đổi, AC chưa rõ, việc phía backend.
Chưa kiểm chứng: những gì cần máy thật hoặc server thật.
```

## Quy tắc điều phối

- Orchestrator gọi `flutter-dev` trước, rồi `flutter-tester` trong một
  subagent riêng để tester không thấy suy luận của dev.
- Hai agent chỉ trao đổi qua phiếu bàn giao.
- Tester viết test nghiệm thu trước khi đọc code của dev.
- Dừng sau ba vòng FAIL cho cùng một finding và báo PM.
- Việc chỉ về hiệu năng vẫn dùng vòng `perf-tester` và `perf-engineer` trong
  `docs/performance/agent-loop.md`.
