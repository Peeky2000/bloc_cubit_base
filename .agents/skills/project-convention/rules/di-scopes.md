# Dependency Injection Scopes

DI is configured by `lib/di/injection.dart`, generated in
`lib/di/injection.config.dart`, and supplemented by runtime providers in
`lib/di/register_module.dart`.

| Type | Annotation / provider | Lifetime |
|---|---|---|
| Feature Cubit/BLoC | `@injectable` | factory per provider |
| UseCase/stateless service | `@lazySingleton` | lazy app lifetime |
| Repository implementation | `@LazySingleton(as: Repo)` | lazy app lifetime via interface |
| DataSource implementation | `@LazySingleton(as: DataSource)` | lazy app lifetime via interface |
| App coordinator | `@singleton` | app lifetime, explicit only |
| SharedPreferences/platform SDK | `@module`, optionally `@preResolve` | composition root |
| `AppConfig` runtime value | explicit runtime module/provider | one bootstrap |

Constructor injection is mandatory outside composition roots. Resolve from
`getIt` only while composing a screen/route or integrating the application root.

After changing annotations or constructors:

```bash
derry gen
```

Never edit generated config, use field injection, hide dependencies in globals,
or make feature Cubits/BLoCs singletons.
