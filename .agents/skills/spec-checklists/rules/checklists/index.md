# Rules — Checklists

Rules for generating and reviewing each checklist type in a frontend spec (`fe.md`).

## How to use

- **When generating a checklist** → read `Fill rules` of the corresponding section file before writing.
- **When reviewing a checklist** → use `Review rules` of each section as a checklist.

## Sections

| File | fe.md section | Covers |
|---|---|---|
| [sections/entity.md](sections/entity.md) | §6.1 Entity | Abstract class in domain/entities |
| [sections/data-model.md](sections/data-model.md) | §6.2 Model | @JsonSerializable in data/model |
| [sections/repository.md](sections/repository.md) | §6.3 Repository | Interface + impl, return types (Entity), cache strategy |
| [sections/api.md](sections/api.md) | §6.4 API | Retrofit DataSource, endpoint scope, request/response Models, error handling |
| [sections/route.md](sections/route.md) | §6.10 Route | New route detection, GoRoute params, navigation flow |
| [sections/validation.md](sections/validation.md) | §6.5 Validation | Flutter form validators, easy_localization keys, reuse vs create |
| [sections/utility.md](sections/utility.md) | §6.6 Utility | Pure Dart functions, inputs/outputs, reuse vs create |
| [sections/component.md](sections/component.md) | §6.7 Widget | Atomic Design layer (Atom/Molecule/Organism), constructor params, visual states |
| [sections/bloc-cubit.md](sections/bloc-cubit.md) | §6.8 BLoC/Cubit | Cubit vs BLoC choice, sealed @freezed State, methods/events |
| [sections/page.md](sections/page.md) | §6.9 Page | Screen composition, BLoC wiring, screen states, navigation |
