# Rule: Add Private Constructor When Model Needs Instance Methods

**Why:** Freezed generates a sealed class internally. When you add a factory constructor
like `const factory User({...}) = _User`, Freezed makes `_User` the
actual implementation and `User` a pure interface with no body. Any instance method
you try to add on `User` fails to compile because the class has no concrete body
to put it in. The fix is a private unnamed constructor `const User._()` -- this
tells Freezed to generate a concrete body for `User` so it can hold custom methods.

---

## Bad

```dart
@freezed
abstract class PaginatedResponse<T> with _$PaginatedResponse<T> {
  const factory PaginatedResponse({
    required List<T> items,
    required int total,
    required int page,
    required int limit,
  }) = _PaginatedResponse<T>;

  // Compile error -- no private constructor
  bool get hasMore => (page * limit) < total;
}
```

---

## Good

```dart
@freezed
abstract class PaginatedResponse<T> with _$PaginatedResponse<T> {
  const PaginatedResponse._(); // add this BEFORE the factory constructor

  const factory PaginatedResponse({
    required List<T> items,
    required int total,
    required int page,
    required int limit,
  }) = _PaginatedResponse<T>;

  // Compiles fine
  bool get hasMore => (page * limit) < total;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) => _$PaginatedResponseFromJson(json, fromJsonT);
}
```

---

## When is it required?

| What you're adding | Need `const ClassName._()`? |
|---|---|
| Only `fromJson` / `toJson` (generated) | No |
| Any computed getter (`bool get hasMore`) | Yes |
| Any other instance method | Yes |

**Rule of thumb:** if it's an instance member (not a factory), add the private constructor.
