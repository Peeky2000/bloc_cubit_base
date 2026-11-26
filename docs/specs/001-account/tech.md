# Thiết kế kỹ thuật: Màn Tài khoản

- Mã: 001-account
- Trạng thái: Approved
- Tài liệu nguồn: [spec.md](spec.md)
- Người duyệt: PM, ngày 2026-11-26 (demo sinh code)
- Quyết định liên quan: ADR-0002, ADR-0009, ADR-0005, ADR-0012

## 1. Yêu cầu nhận vào

| Mã | Yêu cầu (trích tài liệu) | Ghi chú kỹ thuật |
|---|---|---|
| AC1 | Sau khi đăng nhập, app mở màn Tài khoản thay cho màn home trống | `AppPage.home` trỏ sang `accountScreenBuilder()` |
| AC2 | Hiện email, số điện thoại, vai trò; trống thì "Chưa có" | Đọc `AuthUseCase.accountLocal` (session đã có), không gọi API |
| AC3 | Đăng xuất có xác nhận, xoá phiên, về Đăng nhập | `AuthUseCase.logout()` → `SessionRepo.end()` |
| AC4 | Đăng xuất lỗi: báo lỗi, cho thử lại, ở lại màn | Effect lỗi có retry, state `LoadingStatus.error` |

## 2. Quyết định áp dụng

| Chủ đề | Quyết định | Nguồn |
|---|---|---|
| State owner | Cubit | ADR-0002 |
| Điều hướng, dialog | `UiEffect<AccountEffect>`, Screen xử lý | ADR-0009 |
| Route | `SLIRouting` + `AppPage` | ADR-0005 |
| Không màn mẫu | Sinh từ spec bằng scaffold | ADR-0012 |

Quyết định mới đề xuất: không có.

## 3. Tái sử dụng

| Thứ dùng lại | Vị trí |
|---|---|
| Tài khoản đang đăng nhập, đăng xuất | `AuthUseCase.accountLocal`, `AuthUseCase.logout()` |
| Khung màn có lớp loading | `lib/widget/loading_screen.dart` |
| Nút chính | `lib/widget/app_primary_button.dart` |
| Dialog xác nhận | `DialogUtil.confirm` (`sli_common`) |
| Xử lý lỗi chung | `handleErrorResponse` (`lib/presentation/global_handler.dart`) |
| Thẻ nền, token, icon | `SliSurface`, `SliSpacing`, `SliIcons` (`sli_common`) |

## 4. Lệnh sinh khung

```bash
derry scaffold -- account --apply
```

## 5. Danh sách file

| Tầng | Đường dẫn | Mới / Sửa | Vai trò |
|---|---|---|---|
| State | `lib/presentation/account/cubit/` | Mới | `AccountCubit`, `AccountState`, `AccountEffect` |
| Screen | `lib/presentation/account/view/account_screen.dart` | Mới | Thông tin + nút đăng xuất |
| Route | `lib/core/common/route.dart` | Sửa | `home` trỏ sang màn Tài khoản |
| Home cũ | `lib/presentation/home_page/` | Xoá | Màn trống không còn dùng |
| l10n | `lib/l10n/arb/app_en.arb`, `app_vi.arb` | Sửa | Tiêu đề, nhãn, xác nhận |
| Test | `test/presentation/account_cubit_test.dart` | Mới | Chuyển state, effect |
| Test | `test/presentation/account_screen_test.dart` | Mới | Widget: hiển thị, xác nhận đăng xuất |

Không có entity, model, data source, repository hay use case mới.

## 6. Domain

Dùng lại `Account` (`email`, `phone`, `role`).

## 7. API

Không áp dụng: đăng xuất là thao tác cục bộ của `SessionRepo`.

## 8. Lưu trữ

Không áp dụng: `SessionRepo.end()` đã xoá token và tài khoản.

## 9. State và effect

```dart
class AccountState extends BaseAppState<Object> {
  final String? email;
  final String? phone;
  final String? role;
  final UiEffect<AccountEffect>? effect;
}

sealed class AccountEffect {}
// AccountConfirmLogoutEffect, AccountNavigateSignInEffect,
// AccountShowErrorEffect(error)
```

| Hành động của người dùng | Hàm Cubit | State chuyển thế nào | Effect |
|---|---|---|---|
| Mở màn | `load()` | đọc tài khoản vào `email/phone/role` | |
| Bấm Đăng xuất | `onTapLogout()` | | `AccountConfirmLogoutEffect` |
| Đồng ý trong dialog | `logout()` | loading → complete | `AccountNavigateSignInEffect` |
| Đăng xuất lỗi | `logout()` | loading → error | `AccountShowErrorEffect` (thử lại gọi `logout()`) |

## 10. Giao diện

| Thành phần | Widget dùng lại hoặc mới | Key l10n |
|---|---|---|
| Tiêu đề | `AppBar` | `accountTitle` |
| Thẻ thông tin | `SliSurface` + hàng icon/nhãn/giá trị (mới, trong màn) | `email`, `phoneNumber`, `accountRole`, `accountEmptyValue` |
| Nút đăng xuất | `AppPrimaryButton` | `logout` |
| Xác nhận | `DialogUtil.confirm` | `logoutConfirm`, `logout`, `cancel` |

Design mapping: Không áp dụng — demo không có gói design D6.

## 11. Điều hướng

| Route | Path | Tham số | Đi từ đâu |
|---|---|---|---|
| `AppPage.home` | `/home` | Không | Splash (đã đăng nhập), Đăng nhập thành công |
| `AppPage.signIn` | `/sign_in` | Không | Đăng xuất (`offAllNamed`) |

## 12. Lỗi, rỗng, tải, ngoại tuyến

| Tình huống | Hiển thị | Hành động thử lại |
|---|---|---|
| Trường trống | "Chưa có" | |
| Đang đăng xuất | Lớp loading của `LoadingScreen` | |
| Đăng xuất lỗi | `handleErrorResponse` | `logout()` |

## 13. Bảo mật và quyền riêng tư

Email và số điện thoại chỉ hiển thị, không log. Đăng xuất xoá token và tài
khoản qua `SessionRepo.end()`.

## 14. Hiệu năng

Không áp dụng: màn tĩnh, không gọi mạng.

## 15. Test

| Yêu cầu | Test | Cấp |
|---|---|---|
| AC2 | `load` đọc email, số điện thoại, vai trò | unit |
| AC2 | trường trống hiện "Chưa có" | widget |
| AC3 | bấm Đăng xuất phát effect xác nhận, không gọi logout | unit |
| AC3 | đồng ý xác nhận thì gọi logout và về Đăng nhập | unit + widget |
| AC4 | logout lỗi phát effect lỗi, ở lại màn | unit |
| — | kết quả logout về sau khi đóng Cubit bị bỏ qua | unit |

## 16. Truy vết

| Yêu cầu | Thiết kế | Test |
|---|---|---|
| AC1 | §5 Route, §11 | chạy app: đăng nhập vào màn Tài khoản |
| AC2 | §9 `load`, §10 thẻ thông tin | unit `load`, widget "Chưa có" |
| AC3 | §9 `onTapLogout`, `logout`, §10 dialog | unit, widget |
| AC4 | §9, §12 | unit lỗi |

## 17. Câu hỏi nghiệp vụ

Không có.
