# Model Patterns

## Nested object

When an API field is itself a JSON object, create a separate Model for it.

```dart
@freezed
abstract class Product with _$Product {
  const factory Product({
    required String id,
    required String name,
    required Price price,           // nested -- Freezed handles fromJson automatically
    required Category category,     // nested
    @Default([]) List<String> images,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
}

@freezed
abstract class Price with _$Price {
  const factory Price({
    required double amount,
    @Default('USD') String currency,
  }) = _Price;

  factory Price.fromJson(Map<String, dynamic> json) =>
      _$PriceFromJson(json);
}
```

---

## Nested List

When a field is a list of objects, Freezed handles the list deserialization automatically:

```dart
@freezed
abstract class Order with _$Order {
  const factory Order({
    required String id,
    required List<OrderItem> items,
    @JsonKey(name: 'total_amount') required double totalAmount,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _Order;

  factory Order.fromJson(Map<String, dynamic> json) =>
      _$OrderFromJson(json);
}
```

---

## Enum in Model

Use `@JsonValue` on the enum to map string/int values from the API.
Use `@JsonKey(unknownEnumValue: ...)` on the Model field to handle unexpected values gracefully.

```dart
// shared/models/sales/order_status.dart
enum OrderStatus {
  @JsonValue('pending') pending,
  @JsonValue('processing') processing,
  @JsonValue('shipped') shipped,
  @JsonValue('delivered') delivered,
  @JsonValue('cancelled') cancelled,
}

// shared/models/sales/order.dart
@freezed
abstract class Order with _$Order {
  const factory Order({
    required String id,
    @JsonKey(unknownEnumValue: OrderStatus.pending) // fallback for unknown values
    required OrderStatus status,
  }) = _Order;

  factory Order.fromJson(Map<String, dynamic> json) =>
      _$OrderFromJson(json);
}
```

---

## Paginated response wrapper

A generic wrapper for paginated API responses. The `hasMore` getter is a
computed property -- requires the private constructor.

```dart
// shared/models/common/paginated_response.dart
@freezed
abstract class PaginatedResponse<T> with _$PaginatedResponse<T> {
  const PaginatedResponse._();

  const factory PaginatedResponse({
    required List<T> items,
    required int total,
    required int page,
    required int limit,
  }) = _PaginatedResponse<T>;

  bool get hasMore => (page * limit) < total;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) => _$PaginatedResponseFromJson(json, fromJsonT);
}

// Usage in DataSource:
@GET('/products')
Future<PaginatedResponse<Product>> getProducts(@Query('page') int page);
```
