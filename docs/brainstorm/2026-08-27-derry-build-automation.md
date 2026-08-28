# Brainstorm: Hợp nhất Derry, build.sh và Fastlane

**Type:** refactor
**Date:** 2026-08-27

---

## Phân tích

### 1. Vì sao cần refactor lúc này?

Base đang có hai luồng automation dùng cùng từ “build” nhưng hành vi rất khác
nhau:

- `derry build ...` chỉ gọi `flutter build` để tạo artifact cục bộ.
- `build.sh` gọi Fastlane, upload Firebase/Store, đổi nhóm tester, tạo và push
  Git tag; lane store còn có thể sửa version, commit và push branch.

Sự nhập nhằng này khiến người dùng khó biết lệnh nào chỉ build và lệnh nào tạo
side effect từ xa. `build.sh` còn phụ thuộc `$PWD`, sửa `.env` bằng `sed -i ''`
chỉ tương thích macOS, không fail-fast và tự reset nhóm tester về một giá trị
không nhất thiết là giá trị ban đầu.

### 2. Phần nào thay đổi và phần nào giữ nguyên?

Thay đổi:

- Derry trở thành command catalog duy nhất mà developer cần nhớ.
- Phân biệt rõ `build`, `distribute`, và `release`.
- `build.sh` nhận option có tên, hỗ trợ `--dry-run`, fail-fast, chạy được từ mọi
  working directory và không sửa file `.env` để chọn tester group.
- Upload store phải có cờ xác nhận tường minh.
- Git tag chỉ được push khi người chạy chủ động truyền option.

Giữ nguyên:

- Flutter/FVM vẫn là engine tạo artifact local.
- Fastlane vẫn sở hữu signing, Firebase App Distribution, Google Play và
  TestFlight.
- Các lane `build_dev_debug`, `build_staging_staging`,
  `build_prod_release`, và `build_store` tiếp tục được tận dụng trong giai đoạn
  chuyển tiếp.
- Các flag cũ của `build.sh` được giữ như compatibility alias tạm thời.

### 3. Dependency map của automation hiện tại là gì?

```text
Developer
  ├─ derry.yaml
  │    ├─ scripts/flutterw.sh → FVM hoặc Flutter trên PATH
  │    ├─ scripts/generate.sh / quality.sh / ...
  │    └─ build.sh → Bundler → Fastlane
  └─ build.sh cũ
       ├─ android/fastlane/Fastfile
       ├─ ios/fastlane/Fastfile
       ├─ fastlane .env/.env.secret local
       ├─ Firebase App Distribution
       ├─ Google Play / TestFlight
       └─ Git remote/tag/branch
```

Caller trực tiếp của `build.sh` hiện không có trong source; developer gọi thủ
công. `pub_get.sh` và `update_version.sh` được gọi từ Fastfile. Contract public
quan trọng nhất là các flag CLI cũ và tên lane Fastlane.

### 4. Phạm vi refactor là gì?

Trong scope:

- `derry.yaml`
- `build.sh`
- `android/fastlane/Fastfile`
- `ios/fastlane/Fastfile`
- hướng dẫn Derry/build/release và index tài liệu
- dry-run/syntax verification cho command mapping

Ngoài scope của đợt này:

- đổi tên `Giaohang247` và native application identifier
- thay Firebase project, signing profile và store credential mẫu
- viết lại toàn bộ Fastlane theo CI/CD provider mới
- tự động bump version hoặc tự động commit/push release branch

### 5. Điều gì thúc đẩy quyết định làm lúc này?

Derry vừa được đưa vào foundation modernization. Nếu không chuẩn hóa ngay,
developer sẽ tiếp tục dùng song song lệnh mới và script cũ, làm tài liệu và hành
vi thực tế drift. Việc này cũng là tiền đề cho create/rename workflow và CI/CD
sau khi base được trung hòa branding.

### 6. Hiện có test nào bảo vệ automation không?

Chưa có test tự động cho `build.sh` hoặc Fastlane lane. Các application test
không cover shell/Ruby delivery automation. Vì chạy lane thật có side effect từ
xa, safety net phù hợp trong đợt này là:

