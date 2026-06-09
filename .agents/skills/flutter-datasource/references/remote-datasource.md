# Remote API — Retrofit

## Pattern: concrete Retrofit class, no abstract interface

```dart
// shared/api/auth/auth_remote_api.dart
@RestApi()
@injectable
abstract class AuthRemoteApi {
  @factoryMethod
  factory AuthRemoteApi(Dio dio) = _AuthRemoteApi;

  @POST('/auth/login')
  Future<LoginResponse> login(@Body() LoginRequest body);

  @GET('/auth/me')
  Future<User> getMe();
}
```

## Key points

- Class naming: `{Domain}RemoteApi` (not DataSource)
- Returns model classes directly (e.g. `User`, `LoginResponse`) — no Entity/Model distinction
- `@injectable` + `@factoryMethod` for DI registration — no separate module needed
- No abstract interface — Retrofit generates the implementation via `_AuthRemoteApi`
- Location: `shared/api/{domain}/{domain}_remote_api.dart`

## Retrofit annotation reference

| Annotation | When to use |
|---|---|
| `@GET('/path')` | Fetch data |
| `@POST('/path')` | Create resource |
| `@PUT('/path')` | Full update |
| `@PATCH('/path')` | Partial update |
| `@DELETE('/path')` | Delete |
| `@Path('id')` | Path param -> `/products/{id}` |
| `@Query('page')` | Query param -> `?page=1` |
| `@Body()` | Send a JSON object |
| `@Field('key')` | Form field (multipart/form-data) |
| `@Part()` | File upload (multipart) |

## Run codegen after changes

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```
