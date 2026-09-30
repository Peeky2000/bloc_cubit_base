# Quản Lý State

## Lựa chọn mặc định

Dùng Cubit cho screen state theo command. Dùng BLoC cổ điển khi danh tính event,
event concurrency, debounce/restartable behavior, nhiều nguồn event, hoặc audit
trail thật sự cải thiện correctness.

Cả hai style đều là first-class và dùng use case inject qua constructor.

## Hình dạng state

- Giữ `BaseAppState<Failure> + Equatable + copyWith`; dùng `Object` khi feature
  chưa có failure taxonomy riêng.
- State là immutable.
- Loading và failure có kiểu rõ; không dùng `dynamic` cho lỗi state.
- UI-only one-shot effect phải là output tường minh ở presentation, không phải
  navigation hoặc dialog gọi từ Cubit/BLoC.
- Không đưa Freezed hoặc HydratedBloc vào mặc định.

## UI effect một lần

`BaseCubit` và `BaseBloc` cung cấp `createEffect`, trả về `UiEffect<T>` có
revision tăng dần. Effect type dùng sealed class và nằm cạnh feature state.

- Cubit emit intent có kiểu như `NavigateHome`, `ShowError` hoặc `Saved`.
- Screen lọc `previous.effect != current.effect` bằng `BlocListener` hoặc
  `LoadingScreen.listenWhen` rồi mới gọi route/dialog/l10n.
- Không đặt localized string, `BuildContext`, Widget hoặc route argument trong
  Cubit.
- Validation lưu enum/value có kiểu; Screen map sang ARB.
- Callback async phải kiểm tra lifecycle trước khi emit sau `close()`.

Xem [hướng dẫn UI effect](../guides/handle-ui-effects.md) và
[ADR-0009](../adr/0009-typed-ui-effects-at-presentation-boundary.md).

## Lifetime

- Feature Cubit/BLoC là factory và được `BlocProvider` close.
- App-scope state chỉ dùng cho concern thật sự thuộc app-scope như locale hoặc
  session status.
- Timer, stream subscription và callback SDK phải dừng hoặc bỏ qua emit khi
  Cubit/BLoC đã đóng.
