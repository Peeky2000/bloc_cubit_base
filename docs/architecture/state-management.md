# Quản Lý State

## Lựa chọn mặc định

Dùng Cubit cho screen state theo command. Dùng BLoC cổ điển khi danh tính event,
event concurrency, debounce/restartable behavior, nhiều nguồn event, hoặc audit
trail thật sự cải thiện correctness.

Cả hai style đều là first-class và dùng use case inject qua constructor.

## Hình dạng state

- Giữ `BaseAppState + Equatable + copyWith`.
- State là immutable.
- Loading và failure có kiểu rõ; không dùng `dynamic` cho lỗi state.
- UI-only one-shot effect phải là output tường minh ở presentation, không phải
  navigation hoặc dialog gọi từ Cubit/BLoC.
- Không đưa Freezed hoặc HydratedBloc vào mặc định.

## Lifetime

- Feature Cubit/BLoC là factory và được `BlocProvider` close.
- App-scope state chỉ dùng cho concern thật sự thuộc app-scope như locale hoặc
  session status.