- `bash -n build.sh`
- `ruby -c` cho hai Fastfile
- `derry ls -d` để verify command catalog
- `--dry-run` cho từng mapping environment/platform/audience
- `git diff --check`

Test integration upload thật chỉ nên chạy trên project đã thay credential và có
release checklist riêng.

### 7. Chiến lược migration là gì?

Migration thực hiện theo một bước ở command catalog nhưng giữ compatibility
alias trong `build.sh`:

1. Lệnh mới được document và dùng trong Derry.
2. Flag cũ vẫn map sang engine mới và in cảnh báo deprecated.
3. Khi create/rename workflow và Fastlane trung lập sản phẩm hoàn tất, có thể
   xóa alias cũ trong một breaking release của base.

Không duy trì hai implementation build riêng; Derry chỉ là facade, shell script
là orchestration, Fastlane là delivery engine.

### 8. Rủi ro là gì?

- Lane cũ chứa branding, key path và signing configuration của sample nên chưa
  thể chạy universal trên app vừa fork.
- Store upload là side effect không rollback hoàn toàn; xác nhận CLI chỉ giảm
  khả năng chạy nhầm, không thay thế release checklist.
- Android và iOS có thể hoàn tất không đồng thời khi chọn cả hai platform.
- Fastlane/Dotenv có thể lấy biến từ nhiều nguồn; tester group truyền trực tiếp
  phải có precedence rõ ràng.
- Alias cũ có thể che giấu thói quen dùng tên environment/flavor không chuẩn.

### 9. Verify không làm vỡ hành vi bằng cách nào?

- Kiểm tra ba flavor native tồn tại và mọi lệnh run/build truyền `--flavor` phù
  hợp.
- Dry-run sáu tổ hợp distribution chính: Android/iOS × dev/staging/prod.
- Dry-run tester/client để verify tên group theo platform.
- Dry-run store phải bị chặn nếu thiếu `--confirm-store` và được phép khi có cờ.
- Verify flag cũ map đúng lane nhưng không thực thi upload trong dry-run.
- Không chạy Firebase/Store thật trong base repository khi credential chưa được
  trung hòa.

### 10. Cải thiện đo được sau refactor là gì?

- Developer chỉ cần xem `derry ls -d` và một guide để biết toàn bộ workflow.
- Tên lệnh cho biết side effect: `build` local, `distribute` cho tester,
  `release` cho store.
- Chọn tester group không còn sửa hai file `.env` rồi reset cưỡng bức.
- Mọi command delivery đều có dry-run; store không thể chạy do gõ nhầm một lệnh
  thiếu xác nhận.
- Logic `build.sh` cũ được tận dụng thay vì bị copy thêm vào `derry.yaml`.

---

## Tổng hợp

### Nhận định chính

Derry không nên thay thế Fastlane hoặc chứa delivery logic. Nó nên là facade
khám phá lệnh; `build.sh` là orchestration adapter; Fastlane tiếp tục sở hữu
platform delivery. Ba tầng này chỉ bền khi tên lệnh phản ánh đúng mức side
effect.

### Hướng khuyến nghị

Giữ `derry build` hoàn toàn local, thêm `derry distribute` gọi `build.sh` cho
Firebase App Distribution, và chỉ cho `derry release` upload store khi có
`--confirm-store`. Refactor `build.sh` thành CLI fail-fast có dry-run, truyền
tester group qua process environment và giữ flag cũ như alias tạm thời. Tắt
Git tag/commit/push mặc định trong Fastlane; chỉ push tag bằng opt-in rõ ràng.

### Rủi ro cần theo dõi

- Fastlane vẫn còn branding và credential path của sample.
- Release hai platform không phải transaction nguyên tử.
- Dry-run kiểm tra orchestration nhưng không thay thế lần smoke test delivery
  thật trên app đã cấu hình.

### Câu hỏi mở

- CI/CD đích cuối là GitHub Actions, Codemagic hay runner riêng?
- Versioning sau này dùng pubspec, build number từ CI hay conventional release?
- Firebase tester group có tiếp tục theo quy ước `tester-{platform}` và
  `client-{platform}` ở mọi sản phẩm không?
