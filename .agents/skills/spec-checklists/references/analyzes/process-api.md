# Process part: api (DataSource)

Use this reference when processing the **api** part in the checklists workflow (Step 3).

## When needed

- **Needed** if section **6.4 API** in `fe.md` lists any API endpoints.
- Create a checklist for each endpoint group (by feature/datasource) in §6.4. Exclude optional/TBD if clearly out of scope.

## Template

[`../../templates/checklists/api.md`](../../templates/checklists/api.md)

## Entity naming & list files

- **Path pattern:** `docs/specs/{id}-{name}/checklists/api/{entity-name}.md`
- **Entity name:** all lowercase, kebab-case, derived from the datasource name (e.g. `auth-remote-datasource`, `order-remote-datasource`). Group all endpoints of the same feature datasource into one file when possible.

## Path verification

- DataSource files live in `lib/presentation/{feature}/data/datasources/`.
- Before filling **Location**: grep/glob to verify actual path in the project. Use **actual path**, not blindly from spec.

## Analyze & brainstorm

- HTTP method, URL path, request/response shape from spec §6.4.
- Which Model (from §6.2) does each endpoint return?
- Error scenarios: 4xx, 5xx, network error, timeout.
- State management: which BLoC/Cubit (from §6.8) drives this API call?

## Fill content & verify

- Fill all "Output" blocks with endpoint details, Retrofit annotations, request/response types, and verified locations.
- Unit test cases: one checkbox per case (success, ServerException, NetworkException).
- Delete all `<!-- Note: ... -->` lines after filling.
- Verify every endpoint in §6.4 that is in scope has coverage in a checklist.
