# Repository Checklist — {repository-name}

- Spec: `docs/specs/{id}-{name}/fe.md` §6.3
- Skills: `flutter-repository`, `flutter-di`

## Interface

- [ ] `lib/domain/repositories/{name}_repo.dart` — `abstract class`
- [ ] Methods return entities / domain types from §6.1

## Implementation

- [ ] `lib/data/repositories/{name}_repo_impl.dart`
- [ ] Injects remote/local data sources
- [ ] Implementation annotated `@LazySingleton(as: {Name}Repo)`
- [ ] Data sources are constructor-injected; no service-locator access

## UseCase (same spec §6.3)

- [ ] `lib/domain/use_case/{name}_use_case.dart`
- [ ] Cubit will call UseCase, not Repo directly
- [ ] UseCase annotated `@lazySingleton`
- [ ] `derry gen` regenerates the DI graph successfully
