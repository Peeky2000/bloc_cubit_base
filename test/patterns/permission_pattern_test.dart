// Reference implementation: runtime permissions.
//
// Pattern: .agents/skills/flutter-patterns/references/permission.md
// Decision: docs/decisions/D-0008-xin-quyen-runtime-qua-domain-port.md
//
// `permission_handler` is only a transitive dependency (through sli_common),
// and `PermissionUtil` in sli_common shows toasts and dialogs itself, which a
// Cubit cannot test. The pattern puts permission_handler behind a domain
// port (adapter sketch below; the app adds it as a direct dependency per
// D-0008) and keeps the flow in a testable Cubit.

import 'dart:async';

import 'package:bloc_cubit_base/core/base_component/base_app_state.dart';
import 'package:bloc_cubit_base/core/base_component/base_cubit.dart';
import 'package:bloc_cubit_base/core/base_component/ui_effect.dart';
import 'package:bloc_cubit_base/core/common/enum.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// lib/domain/repositories/permission_repo.dart
// ---------------------------------------------------------------------------

/// Capabilities the app asks for. Add a value only when a feature needs it
/// and the manifest/Info.plist declares it.
enum AppPermission { camera, photos, location, notifications }

/// One answer, the same on Android and iOS.
enum PermissionAccess {
  /// Full access.
  granted,

  /// iOS partial photo library or provisional notifications. Treat as
  /// usable; the feature works with what it got.
  limited,

  /// Not granted, and asking again shows the system dialog.
  denied,

  /// Not granted, and the system dialog will not appear again (Android
  /// "don't ask again", iOS after the first refusal). Only Settings helps.
  permanentlyDenied,

  /// Blocked by parental controls or MDM. Neither the app nor the user can
  /// change it.
  restricted,
}

abstract class PermissionRepo {
  /// Reads the current access without a dialog.
  Future<PermissionAccess> status(AppPermission permission);

  /// Shows the system dialog when the platform still allows one, and
  /// completes once with the answer. Concurrent calls for the same
  /// permission share one dialog and one answer.
  Future<PermissionAccess> request(AppPermission permission);

  /// Opens this app's page in system settings. False when it cannot.
  Future<bool> openSettings();
}

// Adapter sketch: lib/data/repositories/permission_handler_repo.dart
// Needs `permission_handler` as a direct dependency (D-0008).
//
//   @LazySingleton(as: PermissionRepo)
//   class PermissionHandlerRepo implements PermissionRepo {
//     final Map<AppPermission, Future<PermissionAccess>> _inFlight = {};
//
//     Permission _map(AppPermission p) => switch (p) {
//       AppPermission.camera => Permission.camera,
//       AppPermission.photos => Permission.photos,   // Android 13+; the
//       AppPermission.location => Permission.locationWhenInUse,
//       AppPermission.notifications => Permission.notification,
//     };   // Android ≤ 12 photos: Permission.storage (sdkInt from
//          // device_info_plus), as PermissionUtil does today.
//
//     PermissionAccess _access(PermissionStatus s) => switch (s) {
//       PermissionStatus.granted => PermissionAccess.granted,
//       PermissionStatus.limited ||
//       PermissionStatus.provisional => PermissionAccess.limited,
//       PermissionStatus.denied => PermissionAccess.denied,
//       PermissionStatus.permanentlyDenied =>
//         PermissionAccess.permanentlyDenied,
//       PermissionStatus.restricted => PermissionAccess.restricted,
//     };
//
//     @override
//     Future<PermissionAccess> status(AppPermission p) async =>
//         _access(await _map(p).status);
//
//     @override
//     Future<PermissionAccess> request(AppPermission p) =>
//         _inFlight[p] ??= _map(p).request().then(_access)
//             .whenComplete(() => _inFlight.remove(p));
//
//     @override
//     Future<bool> openSettings() => openAppSettings();
//   }

// ---------------------------------------------------------------------------
// lib/domain/use_case/permission_use_case.dart
// ---------------------------------------------------------------------------

