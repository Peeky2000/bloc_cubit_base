# Model Checklist — {model-name}

## Prerequisites

- Spec: `docs/specs/{id}-{name}/fe.md` §6.2

## Skills

- [ ] `flutter-model-entity`
- [ ] `project-convention`

## Implementation

- [ ] Entity in `lib/domain/entities/{domain}/{entity}.dart` (if new)
- [ ] Model: `lib/data/model/response/{domain}/{name}_response_model.dart` (or `request/`)
- [ ] `@JsonSerializable()`, `implements` entity when applicable
- [ ] `@JsonKey` for API field names
- [ ] Run `derry gen`
- [ ] `flutter analyze` clean
- [ ] app-memory updated
