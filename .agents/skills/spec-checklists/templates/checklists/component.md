# Component Checklist — {component-name}

- Spec: `docs/specs/{id}-{name}/fe.md` §6.7
- Skill: `flutter-atomic-design`

- [ ] Reuse search completed in app-memory and `sli_common`
- [ ] Ownership selected: `sli_common` cross-product, `lib/core/widget/`
  app-reusable, or `lib/presentation/{feature}/view/` feature-specific
- [ ] Stable constructor documents every typed required/optional property
- [ ] Component receives data/callbacks and owns no feature Cubit/BLoC
- [ ] Default/loading/disabled/error/empty states documented as applicable
- [ ] Uses semantic tokens, l10n, accessibility labels, and minimum touch targets
- [ ] Tests cover render, callbacks, variants, and accessibility semantics
- [ ] If shared toolkit changed, its analyze/tests pass and submodule pointer updates