/// What the feature should do next. A closed set, so every Screen handles
/// every case.
enum PermissionDecision {
  /// Go ahead with the feature.
  proceed,

  /// Show the in-app rationale first; call `confirmRationale` on "continue".
  showRationale,

  /// The user said no this time. Keep the feature disabled; no dialog.
  declined,

  /// Show a dialog that explains and offers "Open settings".
  openSettings,

  /// Not available on this device; hide or disable the feature.
  unavailable,
}

class PermissionUseCase {
  PermissionUseCase(this._repo);

  final PermissionRepo _repo;

  /// Step 1: check without a dialog. A rationale comes before the first
  /// system dialog, because a refusal there may be permanent.
  Future<PermissionDecision> check(AppPermission permission) async =>
      switch (await _repo.status(permission)) {
        PermissionAccess.granted ||
        PermissionAccess.limited => PermissionDecision.proceed,
        PermissionAccess.denied => PermissionDecision.showRationale,
        PermissionAccess.permanentlyDenied => PermissionDecision.openSettings,
        PermissionAccess.restricted => PermissionDecision.unavailable,
      };

  /// Step 2: after the user accepted the rationale.
  Future<PermissionDecision> request(AppPermission permission) async =>
      switch (await _repo.request(permission)) {
        PermissionAccess.granted ||
        PermissionAccess.limited => PermissionDecision.proceed,
        PermissionAccess.denied => PermissionDecision.declined,
        PermissionAccess.permanentlyDenied => PermissionDecision.openSettings,
        PermissionAccess.restricted => PermissionDecision.unavailable,
      };

  Future<bool> openSettings() => _repo.openSettings();
}

// ---------------------------------------------------------------------------
// lib/presentation/scan_receipt/cubit/scan_receipt_effect.dart  (part)
// Example feature: scan a receipt with the camera.
// ---------------------------------------------------------------------------

sealed class ScanReceiptEffect {
  const ScanReceiptEffect();
}

/// In-app explanation before the system dialog. Text comes from l10n.
final class ScanReceiptShowRationaleEffect extends ScanReceiptEffect {
  const ScanReceiptShowRationaleEffect(this.permission);

  final AppPermission permission;
}

/// Dialog with "Open settings" and "Cancel".
final class ScanReceiptShowSettingsEffect extends ScanReceiptEffect {
  const ScanReceiptShowSettingsEffect(this.permission);

  final AppPermission permission;
}

final class ScanReceiptOpenCameraEffect extends ScanReceiptEffect {
  const ScanReceiptOpenCameraEffect();
}

// ---------------------------------------------------------------------------
// lib/presentation/scan_receipt/cubit/scan_receipt_state.dart  (part)
// ---------------------------------------------------------------------------

class ScanReceiptState extends BaseAppState<Object> {
  const ScanReceiptState({
    required super.loading,
    super.error,
    this.camera,
    this.awaitingSettings = false,
    this.effect,
  });

  factory ScanReceiptState.initial() =>
      const ScanReceiptState(loading: LoadingStatus.initial);

  /// Latest decision for the camera, null before the first check. The Screen
  /// renders `declined`/`openSettings`/`unavailable` as an inline notice.
  final PermissionDecision? camera;

  /// True after "Open settings" until the app is resumed and re-checked.
  final bool awaitingSettings;

  final UiEffect<ScanReceiptEffect>? effect;

  ScanReceiptState copyWith({
    LoadingStatus? loading,
    Object? error,
    PermissionDecision? camera,
    bool? awaitingSettings,
    UiEffect<ScanReceiptEffect>? effect,
  }) {
    return ScanReceiptState(
      loading: loading ?? this.loading,
      error: error,
      camera: camera ?? this.camera,
      awaitingSettings: awaitingSettings ?? this.awaitingSettings,
      effect: effect ?? this.effect,
    );
  }

  @override
  List<Object?> get props => [loading, error, camera, awaitingSettings, effect];
}

