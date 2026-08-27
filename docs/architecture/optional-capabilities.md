# Optional Capabilities

The base stays useful by keeping product-dependent infrastructure optional.

| Capability | Status | Adoption gate |
|---|---|---|
| GraphQL | Deferred | A real API schema and operations require it |
| Deep links | Deferred | Product routes and ownership rules are known |
| Firebase Messaging | Deferred | Notification contracts and navigation are known |
| HydratedBloc | Deferred | A state has an explicit persistence requirement |
| Freezed state unions | Deferred | Manual state demonstrably harms correctness |
| Advanced VIPER/AI gates | Later phase | Core base and docs are stable |

Optional modules must be independently removable and must not weaken the default REST,
Cubit/BLoC, or Clean Architecture path.
