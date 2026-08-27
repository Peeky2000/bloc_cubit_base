# Environment and Bootstrap

Entry points choose one typed environment and delegate immediately to
`bootstrap(...)`. They do not initialize plugins or register feature dependencies.

Bootstrap order:

1. Ensure Flutter bindings.
2. Install guarded error reporting and `BlocObserver`.
3. Validate immutable environment configuration.
4. Configure the dependency graph, including pre-resolved plugin dependencies.
5. Apply device policy.
6. Start optional non-production diagnostics.
7. Call `runApp`.

Environment values are compile-time `--dart-define` inputs with safe local placeholders.
Secrets must not be stored in `.env` or committed flavor files. Invalid base URLs fail
before the first network request.
