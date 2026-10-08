# Review theo skill code-review và improve-codebase-architecture của Matt Pocock

- Ngày: 2026-10-08
- Phạm vi code review: `b3b9d76...f4747a2`, tức toàn bộ nhánh `performance-measurement` đã merge vào `main` (8 commit, 61 file)
- Phạm vi kiến trúc: toàn bộ `lib/` (không gồm submodule `sli_common`), cùng `tool/performance` và `tool/review`
- Skill dùng: `~/Documents/Personal/skills/skills/engineering/code-review`, `improve-codebase-architecture`, `codebase-design`
- Cách chạy: ba agent độc lập chạy song song gồm chuẩn code, đúng yêu cầu và kiến trúc. Mọi phát hiện đều được đối chiếu lại với code trước khi ghi vào đây
- Repo chưa có `CONTEXT.md` và `docs/agents/issue-tracker.md` như skill gốc mong đợi. Yêu cầu được lấy từ mô tả PR #1 và các yêu cầu PM nêu trong buổi làm việc

## Phần 1: Code review hai trục

Skill gốc tách hai trục và không xếp hạng chung, để trục này không che lấp trục kia.

### Standards: có tuân thủ chuẩn của repo không

**Vi phạm chuẩn đã ghi trong repo**

1. **`tool/review/plan.dart:11-12` ghi sai cú pháp.** Ghi chú hướng dẫn ghi `--from main`. Parser chỉ nhận `--from=main`, nên chạy theo hướng dẫn sẽ thoát với mã 2. Lỗi này vi phạm luật `docs` trong `tool/review/rules.json`: "Docs, skills and agents match the code and commands that actually exist."
2. **`.claude/commands/perf-check.md:18` cho rằng chỉ cần đặt `API_BASE_URL`.** Runner không chuyển biến này vào app, vì `_secretDefines` chỉ chứa `PERF_USERNAME` và `PERF_PASSWORD`. Kết quả là bước kiểm tra điều kiện qua, nhưng app vẫn gọi `example.com`. Lỗi này vi phạm cùng luật `docs` ở trên.

**Dấu hiệu cần cân nhắc (code smell theo Fowler)**

- **Hàm quá dài và một file đổi vì nhiều lý do.** `tool/performance/run.dart` có 1347 dòng, riêng hàm `run()` khoảng 350 dòng. File trộn cấu hình, điều khiển thiết bị, thử lại, lưu mốc, ghi báo cáo và mã thoát.
- **Một thay đổi phải sửa nhiều chỗ.** Ở `run.dart:178-196`, hàm `record` chép 17 trường sang `results` từng trường một. Mỗi trường mới trong báo cáo phải thêm ở hai nơi.
- **Trạng thái kết quả viết bằng chuỗi trần.** `'PASS'`, `'FAIL'` và `'ERROR'` là chuỗi rời ở khoảng 17 chỗ, trong khi `rating.dart` đã có mẫu tốt hơn là dùng enum.
- **Đi sâu vào dữ liệu lồng nhau ở nhiều nơi.** `_failureOwners` và `_triage` cùng tự đào vào `sample['network']['failures']`.
- **Phụ thuộc vào thứ tự gọi.** `_startup` đọc `config['thresholds']` mà không kiểm tra. Nó chỉ chạy đúng vì `_scenarioGate` đã kiểm tra trường đó từ trước.
- **Che mật khẩu chưa kín.** `_mask` bỏ qua các giá trị ngắn hơn 3 ký tự.
- **File hỗ trợ dùng chung lại phụ thuộc widget riêng của app.** `support/perf_app.dart` import `DeliveryGoButton`.

Các mục đã kiểm tra và khớp: ngưỡng giữa `config.json`, `PERFORMANCE.md` và `standards.md`; mọi lệnh `derry` nhắc trong tài liệu đều có thật.

### Spec: có làm đúng yêu cầu không

**Thiếu hoặc mới làm một phần**

- **"Sửa build Android và iOS".** Android chưa build xong vì máy hết ổ đĩa, nên yêu cầu này vẫn còn mở.
- **"Ngưỡng theo lượng dữ liệu".** Cơ chế đã chạy đúng, nhưng chưa có kịch bản nào truyền `dataSize`. Ngưỡng mẫu duy nhất mang tên `_example_orders_list`, không trùng với kịch bản nào. Nên hiện tại chưa có lần chấm nào dùng ngưỡng theo dữ liệu.
- **"Đo bằng dữ liệu và tài khoản thật".** Khi thiếu `PERF_USERNAME`, kịch bản `app_start` không báo lỗi mà lặng lẽ đo màn đăng nhập (`app_start_test.dart:26-28`). Số đo vẫn ra PASS nhưng không phải cho màn thật.

