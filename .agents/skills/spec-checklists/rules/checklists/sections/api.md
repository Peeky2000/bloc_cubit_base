# Rules — Checklist: api (DataSource)

## When to create

- **Create** for each feature's RemoteDataSource listed in `fe.md` section **6.4 API**.
- **Exclude** optional/TBD endpoints that are clearly out of scope for this spec.

## Fill rules

- **Entity name:** all lowercase, kebab-case derived from the datasource name (e.g. `auth-remote-datasource`).
- **Interface location:** verify via grep/glob. DataSource interface lives in `lib/presentation/{feature}/data/datasources/`.
- **Impl location:** verify via grep/glob. Same folder as interface, with `_impl` suffix.
- **Endpoint details:** include HTTP method, URL path, Retrofit annotation, request shape (Model), response shape (Model).
- **Returns Models**, not Entities — `toEntity()` is the Repository's responsibility.
- **Error handling:** `ServerException` for 4xx/5xx, `NetworkException` for connectivity failures — no swallowing.
- **Unit test cases:** add at least one checkbox per case — success (correct Model returned), ServerException, NetworkException.
- **Placeholders:** delete all `<!-- Note: ... -->` lines and all `{placeholder}` tokens after filling.

## Review rules

- [ ] Every in-scope endpoint from fe.md section 6.4 has coverage in a checklist file.
- [ ] HTTP method, URL path, Retrofit annotations, request/response types are all specified.
- [ ] Response type is a Model from §6.2 — not an Entity.
- [ ] DataSource interface and impl locations are verified against the codebase.
- [ ] Error handling describes ServerException and NetworkException scenarios.
- [ ] Unit test cases cover: success, ServerException, NetworkException.
- [ ] No `<!-- Note: ... -->` or unfilled `{}` placeholders remain.
