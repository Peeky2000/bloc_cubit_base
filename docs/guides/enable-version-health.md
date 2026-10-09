# Bật Version Health

Hướng dẫn này dành cho app fork từ base, khi app đã có Firebase project riêng.
Base chỉ cung cấp một lớp trung gian, gọi là seam. Base không cài Firebase
Analytics, Crashlytics, Performance hay Remote Config. Lý do nằm ở
[ADR 0006](../adr/0006-ui-toolkit-now-defer-product-capabilities.md).

## Seam làm gì

Code nằm ở `lib/core/observability/`. Có bốn interface nhỏ và một bundle.

| Interface | Dùng để | Bản mặc định trong base |
|---|---|---|
| `CrashReporter` | Ghi crash, lỗi non-fatal, breadcrumb, user id đã hash | `LocalCrashReporter` |
| `AnalyticsTracker` | Ghi screen view và event | `LocalAnalyticsTracker` |
| `PerformanceTracer` | Đo một đoạn việc có tên, như tải danh sách | `LocalPerformanceTracer` |
| `FeatureFlags` | Đọc flag có kiểu, có default trong code | `LocalFeatureFlags` |
| `Observability` | Gom bốn thứ trên, áp quy tắc an toàn | `Observability.local()` |

Bản mặc định không gửi gì ra ngoài. Ở bản debug, nó in dòng log đã che dữ liệu
cá nhân, với tag `observability`. Ở bản profile và release, nó im lặng.

Seam đã được nối sẵn:

- `lib/bootstrap.dart` tạo `UncaughtErrorForwarder` ngay dòng đầu. Lỗi từ
  `FlutterError.onError`, `PlatformDispatcher.onError` và `runZonedGuarded`
  vẫn được log như cũ, rồi chuyển tới `CrashReporter`.
- Lỗi xảy ra trước khi DI sẵn sàng được giữ lại, tối đa 20 lỗi. Khi DI xong,
  chúng được gửi đi.
- `SLIRouteObserver` báo screen view khi push, pop, replace và remove. Chỉ tính
  màn hình đầy đủ. Dialog và bottom sheet không tính.
- Sau khi DI xong, bootstrap gọi `flags.refresh()` ở nền. Flag giữ default cho
  tới khi refresh thành công.
- `lib/di/register_module.dart` đăng ký `Observability`. DI cũng đăng ký riêng
  `CrashReporter`, `AnalyticsTracker`, `PerformanceTracer` và `FeatureFlags`.
  Class cần dùng thì nhận qua constructor.
- `AppConfig.observabilityEnabled` quyết định có dùng adapter từ xa hay không.
  Giá trị mặc định là `false` cho mọi môi trường.

### Quy tắc an toàn đã có sẵn

`Observability` luôn bọc adapter bằng lớp kiểm tra. Adapter Firebase của bạn
không cần tự làm lại các việc sau.

- **Lỗi:** text lỗi và `reason` đi qua `DiagnosticRedactor`. Adapter nhận
  `RedactedError`, kèm stack trace gốc.
- **Redactor:** dùng lại luật của `NetworkRedactor`. Che thêm JWT, query của
  URL, email và dãy số dài như số điện thoại.
- **User id:** chỉ nhận chuỗi hex dài 16 tới 128 ký tự, tức là giá trị đã hash.
  Email hay số điện thoại bị bỏ qua.
- **Event:** tên và key phải khớp `[A-Za-z][A-Za-z0-9_]{0,39}`. Không dùng tiền
  tố `firebase_`, `google_`, `ga_`.
- **Tham số:** chỉ nhận `bool`, `int`, `double` hữu hạn và `String`. Bỏ key chỉ
  dữ liệu cá nhân như `email`, `phone`, `user_id`, `token`. Bỏ chuỗi trông như
  dữ liệu cá nhân. Cắt chuỗi còn 100 ký tự. Giữ tối đa 25 tham số.
- **Screen name:** bỏ phần `?query` và `#fragment`.
- **Trace:** tên khớp `[A-Za-z][A-Za-z0-9_]{0,99}`. Tối đa 5 attribute. `stop()`
  chỉ chạy một lần.
- **Flag:** refresh lỗi hoặc quá 10 giây thì trả `false` và giữ giá trị cũ. Đọc
  lỗi hoặc sai kiểu thì trả default.
- **Lỗi adapter:** mọi lỗi của adapter bị nuốt. Telemetry không bao giờ làm hỏng
  điều hướng hay luồng xử lý lỗi.

## Dùng seam trong code

Nhận interface qua constructor. Không gọi `getIt` trong Cubit, UseCase hay
repository.