// ---------------------------------------------------------------------------
// lib/presentation/scan_receipt/cubit/scan_receipt_cubit.dart
// ---------------------------------------------------------------------------

// @injectable
class ScanReceiptCubit extends BaseCubit<ScanReceiptState> {
  ScanReceiptCubit(this._useCase) : super(ScanReceiptState.initial());

  static const AppPermission _permission = AppPermission.camera;

  final PermissionUseCase _useCase;
  bool _busy = false;

  /// The user tapped "Scan". Ask only now, in context, never at launch.
  Future<void> onTapScan() => _guard(() async {
    final decision = await _useCase.check(_permission);
    if (isClosed) return;
    _apply(decision);
  });

  /// The user tapped "Continue" on the rationale.
  Future<void> confirmRationale() => _guard(() async {
    final decision = await _useCase.request(_permission);
    if (isClosed) return;
    _apply(decision);
  });

  /// The user tapped "Open settings".
  Future<void> openSettings() async {
    final opened = await _useCase.openSettings();
    if (isClosed) return;
    emit(state.copyWith(awaitingSettings: opened));
  }

  /// Screen: `AppLifecycleListener(onResume: cubit.onAppResumed)`. The user
  /// may have changed the permission in Settings, or revoked it.
  Future<void> onAppResumed() => _guard(() async {
    if (state.camera == null) return;
    final decision = await _useCase.check(_permission);
    if (isClosed) return;
    final cameBack = state.awaitingSettings;
    emit(
      state.copyWith(
        camera: decision == PermissionDecision.showRationale
            ? PermissionDecision.declined
            : decision,
        awaitingSettings: false,
      ),
    );
    if (cameBack && decision == PermissionDecision.proceed) {
      _emitEffect(const ScanReceiptOpenCameraEffect());
    }
  });

  void _apply(PermissionDecision decision) {
    emit(state.copyWith(camera: decision));
    switch (decision) {
      case PermissionDecision.proceed:
        _emitEffect(const ScanReceiptOpenCameraEffect());
      case PermissionDecision.showRationale:
        _emitEffect(const ScanReceiptShowRationaleEffect(_permission));
      case PermissionDecision.openSettings:
        _emitEffect(const ScanReceiptShowSettingsEffect(_permission));
      case PermissionDecision.declined || PermissionDecision.unavailable:
        break;
    }
  }

  /// A double tap must not stack two system dialogs.
  Future<void> _guard(Future<void> Function() body) async {
    if (_busy) return;
    _busy = true;
    try {
      await body();
    } finally {
      _busy = false;
    }
  }

  void _emitEffect(ScanReceiptEffect effect) {
    emit(state.copyWith(effect: createEffect(effect)));
  }
}

// ===========================================================================
// Tests
// ===========================================================================

