# Model — Rules, Naming & Checklist

## JsonKey — Common cases

| API field | Dart field | Annotation |
|---|---|---|
| `full_name` | `fullName` | `@JsonKey(name: 'full_name')` |
| `created_at` (ISO String) | `createdAt` (DateTime) | `@JsonKey(name: 'created_at', fromJson: _parseDate)` |
| `is_active` | `isActive` | `@JsonKey(name: 'is_active')` |
| Nullable but with default | `count` | `@Default(0) int count` |
| Exclude from serialization | — | `@JsonKey(includeToJson: false)` |

## Naming conventions

| Pattern | Example |
|---|---|
| Class name | `User`, `Product`, `Order` |
| File name | `user.dart`, `product.dart` |
| Freezed generated file | `user.freezed.dart` |
| JSON generated file | `user.g.dart` |
| Location | `shared/models/{domain}/` |

## Checklist

- [ ] Model in `shared/models/{domain}/` -- has `fromJson`/`toJson`
- [ ] Class name uses business name (no `Model` suffix)
- [ ] Uses `const ClassName._()` if custom methods or computed getters are needed
- [ ] Dart fields use camelCase; `@JsonKey(name:)` used when API field differs
- [ ] Enums placed alongside related models in `shared/models/{domain}/`
- [ ] `part 'file.freezed.dart'` and `part 'file.g.dart'` both added
- [ ] `build_runner` executed after adding/modifying annotations
- [ ] No Drift imports in model files -- mapping lives in `core/database/mappers/`
