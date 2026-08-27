# Dependency Injection

The base uses `get_it` as the runtime container and `injectable` as the registration
generator.

## Rules

- Add `@injectable`, `@lazySingleton`, or `@singleton` to owned classes.
- Bind repository/data-source implementations to their abstract contract with
  `@LazySingleton(as: Contract)`.
- Cubits and BLoCs are factories (`@injectable`) unless application lifetime is an
  explicit ADR decision.
- Use `@module` for SDK classes, plugins, async initialization, and factories that need
  runtime configuration.
- A feature class must never call `Injector.getIt`.
- Entry points may pass the selected environment to the composition root. This is the
  only intentional runtime registration.

Generate registrations with `derry gen` or `dart run build_runner build`.
