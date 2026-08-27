# Dependency Rules

## Layers

| Layer | Owns | May import |
|---|---|---|
| `domain` | entities, repository contracts, use cases, domain failures | Dart and domain only |
| `data` | JSON models, data sources, repository implementations | domain, infrastructure-safe core |
| `presentation` | screens, Cubits/BLoCs, UI effects | domain, presentation-safe core |
| `core` | cross-cutting contracts and framework adapters | no feature implementation |
| `di` | composition root | every layer |

## Mandatory rules

1. Widgets never call APIs, repositories, or data sources.
2. Cubits and BLoCs call use cases, not repositories or data sources.
3. Domain never imports `data`, Flutter widgets, Dio, Firebase, or GetIt.
4. Presentation never imports concrete data models when a domain type can express the
   contract.
5. Classes receive dependencies through constructors. `getIt` is allowed only in the
   composition root and route/widget provider factories.
6. External package setup belongs in Injectable modules, not feature classes.

These rules are enforced by review and `scripts/check_architecture.sh`.
