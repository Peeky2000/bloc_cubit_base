---
description: Audit bảo mật app Flutter theo các nhóm tấn công mobile, báo cáo tiếng Việt vào docs/reviews
argument-hint: "[phạm vi: bỏ trống cho cả app, hoặc ví dụ: đăng nhập và token, deep link, nhánh feature/x]"
---

Run a defensive security audit of this Flutter app. Scope from the PM:
$ARGUMENTS

Read `.agents/skills/mobile-security-privacy/SKILL.md` and
`.agents/skills/mobile-security-privacy/references/mobile-attack-classes.md`
first and follow them exactly. This is a review: do not edit code unless the
PM explicitly asks for fixes in the scope.

1. **Scope.**
   - Empty scope: the whole app (`lib/`, `android/`, `ios/`, `pubspec.yaml`).
   - A feature or topic: only the code and config that implement it.
   - A branch or "changes": run `dart run tool/review/plan.dart --from=<base>`
     and audit only the reviewable files, using their rule groups.
   State the scope at the top of the report.
2. **Map the surface before hunting.** List entry points (routes and deep
   links, intent filters, URL schemes, WebViews, push handlers, platform
   channels), data stores (secure storage, SharedPreferences, caches, files),
   network setup (base URLs, interceptors, TLS, inspectors) and the auth and
   session flow. Read the merged-manifest inputs in every `android/app/src/*`
   flavor and every `Info.plist`.
3. **Hunt by attack class** from `mobile-attack-classes.md`: deep links and
   callbacks, WebView bridges, exported components, storage and tokens,
   logout and account switch, network. For each candidate, name the
   lower-trust actor, controlled input, intended control, crossed boundary
   and concrete result. Drop candidates that cannot name all five.
4. **Refute before reporting.** Re-read every cited line and look for the
   guard, server check or platform control that stops it. When subagents are
   available, give each candidate to a fresh verifier that did not find it.
5. **Classify.** `confirmed` (complete source trace; gets severity critical,
   high, medium, low or informational), `needs_validation` (decided by a fact
   outside the repo; name it and a safe way to check; no severity) or
   `rejected` (disproved; keep it listed).
6. **Never** contact production or shared services, use real credentials,
   print secrets, or test beyond the minimum local result.
7. **Report** in Vietnamese to
   `docs/reviews/YYYY-MM-DD-hh-mm-ss-security-audit.md`:
   - scope, commit, what was mapped, and what was not covered;
   - a summary table: id, verdict, severity, title, file:line;
   - for each confirmed finding: actor, steps, impact, evidence, smallest fix
     and the regression test to add;
   - for each needs_validation item: the missing fact and how to check it;
   - rejected candidates in one short list;
   - next steps for the PM, such as which fixes to schedule.
8. Run `derry quality` only if code was changed. Finish with a three-line
   summary in the conversation and the report path.