void main() {
  group('PermissionUseCase', () {
    late _FakePermissionRepo repo;
    late PermissionUseCase useCase;

    setUp(() {
      repo = _FakePermissionRepo();
      useCase = PermissionUseCase(repo);
    });

    test('check maps every access to a decision', () async {
      final expected = {
        PermissionAccess.granted: PermissionDecision.proceed,
        PermissionAccess.limited: PermissionDecision.proceed,
        PermissionAccess.denied: PermissionDecision.showRationale,
        PermissionAccess.permanentlyDenied: PermissionDecision.openSettings,
        PermissionAccess.restricted: PermissionDecision.unavailable,
      };
      for (final entry in expected.entries) {
        repo.current = entry.key;
        expect(
          await useCase.check(AppPermission.camera),
          entry.value,
          reason: '${entry.key}',
        );
      }
      expect(repo.requests, 0);
    });

    test('request maps a refusal to declined, not rationale', () async {
      repo.answer = PermissionAccess.denied;

      expect(
        await useCase.request(AppPermission.camera),
        PermissionDecision.declined,
      );
    });
  });

  group('ScanReceiptCubit', () {
    late _FakePermissionRepo repo;
    late ScanReceiptCubit cubit;

    setUp(() {
      repo = _FakePermissionRepo();
      cubit = ScanReceiptCubit(PermissionUseCase(repo));
    });

    tearDown(() => cubit.close());

    ScanReceiptEffect? effect() => cubit.state.effect?.value;

    test('already granted: opens the camera without a dialog', () async {
      repo.current = PermissionAccess.granted;

      await cubit.onTapScan();

      expect(effect(), isA<ScanReceiptOpenCameraEffect>());
      expect(repo.requests, 0);
    });

    test(
      'first time: rationale, then the system dialog, then camera',
      () async {
        repo
          ..current = PermissionAccess.denied
          ..answer = PermissionAccess.granted;

        await cubit.onTapScan();
        expect(effect(), isA<ScanReceiptShowRationaleEffect>());
        expect(repo.requests, 0);

        await cubit.confirmRationale();
        expect(repo.requests, 1);
        expect(effect(), isA<ScanReceiptOpenCameraEffect>());
      },
    );

    test('a refusal keeps the feature disabled without nagging', () async {
      repo
        ..current = PermissionAccess.denied
        ..answer = PermissionAccess.denied;
      await cubit.onTapScan();
      final rationale = cubit.state.effect;

      await cubit.confirmRationale();

      expect(cubit.state.camera, PermissionDecision.declined);
      expect(cubit.state.effect, rationale);
    });

    test(
      'permanently denied: settings dialog, then re-check on resume',
      () async {
        repo.current = PermissionAccess.permanentlyDenied;
        await cubit.onTapScan();
        expect(effect(), isA<ScanReceiptShowSettingsEffect>());

        await cubit.openSettings();
        expect(cubit.state.awaitingSettings, isTrue);

        repo.current = PermissionAccess.granted;
        await cubit.onAppResumed();

        expect(cubit.state.awaitingSettings, isFalse);
        expect(cubit.state.camera, PermissionDecision.proceed);
        expect(effect(), isA<ScanReceiptOpenCameraEffect>());
        expect(repo.requests, 0);
      },
    );

    test('a permission revoked in Settings is noticed on resume', () async {
      repo.current = PermissionAccess.granted;
      await cubit.onTapScan();
      final opened = cubit.state.effect;

      repo.current = PermissionAccess.denied;
      await cubit.onAppResumed();

      expect(cubit.state.camera, PermissionDecision.declined);
      expect(cubit.state.effect, opened);
    });

    test('restricted: unavailable, no dialog at all', () async {
      repo.current = PermissionAccess.restricted;

      await cubit.onTapScan();

      expect(cubit.state.camera, PermissionDecision.unavailable);
      expect(cubit.state.effect, isNull);
    });

    test('a double tap asks once', () async {
      repo
        ..current = PermissionAccess.denied
        ..hold = Completer<void>();

      final first = cubit.onTapScan();
      final second = cubit.onTapScan();
      repo.hold!.complete();
      await Future.wait([first, second]);

      expect(repo.checks, 1);
    });

    test('resume before any check does nothing', () async {
      await cubit.onAppResumed();

      expect(repo.checks, 0);
      expect(cubit.state, ScanReceiptState.initial());
    });

    test('an answer that arrives after close is ignored', () async {
      repo.hold = Completer<void>();
      final tapping = cubit.onTapScan();
      await cubit.close();
      repo.hold!.complete();

      await expectLater(tapping, completes);
    });
  });
}

class _FakePermissionRepo implements PermissionRepo {
  PermissionAccess current = PermissionAccess.denied;
  PermissionAccess answer = PermissionAccess.granted;
  Completer<void>? hold;
  int checks = 0;
  int requests = 0;

  @override
  Future<PermissionAccess> status(AppPermission permission) async {
    checks++;
    await hold?.future;
    return current;
  }

  @override
  Future<PermissionAccess> request(AppPermission permission) async {
    requests++;
    current = answer;
    return answer;
  }

  @override
  Future<bool> openSettings() async => true;
}
