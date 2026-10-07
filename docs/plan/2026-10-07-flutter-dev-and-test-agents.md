---
title: Agent dev Flutter và agent test khép kín
source: thảo luận ngày 2026-10-07 về vòng agent hiệu năng, open-code-review và security-audit-skill
scope: .agents/agents, .agents/skills, tool/review, docs
date: 2026-10-07
status: đang triển khai; PM đã duyệt ngày 2026-10-07
---

# Plan: Agent dev Flutter và agent test khép kín

## Bối cảnh và mục tiêu

PM muốn base tự nhận tài liệu yêu cầu và trả về tính năng đã code, đã kiểm
tra, kèm báo cáo dễ đọc. Người chỉ cần đưa tài liệu, cắm máy khi cần đo, và
đọc báo cáo.

Base đã có các mảnh rời: `spec-analyze`, `plan-writer`, `spec-implement`,
agent `pm`, `coder`, `flutter-engineer`, `reviewer`, và vòng hiệu năng
`perf-tester` với `perf-engineer`. Thứ còn thiếu là một vòng khép kín cho mọi
loại việc, giống vòng hiệu năng:

```text
Tài liệu → flutter-dev (phân tích → plan → code → tự kiểm tra)
         → flutter-tester (chức năng, convention, bảo mật, hiệu năng)
         → FAIL: phiếu bàn giao quay lại flutter-dev, tối đa 3 vòng
         → PASS: báo cáo cho PM
```

## Quyết định đã thống nhất

- Một agent dev duy nhất `flutter-dev` thay cho `coder` và `flutter-engineer`.
- Một agent test duy nhất `flutter-tester` kiểm tra mọi mặt. `perf-tester`
  trở thành chế độ hiệu năng của agent này.
- Hai agent tách quyền: dev không sửa test chấp nhận, ngưỡng hay baseline;
  tester không sửa code trong `lib/`.
- Trao đổi chỉ qua phiếu bàn giao trong `docs/handoffs/`, như vòng hiệu năng.
- Lấy có chọn lọc từ `cloudflare/security-audit-skill` (MIT): phần mobile,
  deep link, WebView, lưu trữ token và quy tắc mỗi finding phải có bằng chứng.
  Không cài nguyên bộ.
- Lấy ý tưởng của `alibaba/open-code-review` (Apache-2.0), không nhúng CLI:
  code quyết định file nào cần review và luật nào áp cho file đó, agent chỉ làm
  phần suy luận.

## Ngoài phạm vi

- Nhúng CLI `ocr` hoặc gọi LLM bên ngoài.
- Chạy toàn bộ sáu pha audit bảo mật với sandbox của Cloudflare.
- CI chạy agent tự động trên mỗi PR.
- Thay đổi kiến trúc app, DI hay state management.

## Công việc

### Đợt 1: Nền tảng review có tính xác định

- [x] **T1. Script chọn file và luật review.** Owner: flutter-dev.
  - Tạo `tool/review/plan.dart`. Đầu vào: `--from`, `--to` hoặc workspace.
    Đầu ra JSON: danh sách file thay đổi, file bị loại kèm lý do (generated,
    lock, asset), và luật áp cho từng file theo tầng (domain, data,
    presentation, DI, test, native, docs).
  - Luật đọc từ `tool/review/rules.json`, map glob sang đoạn luật lấy từ
    `project-convention` và skill tầng tương ứng.
  - Verify: unit test trong `test/tool/review/` cho phân loại tầng, loại file
    generated và ghép luật; `derry quality` xanh.
  - Kết quả: `tool/review/plan.dart`, `tool/review/review_plan.dart`,
    `tool/review/rules.json`, lệnh `derry review plan`, 5 unit test.
- [x] **T2. Nâng cấp `flutter-code-review`.** Owner: flutter-dev.
  - Bước đầu tiên luôn là chạy `tool/review/plan.dart`, tạo checklist từ danh
    sách file và review từng file với luật của nó. Không được bỏ file nào.
  - Mỗi finding phải qua một bước tự bác bỏ trước khi báo.
  - Verify: review thử một diff mẫu có lỗi đã biết và ghi kết quả vào
    `docs/reviews/`.
  - Kết quả: skill đã có bước lập kế hoạch, bước tự bác bỏ và báo cáo độ phủ.
    Review thử còn chờ làm trong pilot T7.

### Đợt 2: Bảo mật mobile

