# Naming Conventions

## File Names — `snake_case`

| Artifact | Pattern | Example |
|----------|---------|---------|
| Repository | `<domain>_repository.dart` | `auth_repository.dart` |
| Remote API | `<domain>_remote_api.dart` | `auth_remote_api.dart` |
| Local API | `<domain>_local_api.dart` | `auth_local_api.dart` |
| Model | `<name>_model.dart` | `auth_token_model.dart`, `user_model.dart` |
| BLoC | `<feature>_bloc.dart` | `auth_bloc.dart` |
| BLoC Event | `<feature>_event.dart` | `auth_event.dart` |
| BLoC State | `<feature>_state.dart` | `auth_state.dart` |
| Cubit | `<feature>_cubit.dart` | `product_cubit.dart` |
| Cubit State | `<feature>_state.dart` | `product_state.dart` |
| Page | `<feature>_page.dart` | `login_page.dart` |
| Widget (atom) | `app_<name>.dart` | `app_text_field.dart`, `app_button.dart` |
| Widget (molecule/organism) | `<name>.dart` | `password_field.dart`, `login_form.dart` |
| Drift table | `<domain>_table.dart` | `transactions_table.dart` |
| Drift DAO | `<domain>_dao.dart` | `transaction_dao.dart` |
| Mapper | `<domain>_mapper.dart` | `transaction_mapper.dart` |

## Class Names — `PascalCase`

| Artifact | Pattern | Example |
|----------|---------|---------|
| Repository (concrete) | `<Domain>Repository` | `AuthRepository` |
| Remote API | `<Domain>RemoteApi` | `AuthRemoteApi` |
| Local API | `<Domain>LocalApi` | `AuthLocalApi` |
| Model (unified) | `<Name>Model` | `AuthTokenModel`, `UserModel` |
| BLoC | `<Feature>Bloc` | `AuthBloc` |
| Event (sealed wrapper) | `<Feature>Event` | `AuthEvent` |
| Event (variant) | `<Feature><Action>` | `AuthLoginRequested`, `AuthLogoutRequested` |
| State (sealed wrapper) | `<Feature>State` | `AuthState` |
| State (variant) | `<Feature><Variant>` | `AuthLoading`, `AuthAuthenticated`, `AuthError` |
| Cubit | `<Feature>Cubit` | `ProductCubit` |
| Page | `<Feature>Page` | `LoginPage`, `ProductListPage` |
| Atom widget | `App<Name>` | `AppTextField`, `AppButton` |
| Drift DAO | `<Domain>Dao` | `TransactionDao` |

## Variables & Methods

| Type | Convention | Example |
|------|-----------|---------|
| Private fields | `_camelCase` | `_repository`, `_emailController` |
| Public fields | `camelCase` | `email`, `products` |
| Methods | `camelCase` | `loadProducts()`, `submitForm()` |
| BLoC event handlers | `_on<EventName>` | `_onLoginRequested`, `_onLogoutRequested` |
| Constants | `camelCase` (class member) | `AppConstants.accessTokenKey` |
| Color/style class | `abstract final class` | `AppColors`, `AppTextStyles` |

## Translation Keys

Pattern: `feature.field` or `feature.field.sub`

```
login.title
login.email
login.password_too_short
products.title
products.empty
cart.checkout_button
common.retry
common.error
common.loading
```

## Route Paths & Names

- Path: `kebab-case` → `/product-detail/:id`
- Route key constant: `camelCase` in `AppRoutes` → `AppRoutes.productDetail`
