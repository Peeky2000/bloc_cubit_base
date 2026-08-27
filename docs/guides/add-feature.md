# Add a Feature

Only add layers that the feature needs, while preserving this dependency order:

```text
Entity → Model → DataSource → Repository → UseCase → Cubit/BLoC → Screen
```

## Checklist

1. Search app-memory, `sli_common`, routes, and sibling domain code.
2. Define pure domain values/contracts; do not expose JSON models.
3. Add `json_serializable` request/response models in data.
4. Add an abstract data source and injectable implementation around
   `ApiHandler` or a local storage abstraction.
5. Add the domain repository contract and bind `RepoImpl` with
   `@LazySingleton(as: Repo)`.
6. Add a constructor-injected UseCase for orchestration.
7. Choose Cubit or BLoC using [the decision guide](choose-cubit-or-bloc.md),
   annotate it `@injectable`, and unit-test transitions.
8. Build a thin screen. Resolve the state owner once in its builder and localize
   all user-facing text.
9. Register `AppPage`/`SLIPage`, update ARB files, and reuse `Sli*` components.
10. Run `derry gen`, `derry quality`, and update app-memory/docs.

Do not put BuildContext, navigation, localization, Dio, or service-locator calls
inside domain/business logic.
