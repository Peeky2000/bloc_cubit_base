---
name: flutter-repository
description: >
  Repository layer for this base: abstract interface in domain, implementation in data.
  Trigger: "repository", "AuthRepo", "repo impl".
---

# Repository

## Locations

| | Path |
|---|------|
| Interface | `lib/domain/repositories/{name}_repo.dart` |
| Implementation | `lib/data/repositories/{name}_repo_impl.dart` |

## Pattern

```dart
// domain
abstract class OrderRepo {
  Future<List<Order>> getOrders({required int page});
}

// data
@LazySingleton(as: OrderRepo)
class OrderRepoImpl implements OrderRepo {
  OrderRepoImpl(this._remote);
  final OrderRemoteDataSource _remote;

  @override
  Future<List<Order>> getOrders({required int page}) =>
      _remote.getOrders(page: page);
}
```

A repository owns one concern. It does not also persist the session, tokens
or another feature's data; session state belongs to `SessionRepo`.

## Rules

- Bind the implementation with `@LazySingleton(as: AuthRepo)`
- Constructor-inject data sources; never resolve `getIt` internally
- Orchestrate remote + local; **no** UI, **no** form validation
- Prefer returning types that implement domain entities (`Login`, etc.)
- UseCases call repos — Cubits call UseCases
- Accept domain entities and convert them to storable models inside the
  implementation; never ignore a value because it is not a data model
- Wrap callback-based SDKs so the port returns one `Future<Outcome>` and
  throws one typed failure; see
  [references/async-flow-patterns.md](references/async-flow-patterns.md)
- For anything persisted, follow
  `../flutter-datasource/references/storage-patterns.md`

- Catch only to transform an infrastructure failure into a documented domain
  failure or to implement repository-level fallback; never swallow an error.
