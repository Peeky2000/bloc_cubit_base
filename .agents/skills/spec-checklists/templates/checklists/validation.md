# Validation Checklist — {validation-name}

- Spec: `docs/specs/{id}-{name}/fe.md` §6.5
- Skills: `flutter-bloc-cubit`, `flutter-translations`, `app-memory`

- [ ] Search existing validators with `mem_search.py`
- [ ] Define input shape, typed result/error code, normalization, and edge cases
- [ ] Keep validation testable without BuildContext or service locator
- [ ] Cubit/BLoC stores typed field errors; widget maps them through `context.l10n`
- [ ] ARB keys exist for every supported locale
- [ ] Unit tests cover valid, required, boundary, malformed, and normalized input
- [ ] `derry quality`
