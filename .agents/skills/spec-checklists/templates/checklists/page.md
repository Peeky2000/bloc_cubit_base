# Screen Checklist — {screen-name}

- Spec: `docs/specs/{id}-{name}/fe.md` §6.9
- Skills: `flutter-bloc-cubit`, `flutter-atomic-design`, `flutter-router`,
  `flutter-translations`

- [ ] `{Feature}Screen` and `{feature}ScreenBuilder()` at
  `lib/presentation/{feature}/view/{feature}_screen.dart`
- [ ] Builder resolves the annotated Cubit/BLoC once and uses `BlocProvider`
- [ ] Screen renders initial/loading/empty/error/success states from the spec
- [ ] `BlocListener`/`BlocConsumer` owns one-shot navigation/dialog effects
- [ ] Route argument keys/types are documented and validated
- [ ] Reuses `Sli*` or existing app widgets before creating feature UI
- [ ] No API/repository calls or business logic in widgets
- [ ] User-facing copy uses `context.l10n`; accessibility/touch states covered
- [ ] Widget tests cover state rendering, primary interaction, and navigation
- [ ] `derry quality`
