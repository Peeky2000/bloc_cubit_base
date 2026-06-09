# Rules — Checklist: bloc-cubit

## When to create

- **Create** for every BLoC or Cubit in `fe.md` section **6.8 BLoC / Cubit**.
- Typically **one per screen**, but may have more if the screen has independent state concerns.

## Fill rules

- **Entity name:** all lowercase, kebab-case derived from the cubit/bloc name (e.g. `user-list-cubit`, `auth-bloc`).
- **Type decision:** must be explicitly `Cubit` or `BLoC` with justification. Default is Cubit.
- **Location:** must be verified via grep/glob. Lives in `lib/presentation/{feature}/presentation/bloc/`.
- **State variants:** must include at minimum `initial`, `loading`, `success`, `error`. Add others only if spec specifies.
- **State data:** `success` state fields must use Entity types from §6.1 — never Models.
- **Methods/Events coverage:** every user action in spec §6.9 Page must have a corresponding method (Cubit) or event (BLoC).
- **Unit test cases:** initial state, [loading, success] per method/event, [loading, error] per method/event.
- **Placeholders:** delete all `<!-- Note: ... -->` lines and all `{placeholder}` tokens after filling.

## Review rules

- [ ] Every BLoC/Cubit in fe.md section 6.8 has a corresponding checklist file.
- [ ] Type decision (`Cubit` / `BLoC`) is explicitly stated with justification.
- [ ] Location is a real, verified path under `presentation/bloc/`.
- [ ] `initial`, `loading`, `success`, `error` state variants are all defined.
- [ ] `success` state fields use Entity types — no Models.
- [ ] Every user action in §6.9 has a corresponding method or event.
- [ ] No `bool isLoading` pattern — all states expressed as sealed variants.
- [ ] Unit test cases cover: initial state, [loading, success], [loading, error].
- [ ] No `<!-- Note: ... -->` or unfilled `{}` placeholders remain.
