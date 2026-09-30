# ADR 0009: Typed UI Effect Tại Presentation Boundary

- Trạng thái: Accepted
- Ngày: 2026-09-28

## Bối cảnh

Các Cubit auth cũ lấy `BuildContext` gián tiếp qua `AppController`, tự dịch chuỗi,
mở dialog và điều hướng. Cách này khiến business transition phụ thuộc widget
tree, khó unit-test và che mờ ownership của side effect.

## Quyết định

- Cubit/BLoC chỉ emit state và `UiEffect<T>` có kiểu; không gọi navigation,
  dialog, snackbar, localization hoặc đọc route argument.
- `UiEffect` có revision tăng dần để hai intent giống nhau liên tiếp vẫn là hai
  lần xử lý độc lập.
- Screen xử lý effect bằng `BlocListener` hoặc `LoadingScreen.listenWhen`, rồi
  mới gọi `SLIRouting`, dialog và `context.l10n`.
- Validation state dùng enum/value có kiểu. Việc đổi validation thành câu chữ
  thuộc Screen.
- Error mapper lõi nhận fallback text tường minh; nó không resolve context hoặc
  service locator.

## Hệ quả

- Cubit có thể test không cần widget tree và UI side effect trở nên truy vết
  được.
- Mỗi listener phải lọc theo revision/effect thay đổi để state khác không phát
  lại effect cũ.
- Effect chỉ biểu diễn presentation intent ngắn hạn; dữ liệu nghiệp vụ bền vững
  vẫn phải nằm trong state/domain model bình thường.

Ví dụ chuẩn nằm trong
[hướng dẫn xử lý UI effect](../guides/handle-ui-effects.md).
