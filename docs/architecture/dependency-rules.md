# Quy Tắc Dependency

## Layers

| Layer | Sở hữu | Được import |
|---|---|---|
| `domain` | entities, repository contracts, use cases, domain failures | Chỉ Dart và domain |
| `data` | JSON models, data sources, repository implementations | domain, core an toàn cho infrastructure |
| `presentation` | screens, Cubits/BLoCs, UI effects | domain, core an toàn cho presentation |
| `core` | contract dùng chung và adapter framework | không chứa feature implementation |
| `di` | composition root | mọi layer |

## Quy tắc bắt buộc

1. Widget không bao giờ gọi API, repository, hoặc data source.
2. Cubit và BLoC gọi use case, không gọi repository hoặc data source.
3. Domain không bao giờ import `data`, Flutter widget, Dio, Firebase, hoặc GetIt.
4. Presentation không import data model cụ thể khi domain type đã diễn đạt được
   contract.
5. Class nhận dependency qua constructor. `getIt` chỉ được dùng ở composition
   root và factory tạo route/widget provider.
6. Setup external package nằm trong Injectable module, không nằm trong feature
   class.

Các quy tắc này được enforce bằng review và `scripts/check_architecture.sh`.
