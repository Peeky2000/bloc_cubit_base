# Utility Checklist — {utility-name}

- Spec: `docs/specs/{id}-{name}/fe.md` §6.6
- Skill: `project-convention`

- [ ] Search app-memory before creating
- [ ] Document pure inputs, output, null/error policy, and ownership
- [ ] Place feature-only code near `lib/presentation/{feature}/`; place app-wide
  infrastructure under the matching existing `lib/core/` area
- [ ] No BuildContext, service locator, hidden mutable global, or layer violation
- [ ] Unit tests cover boundaries and malformed input
- [ ] `derry quality`
