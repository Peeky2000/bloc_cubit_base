# Matrix migration widget trùng — 2026-10-01 (cập nhật 2026-10-08)

Đây là checklist quyết định cho 10 filename còn trùng sau BottomSheet. So sánh
source app tại `lib/core/widget` với public export trong `sli_common`; tên file
giống nhau **không** chứng minh contract giống nhau. Nguồn V2/`commons` là tham
khảo design khi thiết kế `Sli*`, không quyết định behavior app hiện tại.

| Widget/family | Khác biệt đáng kể | Caller app / coupling | Quyết định và gate trước migration |
|---|---|---|---|
| `ExpandedWidget` / layout | Shared trước đây căn đáy cả hai trục; app căn phải với trục ngang | `CommonTextField` dùng dọc | **Đã làm:** đồng bộ căn lề, test hai trục, app adapter deprecated và caller nội bộ dùng shared |
| `TitleWidget` / display | Implementation trùng; hai class giữ `defaultTitleStyle`/`defaultValueStyle` static độc lập | `MainApp` cấu hình static, chưa thấy render caller | Chưa đổi: test theme/defaults, chuyển config sang shared rồi adapter forward static |
| `MoneyWidget` / display | Chỉ khác import formatter; formatter hiện giống nội dung | `MainApp` đặt `unitDefault = ' đ'`; chưa thấy render caller | Test dấu dương, locale/format/unit và static default trước adapter |
| `BaseField` / display | Implementation trùng | `MainApp` đặt `baseFieldStyle` static; chưa thấy render caller | Kiểm tra type/style/enum compatibility; tránh hai global style độc lập |
| `CommonDropDown` / form | Chỉ khác import `StringExtension`; extension hiện giống nội dung | 2 caller ở SignUp; `MainApp` đặt `commonDropDownStyle` static | Test enable/error/value/theme và chuyển style cùng caller, rồi adapter |
| `CommonTextField` / form | Chỉ khác import `StringExtension` và `ExpandedWidget`; widget code còn lại trùng | SignIn/SignUp/ResetPassword; `MainApp` đặt `commonTextFieldStyle` static | Test focus/validation/password/expand, kiểm tra lifecycle controller và đồng bộ style trước adapter |
| `DialogUtil` / overlay | Code gần trùng nhưng `context.l10n` thuộc hai package khác nhau; option model khác type | Global handler, ResetPassword, MainApp; app chỉ đăng ký app l10n delegate | **Chặn direct swap:** cần label contract/delegate hoặc adapter truyền text, test alert/error/option/flushbar và chống dialog trùng |
| `InkWellButton` / action | App dùng `Container + InkWell`, shared dùng `ElevatedButton`; height, text style, disabled color, min-size khác | DeliveryGoButton, NoInternetScreen | Không thay theo tên; thiết kế `SliButton` variant hoặc adapter giữ geometry/semantics, test disabled/tap/theme |
| `BottomButton` / action | App là full-width `ElevatedButton` 48.h với shadow; shared là SafeArea + 15px spacing + `InkWellButton` | DeliveryGoBottomButton | Test fixed height, divider, bottom inset, callback/disabled; quyết định footer layout riêng thay vì đổi import |
| `Bottom2Button` / action | App 2 nút dính nhau với divider 1px; shared 2 nút rời cách 12px trong SafeArea | DeliveryGoBottom2Button | Test geometry hai nút, border radius, disabled từng nút; giữ product wrapper ở app |

## Thứ tự tiếp theo

1. Form/input đang có caller thật: khóa behavior, chuyển style từ global app sang
   shared hoặc facade có style injection; migrate caller và giữ app adapter.
2. Dialog: giải quyết l10n/model boundary trước khi thay import.
3. Action: tách container footer khỏi button primitive; dùng `SliButton` nếu
   parity đạt, không copy layout `commons` nguyên khối.
4. Display còn lại: chuyển các static defaults và chứng minh parity dù hiện
   chưa có render caller.

Mỗi dòng chỉ được đánh dấu xong khi có test behavioral/semantics, docs/catalog
đúng maturity, adapter deprecated và `derry quality` pass. Đếm file trùng ở
đây là inventory, không phải thước đo chất lượng API. Xem
[guide migration](../guides/use-sli-common.md) và
[review BottomSheet](../reviews/2026-09-30-shadcn-bottom-sheet-review.md).

## Kết quả 2026-10-08

Bảy file trùng đã được xử lý:

| Widget | Kết quả |
|---|---|
| `TitleWidget`, `MoneyWidget`, `BaseField`, `CommonDropDown`, `CommonTextField` | Code trùng 100% với `sli_common` (chỉ khác import). App dùng bản `sli_common`, xoá bản app. `MainApp` vẫn cấu hình style tĩnh như cũ, nay trên class của `sli_common` |
| `DialogUtil` | Code trùng 100%. App dùng bản `sli_common`; `MainApp` đăng ký thêm `sli_common` localizations delegate để nhãn mặc định (Hủy, Ok) dịch được. Có test `test/core/widget/shared_dialog_localization_test.dart` |
| `BottomButton`, `Bottom2Button` | Không còn caller nào; đã xoá cùng wrapper `DeliveryGo*` |
| `InkWellButton` | Khác hẳn về layout với bản `sli_common`. Giữ bản app, đổi tên `AppInkWellButton` và chuyển vào `lib/widget/` cạnh `AppPrimaryButton` |
| `BottomSheetWidget`, `ExpandedWidget` | Vẫn là adapter deprecated có test, chuyển tiếp sang `sli_common` |