- [x] **T3. Nâng cấp `mobile-security-privacy`.** Owner: flutter-dev.
  - Thêm `references/mobile-attack-classes.md` chuyển thể từ
    `DESKTOP-MOBILE-AND-LOCAL-IPC.md` cho Flutter: deep link và callback,
    WebView và JS bridge, exported component trong AndroidManifest, keychain và
    keystore, dữ liệu còn lại sau logout hoặc đổi tài khoản.
  - Thêm ba mức kết luận `confirmed`, `needs_validation`, `rejected` và thang
    severity của Cloudflare. Ghi nguồn và giấy phép MIT.
  - Verify: chạy skill trên repo hiện tại, kết quả nằm ở `docs/reviews/`.
  - Kết quả: `references/mobile-attack-classes.md` và chuẩn finding mới trong
    `SKILL.md`. Lần chạy thử trên repo còn chờ làm trong pilot T7.

### Đợt 3: Hai agent

- [ ] **T4. Agent `flutter-dev`.** Owner: PM duyệt nội dung.
  - Gộp `coder.md` và `flutter-engineer.md` thành `.agents/agents/flutter-dev.md`.
  - Luồng: đọc tài liệu → `spec-analyze` → `plan-writer` → `spec-implement`
    theo checklist → tự kiểm tra (`derry gen`, `derry quality`, test của phần
    vừa sửa) → điền phần Dev trong phiếu → gửi `flutter-tester`.
  - Chọn skill theo việc dựa trên `docs/guides/mobile-engineering-skills.md`.
  - Giữ `coder.md` và `flutter-engineer.md` dưới dạng chuyển hướng một dòng để
    không gãy tham chiếu cũ.
- [ ] **T5. Agent `flutter-tester`.** Owner: PM duyệt nội dung.
  - Đổi `perf-tester.md` thành `.agents/agents/flutter-tester.md` với bốn chế
    độ: chức năng, convention, bảo mật, hiệu năng. Chế độ hiệu năng giữ nguyên
    nội dung hiện tại.
  - Chức năng: đọc acceptance criteria trong spec, viết widget hoặc
    integration test chấp nhận trong `test/acceptance/` trước khi đọc code của
    dev, chạy và báo kết quả.
  - Convention: chạy `tool/review/plan.dart` và `flutter-code-review`.
  - Bảo mật: chạy `mobile-security-privacy` khi thay đổi chạm tới auth, token,
    lưu trữ, log, deep link, WebView hoặc manifest.
  - Không sửa `lib/`. Không sửa test của dev; test chấp nhận do tester sở hữu.
- [ ] **T6. Quy trình điều phối.** Owner: flutter-dev.
  - Tạo `docs/agents/delivery-loop.md`: sơ đồ vòng, mẫu phiếu
    `docs/handoffs/YYYY-MM-DD-hh-mm-<topic>.md`, mẫu báo cáo PM, giới hạn ba
    vòng, khi nào phải hỏi PM.
  - Đổi `docs/performance/agent-loop.md` thành một chế độ của quy trình chung.
  - Cập nhật bảng agent trong `AGENTS.md`, `ai-process.md`,
    `docs/guides/mobile-engineering-skills.md` và `docs/README.md`.

### Đợt 4: Chạy thử

- [ ] **T7. Pilot một feature nhỏ.** Owner: PM chọn feature.
  - Đưa một spec thật qua toàn bộ vòng. Ghi lại số vòng, lỗi tester bắt được,
    thời gian, và chỗ agent phải hỏi PM.
  - Verify: báo cáo pilot trong `docs/reviews/`, chỉnh agent theo kết quả.

## Rủi ro

| Rủi ro | Cách giảm |
|---|---|
| Agent dev và tester cùng mô hình nên cùng điểm mù | Tester viết test chấp nhận từ spec trước khi đọc code; finding phải qua bước tự bác bỏ |
| Vòng sửa không dừng | Tối đa ba vòng cho mỗi finding, sau đó báo PM |
| Gộp agent làm gãy hướng dẫn cũ | Giữ file chuyển hướng, cập nhật mọi tham chiếu trong cùng thay đổi |
| Skill quá dài làm agent bỏ sót | Tách nội dung chi tiết sang `references/`, `SKILL.md` chỉ giữ quy trình |
| Nội dung từ repo ngoài sai giấy phép | Ghi nguồn và giấy phép trong từng file chuyển thể |

## Definition of Done

- T1 đến T6 xong, `derry quality` xanh, test mới cho `tool/review/` qua.
- `AGENTS.md`, `ai-process.md` và `docs/README.md` trỏ tới hai agent mới.
- Pilot T7 chạy hết vòng và có báo cáo.
- Không còn tham chiếu nào tới tên agent cũ ngoài file chuyển hướng.
