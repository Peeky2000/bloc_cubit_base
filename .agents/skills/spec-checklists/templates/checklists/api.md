# API / DataSource Checklist — {api-name}

- Spec: `docs/specs/{id}-{name}/fe.md` §6.4
- Skills: `flutter-datasource`, `flutter-di`, `flutter-error-handling`

## Contract and implementation

- [ ] Abstract `{Feature}RemoteDataSource` and implementation share
  `lib/data/datasource/remote/{feature}_remote_data_source.dart`
- [ ] Implementation is bound with
  `@LazySingleton(as: {Feature}RemoteDataSource)`
- [ ] `ApiHandler` is constructor-injected; no service locator
- [ ] Endpoint is defined in `UrlEndPoint`
- [ ] Each method documents HTTP verb, path, request model/body, response model,
  and parser callback
- [ ] Returns data models to the repository and propagates typed failures
- [ ] No business rules, UI, navigation, translation, or raw secret logging

## Tests and generation

- [ ] `test/data/datasource/remote/{feature}_remote_data_source_test.dart`
  covers success parsing and representative transport failure
- [ ] Security-sensitive changes cover redaction/session behavior
- [ ] `derry gen` and `derry quality`
