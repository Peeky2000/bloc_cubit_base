# AI Agents — Flutter Base Template

## Start

Read these sources in order before changing code:

1. [ai-process.md](ai-process.md)
2. [docs/prerequisites.md](docs/prerequisites.md)
3. [architecture rules](docs/architecture/README.md)
4. [.agents/skills/project-convention/SKILL.md](.agents/skills/project-convention/SKILL.md)

## Agents

| Agent | Invoke |
|---|---|
| PM | `@.agents/agents/pm.md` |
| Coder | `@.agents/agents/coder.md` |
| Reviewer | `@.agents/agents/reviewer.md` |
| Quick fix | `@.agents/agents/flutter-engineer.md` |

Search indexed project artifacts before creating a duplicate:

```bash
python3 .agents/skills/app-memory/scripts/mem_search.py "auth"
```

## Non-negotiable rules

- Layer order: Entity → Model → DataSource → Repository → UseCase → Cubit/BLoC
  → Screen → Route → l10n → generated DI.
- Dependency direction: presentation → domain ← data. Domain has no Flutter,
  data, presentation, service-locator, or UI dependencies.
- Classes receive dependencies through constructors. Only composition roots
  resolve from `getIt` (`bootstrap`, route/screen builders, DI modules).
- Use `@injectable` for feature Cubits/BLoCs, `@lazySingleton` for stateless
  services, and interface bindings such as `@LazySingleton(as: AuthRepo)`.
- Never edit `lib/di/injection.config.dart`; run `derry gen`.
- Cubit is the default. Choose BLoC only when named events, event transformers,
  or concurrency semantics provide concrete value.
- Reuse `sli_common` before adding app-local reusable widgets. Import its stable
  API; do not spread direct `shadcn_flutter` imports through the app.
- Run `derry quality` and report pre-existing debt separately from regressions.