```dart
@injectable
class OrdersCubit extends Cubit<OrdersState> {
  OrdersCubit(this._useCase, this._tracer, this._analytics, this._flags)
    : super(const OrdersState());

  final OrdersUseCase _useCase;
  final PerformanceTracer _tracer;
  final AnalyticsTracker _analytics;
  final FeatureFlags _flags;

  Future<void> load() async {
    final trace = _tracer.start('load_orders');
    try {
      final pageSize = _flags.value(AppFlags.ordersPageSize);
      final orders = await _useCase.load(pageSize: pageSize);
      trace.setAttribute('result', orders.isEmpty ? 'empty' : 'some');
      unawaited(
        _analytics.event('orders_loaded', params: {'count': orders.length}),
      );
    } finally {
      await trace.stop();
    }
  }
}
```

Khai báo flag ở một chỗ để review default cùng nhau:

```dart
abstract final class AppFlags {
  static const newCheckout = FeatureFlag('new_checkout_enabled', false);
  static const ordersPageSize = FeatureFlag('orders_page_size', 20);
}
```

Domain không import `core/observability`. Đặt trace và event ở Cubit, BLoC hoặc
data layer.

## Bật Firebase trong app fork

Làm từng bước. Sau mỗi bước, build bản test và kiểm tra trên console.

### 1. Chốt trước khi code

- Mỗi flavor dùng Firebase project nào: `dev`, `staging`, `prod`.
- Ai quản lý console. Ai có quyền publish Remote Config.
- Chính sách consent và thời gian lưu dữ liệu.
- Ngưỡng Version Health, cỡ mẫu tối thiểu và đường rollback.

Nên dùng project riêng cho `prod`. Như vậy dữ liệu test không làm bẩn dashboard
thật.

### 2. Thêm package

```bash
fvm flutter pub add firebase_analytics firebase_crashlytics firebase_performance firebase_remote_config
```

Base đang dùng `firebase_core ^3.6.0`. Với ràng buộc này, pub chọn
`firebase_core 3.15.x`, `firebase_analytics 11.x`, `firebase_crashlytics 4.x`,
`firebase_performance 0.10.x` và `firebase_remote_config 5.x`. Muốn lên major
mới thì nâng cả `firebase_core` và `firebase_auth` cùng lúc.

### 3. Chạy `flutterfire configure` cho từng flavor

Cài CLI một lần:

```bash
dart pub global activate flutterfire_cli
firebase login
```

Base đã có `android/app/src/<flavor>/google-services.json` và
`ios/config/<flavor>/GoogleService-Info.plist`. Chạy lệnh cho từng flavor để
file đúng chỗ. Thay `<project-dev>` và các bundle id bằng giá trị thật.

```bash
flutterfire configure \
  --project=<project-dev> \
  --platforms=android,ios \
  --android-package-name=<applicationId-dev> \
  --ios-bundle-id=<bundleId-dev> \
  --android-out=android/app/src/dev/google-services.json \
  --ios-out=ios/config/dev/GoogleService-Info.plist \
  --ios-build-config=Debug-dev \
  --out=lib/firebase_options_dev.dart
```

Lặp lại với `Release-dev` và `Profile-dev`, rồi với `staging` và `prod`. Build
configuration của iOS có dạng `Debug-<flavor>`, `Profile-<flavor>` và
`Release-<flavor>`.

Lệnh này cũng sửa file native:

- Android: thêm Gradle plugin của Crashlytics và Performance.
- iOS: thêm build phase `FlutterFire: "flutterfire upload-crashlytics-symbols"`
  để tải dSYM lên.

Xem lại diff của các file `android/` và `ios/` trước khi commit.

### 4. Kiểm tra Gradle plugin Android

Nếu CLI không tự thêm, sửa tay như sau. Trong `android/settings.gradle`:

```groovy
plugins {
    // ...
    id "com.google.gms.google-services" version "4.4.3" apply false
    id "com.google.firebase.crashlytics" version "3.0.8" apply false
    id "com.google.firebase.firebase-perf" version "2.0.2" apply false
}
```

Trong `android/app/build.gradle`:

```groovy
plugins {
    id "com.android.application"
    id "com.google.gms.google-services"
    id "com.google.firebase.crashlytics"
    id "com.google.firebase.firebase-perf"
    id "org.jetbrains.kotlin.android"
    id "dev.flutter.flutter-gradle-plugin"
}
```

Lấy version mới nhất trong tài liệu Firebase cho Android.

### 5. Kiểm tra dSYM trên iOS

- Trong Xcode, target `Runner`, đặt `Debug Information Format` là
  `DWARF with dSYM File` cho mọi build configuration Release.
- Kiểm tra build phase upload symbols nằm sau bước copy `GoogleService-Info.plist`.
- Nếu build với `--obfuscate --split-debug-info=build/symbols`, tải symbol
  Flutter lên bằng tay:

```bash
firebase crashlytics:symbols:upload --app=<FIREBASE_APP_ID> build/symbols
```

