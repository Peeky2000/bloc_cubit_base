# Xử Lý UI Effect Từ Cubit/BLoC

Dùng pattern này khi business transition cần yêu cầu Screen điều hướng, mở
dialog, hiển thị lỗi hoặc thực hiện một hành động UI chỉ một lần.

## Ownership

| Thành phần | Được làm | Không được làm |
|---|---|---|
| Cubit/BLoC | Validate bằng type, gọi UseCase, emit state/effect | Giữ `BuildContext`, dịch ARB, gọi route/dialog |
| State | Giữ dữ liệu render và `UiEffect<T>?` | Giữ Widget hoặc localized message |
| Screen | Map validation sang `context.l10n`, xử lý effect | Gọi API/repository trực tiếp |

## 1. Định nghĩa effect có kiểu

```dart
sealed class ProfileEffect {
  const ProfileEffect();
}

final class ProfileSavedEffect extends ProfileEffect {
  const ProfileSavedEffect();
}

final class ProfileShowErrorEffect extends ProfileEffect {
  const ProfileShowErrorEffect(this.error);

  final Object error;
}
```

Đặt effect cạnh Cubit, ví dụ
`lib/presentation/profile/cubit/profile_effect.dart`, và khai báo bằng `part`
nếu feature đang theo cấu trúc hiện tại.

## 2. Đưa effect vào state

```dart
final UiEffect<ProfileEffect>? effect;

// Trong copyWith:
effect: effect ?? this.effect,

// Trong props:
effect,
```

Cubit kế thừa `BaseCubit`, vì vậy có thể phát revision mới:

```dart
void _emitEffect(ProfileEffect effect) {
  emit(state.copyWith(effect: createEffect(effect)));
}
```

Không emit localized string. Với validation, dùng enum như
`PhoneInputError.required` rồi map sang ARB ở Screen.

## 3. Xử lý ở Screen

```dart
LoadingScreen<ProfileCubit, ProfileState>(
  listenWhen: (previous, current) => previous.effect != current.effect,
  listener: (context, state) {
    switch (state.effect?.value) {
      case ProfileSavedEffect():
        SLIRouting.back();
      case ProfileShowErrorEffect(:final error):
        handleErrorResponse(context, error);
      case null:
        break;
    }
  },
  builder: (context, state) => const ProfileView(),
);
```

Nếu listener còn nghe page transition hoặc concern khác, phải bảo đảm effect
chỉ được xử lý khi revision thay đổi. Ưu tiên tách listener theo concern khi
flow phức tạp.

## 4. Test tối thiểu

- Invalid input tạo validation enum và không gọi UseCase.
- Loading/success/failure transition đúng.
- Hai command UI giống nhau tạo hai revision khác nhau.
- Error effect giữ raw error + retry intent, không tự mở dialog.
- Callback async tới sau `close()` không emit thêm state.

Cuối cùng chạy `derry gen` nếu constructor Injectable đổi, rồi `derry quality`.
Architecture gate sẽ fail nếu file `presentation/**/cubit/*.dart` import UI,
routing, localization hoặc dùng `BuildContext`.
