# Rules — Checklist: repository

## Fill rules

- **Interface:** `lib/domain/repositories/{name}_repo.dart`
- **Impl:** `lib/data/repositories/{name}_repo_impl.dart`
- **UseCase:** `lib/domain/use_case/{name}_use_case.dart` (same spec §6.3)

See [canonical-paths.md](../../../../project-convention/references/canonical-paths.md).

## Review rules

- [ ] Interface + impl + use case paths correct.
- [ ] DI in `lib/di/injection.dart`.
