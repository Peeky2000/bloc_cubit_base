# API / DataSource Checklist — {api-name}

## Prerequisites

<!-- Note: Description: List the spec file this datasource is derived from. Output: Fill in the actual path below. -->

- Spec file: `docs/specs/{id}-{name}/fe.md`
- Derived from: section `6.4 API` in `fe.md`

---

## Required Skills

Before implementing, read the following skills:

- [ ] `flutter-datasource` skill — RemoteDataSource rules: abstract interface, Retrofit implementation, no business logic
- [ ] `flutter-di` skill — `@Injectable(as: ...)` registration with get_it + injectable
- [ ] `flutter-error-handling` skill — throw exceptions, never swallow errors

---

## 1. Remote DataSource Interface

> Follow `flutter-datasource` skill — abstract-before-impl rule. Interface lives in the data layer.

<!-- Note: Description: Identify the datasource name, location, and method signatures from spec §6.4. Output: Fill in the actual values below. -->

- [ ] **Interface name:** `{FeatureName}RemoteDataSource` (e.g. `AuthRemoteDataSource`)
- [ ] **Location:** `lib/features/{feature}/data/datasources/{feature_name}_remote_datasource.dart`
- [ ] **Methods:**
  <!-- Note: Description: List every API method — one per endpoint from spec §6.4 summary table. Output: Replace with real signatures. -->
  - [ ] `Future<{ModelName}> {methodName}({params})` — `{description}`
- [ ] Returns Models (not Entities) — conversion to Entity is the Repository's responsibility
- [ ] No business logic, no filtering, no transformation — only data transport

---

## 2. Retrofit Implementation

> Follow `flutter-datasource` skill — Retrofit annotations, throw-dont-catch rule.

<!-- Note: Description: Identify HTTP method, URL, request/response shapes from spec §6.4. Output: Fill in the actual values below. -->

- [ ] **Impl name:** `{FeatureName}RemoteDataSourceImpl` (interface name + `Impl`)
- [ ] **Location:** `lib/features/{feature}/data/datasources/{feature_name}_remote_datasource_impl.dart`
- [ ] **Endpoints:**
  <!-- Note: Description: One row per API endpoint from spec §6.4. Output: Replace with real endpoint details. -->
  - [ ] `@{GET|POST|PUT|DELETE}('{path}')` → `Future<{ModelName}> {methodName}({@Body() | @Query() | @Path()} params)`
  - [ ] HTTP method: `{GET | POST | PUT | DELETE}`
  - [ ] URL path: `{endpoint path from spec}`
  - [ ] Request body type: `{ModelName | none}` (POST/PUT/PATCH only)
  - [ ] Response type: `{ModelName}` — maps to Model from §6.2
- [ ] Annotated with `@Injectable(as: {FeatureName}RemoteDataSource)`
- [ ] Exceptions bubble up — no try/catch unless changing exception type

---

## 3. Unit Tests

>

- [ ] **Test file:** `test/features/{feature}/data/datasources/{feature_name}_remote_datasource_test.dart`
- [ ] Test cases:
  <!-- Note: Description: Plan test cases for each endpoint. Output: Replace with real test cases. -->
  - [ ] **Test case:** should call correct endpoint and return mapped Model on success — Input: mock Dio returns valid JSON | Expected: `{ModelName}` returned
  - [ ] **Test case:** should throw ServerException when API returns 4xx/5xx — Input: mock Dio throws `DioException` with error response | Expected: `ServerException` thrown
  - [ ] **Test case:** should throw NetworkException when no connection — Input: mock Dio throws `DioException` with connection error | Expected: `NetworkException` thrown

---

_Instruction: The `<!-- Note: ... -->` lines guide the Agent in filling actual content. After filling the "Output", delete all Note lines before starting implementation._
