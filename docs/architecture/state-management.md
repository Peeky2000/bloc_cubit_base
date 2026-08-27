# State Management

## Default choice

Use Cubit for command-oriented screen state. Use classic BLoC when event identity,
event concurrency, debounce/restartable behavior, multiple event sources, or an audit
trail materially improves correctness.

Both styles are first-class and use constructor-injected use cases.

## State shape

- Keep `BaseAppState + Equatable + copyWith`.
- State is immutable.
- Loading and failures are typed; do not use `dynamic` state errors.
- UI-only one-shot effects must be explicit presentation output, not navigation or
  dialogs called from a Cubit/BLoC.
- Do not introduce Freezed or HydratedBloc by default.

## Lifetime

- Feature Cubits/BLoCs are factories and are closed by `BlocProvider`.
- App-scope state is allowed only for genuine app-scope concerns such as locale or
  session status.