### 6. Viết adapter

Tạo file `lib/core/observability/firebase_observability.dart` trong app fork.
Đoạn code dưới đây đã được analyze sạch với các version ở bước 2.

```dart
import 'package:bloc_cubit_base/core/observability/observability.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Gọi sau `Firebase.initializeApp()`. Truyền vào `Observability.select`.
Observability createFirebaseObservability() => Observability(
  crash: FirebaseCrashReporter(FirebaseCrashlytics.instance),
  analytics: FirebaseAnalyticsTracker(FirebaseAnalytics.instance),
  performance: FirebasePerformanceTracer(FirebasePerformance.instance),
  flags: FirebaseFeatureFlags(FirebaseRemoteConfig.instance),
);

final class FirebaseCrashReporter implements CrashReporter {
  FirebaseCrashReporter(this._crashlytics);

  final FirebaseCrashlytics _crashlytics;

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
  }) => _crashlytics.recordError(error, stack, fatal: fatal, reason: reason);

  @override
  Future<void> log(String message) => _crashlytics.log(message);

  @override
  Future<void> setUserIdentifier(String hashedId) =>
      _crashlytics.setUserIdentifier(hashedId);
}

final class FirebaseAnalyticsTracker implements AnalyticsTracker {
  FirebaseAnalyticsTracker(this._analytics);

  final FirebaseAnalytics _analytics;

  @override
  Future<void> screenView(String name) =>
      _analytics.logScreenView(screenName: name);

  @override
  Future<void> event(String name, {Map<String, Object> params = const {}}) =>
      _analytics.logEvent(
        name: name,
        // Firebase nhận String hoặc num; đổi bool thành 0/1.
        parameters: {
          for (final MapEntry(:key, :value) in params.entries)
            key: value is bool ? (value ? 1 : 0) : value,
        },
      );
}

final class FirebasePerformanceTracer implements PerformanceTracer {
  FirebasePerformanceTracer(this._performance);

  final FirebasePerformance _performance;

  @override
  TraceHandle start(String name) {
    final trace = _performance.newTrace(name);
    return _FirebaseTrace(trace, trace.start());
  }
}

final class _FirebaseTrace implements TraceHandle {
  _FirebaseTrace(this._trace, this._started);

  final Trace _trace;
  final Future<void> _started;

  @override
  void setAttribute(String name, String value) =>
      _trace.putAttribute(name, value);

  @override
  Future<void> stop() async {
    await _started;
    await _trace.stop();
  }
}

final class FirebaseFeatureFlags implements FeatureFlags {
  FirebaseFeatureFlags(this._remoteConfig);

  final FirebaseRemoteConfig _remoteConfig;

  @override
  T value<T extends Object>(FeatureFlag<T> flag) {
    final remote = _remoteConfig.getValue(flag.key);
    // Key chưa publish hoặc chưa fetch: dùng default trong code.
    if (remote.source != ValueSource.valueRemote) {
      return flag.defaultValue;
    }
    final raw = remote.asString().trim();
    final Object? parsed = switch (flag.defaultValue) {
      bool() => switch (raw.toLowerCase()) {
        'true' => true,
        'false' => false,
        _ => null,
      },
      int() => int.tryParse(raw),
      double() => double.tryParse(raw),
      String() => remote.asString(),
      _ => null,
    };
    // Sai kiểu trên console: dùng default trong code.
    return parsed is T ? parsed : flag.defaultValue;
  }

  @override
  Future<bool> refresh() async {
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );
    return _remoteConfig.fetchAndActivate();
  }
}
```

Vì sao adapter ngắn: redaction, kiểm tra tên, giới hạn tham số, timeout và xử
lý lỗi đã nằm trong `Observability`. Adapter chỉ chuyển lời gọi sang SDK.

Không gọi `FirebaseCrashlytics.instance.recordFlutterFatalError` trong
`FlutterError.onError`. Bootstrap đã chuyển lỗi qua `CrashReporter`. Gán thêm
handler sẽ làm mất bước redaction và có thể ghi trùng.

### 7. Nối adapter vào DI và bật cờ

Trong `lib/di/register_module.dart`, thêm `remote`:

```dart
@lazySingleton
Observability observability(AppConfig config) => Observability.select(
  enabled: config.observabilityEnabled,
  remote: createFirebaseObservability,
);
```

Nếu `remote` ném lỗi, ví dụ Firebase chưa khởi tạo, app tự quay về bản local.

Bật theo môi trường trong `AppConfig.forEnvironment`, ở `defaultValue` của
`observabilityEnabled`. Hoặc bật lúc build:

```bash
fvm flutter run --flavor dev -t lib/main_dev.dart --dart-define=ENABLE_OBSERVABILITY=true
```