**Ngoài phạm vi yêu cầu**

- File `docs/brainstorm/2026-10-06-version-health-firebase-observability.md` không thuộc yêu cầu nào trong mười yêu cầu.
- minSdk tăng từ 21 lên 24. Thay đổi này đã được ghi rõ, nhưng không nằm trong yêu cầu "sửa build".

**Đã làm nhưng có chỗ sai**

- **Thông báo lỗi 429 bị hỏng chữ do lệnh thay thế hàng loạt** (`network_errors.dart:76`). Nó ghi "RetryAdvice after the RetryAdvice-After window", trong khi đúng phải là "Retry after the Retry-After window". Chuỗi này hiện ra trong báo cáo cho PM.
- **Bước che bí mật chỉ áp lên log và dòng lệnh.** File JSON báo cáo và `summary.json` không đi qua bước che. Hiện chưa thấy rò rỉ vì config không chứa bí mật và URL đã được rút gọn, nhưng chưa có lớp phòng thủ thứ hai.

Các mục đã kiểm tra và đúng: ngưỡng `targets` riêng có ảnh hưởng tới rating và được gắn nhãn proposed; chỉ bỏ lần đo khi mọi lỗi thuộc mạng hoặc backend; startup tôn trọng `--scenario`; chỉ lưu mốc khi toàn bộ PASS; mốc bằng 0 vẫn được chặn; config được kiểm tra trước khi đụng tới thiết bị; percentile dùng nearest-rank; mỗi kịch bản chỉ build một lần.

### Tóm tắt hai trục

- **Standards:** 2 vi phạm chuẩn ghi trong repo, 7 dấu hiệu cần cân nhắc. Nặng nhất là hướng dẫn `API_BASE_URL` sai, khiến bước kiểm tra điều kiện qua nhầm.
- **Spec:** 3 yêu cầu còn thiếu, 2 thay đổi ngoài phạm vi, 2 chỗ làm sai. Nặng nhất là kịch bản đo nhầm màn đăng nhập khi thiếu tài khoản test mà vẫn ra PASS.

## Phần 2: Cơ hội cải thiện kiến trúc

Thuật ngữ theo `codebase-design`:
- **Module** là bất cứ thứ gì có giao diện và phần cài đặt.
- **Nông** nghĩa là giao diện gần phức tạp bằng phần cài đặt. **Sâu** nghĩa là nhiều hành vi nằm sau một giao diện nhỏ.
- **Seam** là chỗ thay đổi được hành vi mà không cần sửa code tại chỗ đó.
- **Locality** là khi lỗi và thay đổi tập trung ở một nơi.

Báo cáo HTML có sơ đồ trước và sau cho từng mục được ghi ngoài repo, đúng theo skill, tại `$TMPDIR/architecture-review-20261008-085554.html`.

### 1. Gộp vòng đời phiên đăng nhập vào một module sâu (Mạnh)

**File:**
- `lib/domain/use_case/auth_use_case.dart`
- `lib/data/repositories/auth_repo_impl.dart`
- `lib/data/repositories/user_repo_impl.dart`
- `lib/data/datasource/local/token_provider.dart`
- `lib/data/datasource/local/user_local_data_source.dart`
- `lib/data/datasource/local/session_expiry_coordinator.dart`

**Vấn đề:** phiên đăng nhập bị chia ra bảy module, và chỗ chia đó tạo ra lỗi thật. Mình đã đọc code để xác nhận cả ba lỗi đầu:
- **Đăng nhập mà không bật "ghi nhớ" thì không có token.** Khi `isRememberLogin` là false, `login()` không lưu token ở đâu cả (`auth_use_case.dart:28-31`). `AuthInterceptor` đọc `TokenProvider.token` (`auth_interceotor.dart:12-14`), nên các request sau đó không có header `Authorization`.
- **`logout()` không làm gì** (`auth_use_case.dart:75`).
- **Phiên hết hạn thì chỉ xoá token, giữ lại tài khoản** (`session_expiry_coordinator.dart:14`). `clearAccount` không được gọi ở đâu cả, nên Splash vẫn đọc ra tài khoản cũ.
- `setTokenToLocal` và `setAccountToLocal` lặng lẽ bỏ qua dữ liệu không phải model của tầng data, do kiểm tra kiểu lúc chạy.
- Chưa có test cho `AuthRepoImpl`, `UserRepoImpl` và `login()`.

**Hướng sửa:** một module phiên duy nhất nắm token, tài khoản đã lưu, đăng nhập, đăng xuất và hết hạn. Đăng xuất và hết hạn đi chung một đường.

