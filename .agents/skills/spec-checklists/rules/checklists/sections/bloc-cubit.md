# Rules — Cubit/BLoC Checklist

Create for every state owner in spec §6.8. Cubit is default; document why classic
BLoC is needed. Verify location under `lib/presentation/{feature}/`, immutable
`BaseAppState + Equatable + copyWith`, domain-typed data, constructor-injected
UseCase, `@injectable` factory scope, async lifecycle, UI-effect boundary, and
bloc_test coverage. Do not require sealed Freezed variants.