Khi app có màn consent, đừng bật cứng. Hãy tắt thu thập cho tới khi người dùng
đồng ý (xem phần sau).

### 8. Kiểm tra trên bản test

- Analytics: mở DebugView, kiểm tra `screen_view` và event của bạn.
- Crashlytics: tạo một lỗi thử ở bản release, mở lại app, chờ vài phút. Stack
  trace phải đọc được, tức là symbol đã lên.
- Performance: chạy một custom trace, so thời gian với thao tác thật.
- Remote Config: publish một flag, gọi `refresh()`, thấy giá trị đổi. Tắt mạng,
  mở app, thấy default.
- Mở từng event, crash và trace. Không được có email, số điện thoại, token hay
  URL chứa query.

## Consent và quy tắc dữ liệu

- Không gửi PII: tên, email, số điện thoại, địa chỉ, vị trí, token, payload của
  request hay response.
- User id gửi lên phải là hash một chiều có salt của app, ví dụ SHA-256. Không
  gửi id thô từ server.
- Tham số event là giá trị không định danh: số đếm, enum, cờ, bucket thời gian.
- Không dùng Remote Config để chứa secret. Ai cũng đọc được nó.
- Mọi flag phải có default an toàn trong code. App phải chạy đúng khi offline.
- Khi chưa có consent, tắt thu thập trước khi gửi bất kỳ dữ liệu nào:

```dart
await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(false);
await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
await FirebasePerformance.instance.setPerformanceCollectionEnabled(false);
```

  Bật lại sau khi người dùng đồng ý. Muốn tắt từ lần mở đầu tiên, đặt cấu hình
  native tương ứng theo tài liệu Firebase của từng SDK.
- Ghi lại thời gian lưu dữ liệu trên Firebase console và trong chính sách
  quyền riêng tư của app.

## Chỉ số Version Health cần theo dõi

Mỗi chỉ số đến từ một nguồn khác nhau. Đừng coi chúng là cùng một nhóm người
dùng. Các ngưỡng dưới đây chỉ là đề xuất. Product owner phải duyệt trước khi
dùng để quyết định rollout.

| Chỉ số | Nguồn | Ngưỡng tốt | Dừng rollout khi | Ghi chú |
|---|---|---|---|---|
| Crash-free users | Crashlytics | ≥ 99,5% | < 99% | Android vitals coi tỉ lệ crash trên 1,09% là kém |
| ANR rate (Android) | Play Console vitals | ≤ 0,2% | > 0,47% | 0,47% là ngưỡng kém của Android vitals |
| Cold start p90 | Performance (`_app_start`) | ≤ 2 giây | > 5 giây | Khớp mốc `startup_first_frame_ms` của benchmark |
| Slow frames | Performance và benchmark | ≤ 5% | > 25% | Firebase không đo render từng màn Flutter. Dùng custom trace hoặc `derry perf run` |
| Frozen frames | Performance và benchmark | ≤ 0,1% | > 1% | Frame trên 700 ms |
| Network p95 | Performance (HTTP/S) | ≤ 1 giây | > 3 giây | Đối chiếu redaction của Dio |
| Adoption theo version | Analytics (`app_version`) | Theo kế hoạch | Không đạt kế hoạch sau 7 ngày | Dùng để biết đã đủ mẫu chưa |

Quy tắc ra quyết định:

- Chỉ kết luận khi version mới đủ mẫu, ví dụ 1.000 user hoặc 10.000 phiên.
  Product owner chốt con số thật.
- So sánh version mới với version ổn định trước đó, cùng nền tảng và cùng cửa sổ
  thời gian.
- Rollout theo bậc, ví dụ 1%, 5%, 20%, 50%, 100%. Mỗi bậc quan sát ít nhất 24
  giờ.
- Vượt ngưỡng dừng: tạm ngưng rollout, tắt tính năng bằng flag nếu có, rồi
  quyết định hotfix hoặc rollback.
- Không tự động rollout hay rollback khi chưa có chính sách được duyệt.
- Dữ liệu `derry perf run` là phép đo trên máy test. Không trộn nó với số liệu
  từ người dùng thật.

## Câu hỏi còn mở

Lấy từ brainstorm. Cần trả lời trước khi bật trên production.

- Mỗi flavor dùng Firebase project nào, và ai quản lý console?
- Chính sách consent, thời gian lưu và loại dữ liệu được phép ghi là gì?
- Ngưỡng Version Health, cỡ mẫu tối thiểu, owner và đường rollback nào được
  duyệt?

## Gỡ bỏ

Seam không phụ thuộc Firebase. Muốn gỡ Firebase khỏi app fork, xoá file adapter,
bỏ `remote:` trong `register_module.dart` và gỡ package. App quay về bản local
mà không phải sửa Cubit hay màn hình nào.