**Lợi ích:**
- Locality: quy tắc "token và tài khoản sống chết cùng nhau" chỉ nằm ở một chỗ.
- Giao diện nhỏ lại: bỏ được bộ ba hàm `setTokenToLocal`, `setAccountToLocal` và `isAppLogin`.
- Test được cả vòng đời qua một giao diện, dùng bộ lưu trữ trong bộ nhớ.

**Loại phụ thuộc:** thay thế được bằng bản local. **ADR:** không xung đột.

### 2. Cổng xác thực số điện thoại trả về một kết quả duy nhất (Mạnh)

**Vấn đề:**
- `PhoneVerificationRepo` báo kết quả qua callback, và Future của nó kết thúc trước khi mã OTP được gửi.
- Năm Cubit (splash, sign_in, sign_up, confirm_information, reset_password) lặp cùng một mẫu: callback, kiểm tra `isClosed`, rồi xử lý lỗi.
- Đoạn chuẩn hoá số điện thoại `+84` bị chép ở ba nơi.

**Hướng sửa:**
- Cổng trả về một kết quả duy nhất: đã gửi mã, tự xác thực, hoặc lỗi.
- Đưa phần chuẩn hoá số điện thoại vào domain.

**Lợi ích:**
- Năm nơi gọi đều đơn giản hơn.
- Ba callback gộp lại thành một kết quả.
- Test bằng adapter giả mà không phải dựng chuỗi callback.

**ADR:** giữ đúng cổng của ADR-0010, chỉ đổi hình dạng của nó.

### 3. Tách `tool/performance/run.dart` (Mạnh)

**Vấn đề:** phần quyết định PASS, FAIL hay ERROR nằm trong các hàm private của script, nên không test được. Cụ thể là `_triage`, `_queue`, logic thử lại, `_sameEnvironment`, `_validate` và phần đọc config.

**Hướng sửa:** chuyển phần thuần logic sang một module test được, giống `gate.dart` và `rating.dart`. `run.dart` chỉ còn điều phối tiến trình và thiết bị.

**Lợi ích:** test chạm được tới các quyết định thật. Logic thử lại nằm cạnh test của nó.

### 4. Bỏ lớp `Injector` và truyền dependency từ composition root (Đáng thử)

**Vấn đề:**
- `Injector` chỉ chuyển tiếp sang `GetIt.instance`.
- `AppColor` và `NoInternetScreen` dùng nó để tự tra dependency. Việc này vi phạm quy tắc constructor injection trong `AGENTS.md`.

**Hướng sửa:** route builder và `MainApp` lấy dependency rồi truyền vào qua constructor.

**ADR:** khớp với ADR-0001.

### 5. Gộp các use case chỉ chuyển tiếp (Thử nghiệm)

**Vấn đề:** `AppUseCase` và `AppRepoImpl` chỉ chuyển lời gọi xuống tầng dưới. Bỏ chúng đi cũng không mất logic nào.

**Lưu ý:** việc này trái với thứ tự tầng mà template cố ý dạy trong `AGENTS.md`. Chỉ ghi nhận ở đây, không đề xuất làm.

### Nên làm trước

**Mục 1.** Đây là mục duy nhất mà thiết kế rời rạc gây ra lỗi đã xác nhận:
- đăng nhập không ghi nhớ thì không có token;
- tài khoản còn sót lại sau khi phiên hết hạn;
- đăng xuất không làm gì.

Cả ba nằm trong phần code chưa có test. Làm xong mục 1 thì mục 2 cũng dễ hơn.

## Việc tiếp theo cho PM

| Ưu tiên | Việc | Loại |
|---|---|---|
| 1 | Sửa ba lỗi phiên đăng nhập, kèm test | Lỗi thật trong luồng chính |
| 2 | Sửa chữ hỏng ở thông báo 429, cú pháp trong ghi chú `plan.dart` và hướng dẫn `API_BASE_URL` | Sửa nhỏ, nhanh |
| 3 | Cho `app_start` báo lỗi khi thiếu tài khoản test, thay vì đo nhầm màn đăng nhập | Sai yêu cầu |
| 4 | Tách `run.dart` thành module test được | Cải thiện kiến trúc |
| 5 | Đổi cổng xác thực số điện thoại sang trả một kết quả | Cải thiện kiến trúc |

Skill `improve-codebase-architecture` dừng ở bước hỏi PM muốn đào sâu mục nào. Chọn một mục thì agent sẽ cùng bạn đi qua các ràng buộc, hình dạng module mới và phần test giữ lại, trước khi code.
