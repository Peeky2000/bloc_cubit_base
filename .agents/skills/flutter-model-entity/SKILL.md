---
name: flutter-model-entity
description: >
  Domain entities (abstract contracts) and data models (json_serializable) for this base.
  Models implement entities. Trigger: "model", "entity", "fromJson", "response model".
---

# Entity + Model (separate layers)

## Locations

| Layer | Path | Role |
|-------|------|------|
| Entity | `lib/domain/entities/{domain}/` | Abstract class — API-agnostic contract |
| Model | `lib/data/model/request/` or `response/` | JSON DTO, `@JsonSerializable` |
| Repo returns | Entity types or models implementing entities | See existing `AuthRepo` |

## Entity

```dart
abstract class Login {
  Account? get account;
  TokenWrapper? get token;
}
```

No `fromJson`, no `part` files.

## Model

```dart
@JsonSerializable()
class LoginResponseModel implements Login {
  // fields with @JsonKey, fromJson/toJson, .g.dart
}
```

## Codegen

```bash
derry gen
```

## Rules

- **No** `@freezed` in this base (unless user explicitly migrates)
- Request bodies: `data/model/request/*_request_model.dart`
- Use `@JsonKey(name: 'snake_case')` for API field names
- Cubit/UI depend on **entities** or state primitives — not raw `*_model.dart` in presentation

- Models contain transport serialization only; database/platform mapping belongs
  in a dedicated data-layer adapter, never in domain or presentation.
