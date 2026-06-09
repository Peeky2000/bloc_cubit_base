# Model — Unified Data Class

A Model is the single data class used across all layers. It uses `@freezed` for
immutability and `json_serializable` for JSON serialization. There is no separate
Entity -- the Model serves both domain and data purposes.

## Standard Model

```dart
// shared/models/auth/user.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
abstract class User with _$User {
  const factory User({
    required String id,
    required String email,
    @JsonKey(name: 'full_name') required String fullName,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @Default(false) bool isVerified,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) =>
      _$UserFromJson(json);
}
```

## Key points

- Class name uses the **business name**: `User`, `Product`, `Order` -- no `Model` suffix
- Has `fromJson` (used by Retrofit and JSON deserialization)
- Has `@JsonKey` where API field names differ from Dart names
- No `toEntity()` -- this class IS the entity
- Drift mapping is in `core/database/mappers/` as extensions, NOT in the model file

## Generated files

Both are required:

```dart
part 'user.freezed.dart'; // immutable class
part 'user.g.dart';       // fromJson / toJson
```

```bash
flutter pub run build_runner build --delete-conflicting-outputs
# or during active development:
flutter pub run build_runner watch --delete-conflicting-outputs
```

## Naming conventions

| Element | Example |
|---|---|
| Class | `User`, `Product`, `Order` |
| File | `user.dart`, `product.dart` |
| Freezed generated | `user.freezed.dart` |
| JSON generated | `user.g.dart` |
| Location | `shared/models/auth/`, `shared/models/sales/` |
