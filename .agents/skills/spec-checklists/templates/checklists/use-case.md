# UseCase Checklist — {use-case-name}

- Spec: `docs/specs/{id}-{name}/fe.md` §6.3
- Skill: `project-convention`

- [ ] `lib/domain/use_case/{name}_use_case.dart`
- [ ] Methods listed in spec implemented
- [ ] Calls repo(s) only — no UI
- [ ] Annotated `@lazySingleton` and constructor-injects repository interfaces
- [ ] No service-locator, Flutter, or UI dependency
- [ ] Run `derry gen`
- [ ] `flutter analyze`
