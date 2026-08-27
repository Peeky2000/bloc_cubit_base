# Networking

REST through Dio is the default transport. `ApiHandler` is the application-facing
adapter and data sources own response parsing.

## Security and lifecycle

- Interceptors never navigate, show dialogs, or read a `BuildContext`.
- Authentication adds credentials through a token-store contract.
- Refresh is single-flight: concurrent 401 responses await one refresh operation.
- Refresh requests use a dedicated Dio client and never recurse through the session
  interceptor.
- Session expiry is emitted through a session contract and handled in presentation.
- Request/response logs redact authorization, cookies, tokens, passwords, and common
  PII fields by default.
- Alice is available only outside production.

GraphQL is an optional capability and must not be added until a product requires it.
