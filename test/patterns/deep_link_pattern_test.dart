// Reference implementation: deep links (App Links, Universal Links, custom
// scheme) into SLIRouting.
//
// Pattern: .agents/skills/flutter-patterns/references/deep_link.md
// Decision: docs/decisions/D-0006-deep-link-qua-domain-port.md
//
// `app_links` (proposed in D-0006) is not in pubspec, so the platform side is
// a one-line adapter sketch. The parser, the gate that waits for app start
// and sign-in, the Cubit and the SLIRouting wiring are compiled and tested.

import 'dart:async';

import 'package:bloc_cubit_base/core/base_component/base_app_state.dart';
import 'package:bloc_cubit_base/core/base_component/base_cubit.dart';
import 'package:bloc_cubit_base/core/base_component/ui_effect.dart';
import 'package:bloc_cubit_base/core/common/enum.dart';
import 'package:bloc_cubit_base/core/routing/routing.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// lib/domain/entities/link/app_link_target.dart
// ---------------------------------------------------------------------------

/// Where a link may lead. Only ids travel in a link; the destination screen
/// loads the data through the API, which checks ownership.
sealed class AppLinkTarget extends Equatable {
  const AppLinkTarget();

  bool get requiresSession;
}

final class OrderDetailLink extends AppLinkTarget {
  const OrderDetailLink(this.orderId);

  final String orderId;

  @override
  bool get requiresSession => true;

  @override
  List<Object?> get props => [orderId];
}

/// Opens a confirmation screen. A link never accepts, pays or changes data
/// by itself.
final class InviteLink extends AppLinkTarget {
  const InviteLink(this.code);

  final String code;

  @override
  bool get requiresSession => true;

  @override
  List<Object?> get props => [code];
}

final class PromotionLink extends AppLinkTarget {
  const PromotionLink(this.promotionId);

  final String promotionId;

  @override
  bool get requiresSession => false;

  @override
  List<Object?> get props => [promotionId];
}

// ---------------------------------------------------------------------------
// lib/domain/entities/link/app_link_parser.dart
// ---------------------------------------------------------------------------

/// The only place that turns a URI into a target. Anything not listed here
/// is ignored. Push notification taps use the same parser.
abstract final class AppLinkParser {
  /// Verified App Link / Universal Link hosts. Fork: replace with the real
  /// domain(s) that serve assetlinks.json and apple-app-site-association.
  static const Set<String> hosts = {'app.example.com'};

  /// Custom scheme, for links from email or QR codes that cannot be https.
  static const String scheme = 'blocbase';

  static final RegExp _id = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

  static AppLinkTarget? parse(Uri uri) {
    final List<String> segments;
    if (uri.scheme == 'https' && hosts.contains(uri.host)) {
      if (uri.hasPort || uri.userInfo.isNotEmpty) return null;
      segments = uri.pathSegments;
    } else if (uri.scheme == scheme) {
      segments = [uri.host, ...uri.pathSegments];
    } else {
      return null;
    }
    final parts = segments.where((s) => s.isNotEmpty).toList();
    if (parts.length != 2 || !_id.hasMatch(parts[1])) return null;
    return switch (parts[0]) {
      'orders' => OrderDetailLink(parts[1]),
      'invites' => InviteLink(parts[1]),
      'promotions' => PromotionLink(parts[1]),
      _ => null,
    };
  }
}

// ---------------------------------------------------------------------------
// lib/domain/repositories/deep_link_repo.dart
// ---------------------------------------------------------------------------

abstract class DeepLinkRepo {
  /// Emits the link that launched the app, once, then every link that
  /// arrives while it runs. Never errors.
  Stream<Uri> watchLinks();
}

// Adapter sketch: lib/data/repositories/app_links_deep_link_repo.dart
// Needs `app_links` (D-0006).
//
//   @LazySingleton(as: DeepLinkRepo)
//   class AppLinksDeepLinkRepo implements DeepLinkRepo {
//     AppLinksDeepLinkRepo(this._appLinks);   // AppLinks() from RegisterModule
//     final AppLinks _appLinks;
//
//     @override
//     Stream<Uri> watchLinks() => _appLinks.uriLinkStream;  // includes the
//   }                                                       // initial link
//
// Native: Android intent-filter (autoVerify) + assetlinks.json, iOS
// Associated Domains + apple-app-site-association, and Flutter's built-in
// deep linking turned off (flutter_deeplinking_enabled=false,
// FlutterDeepLinkingEnabled=NO): MainApp.generator throws for an unknown
// route name, and the plugin must be the only reader.

// ---------------------------------------------------------------------------
// lib/domain/use_case/deep_link_use_case.dart
// ---------------------------------------------------------------------------

/// Reads the session through a getter so the domain does not depend on how
/// the session is stored; in the app this is `SessionRepo.isSignedIn`.
class DeepLinkUseCase {
  DeepLinkUseCase(this._links, this._isSignedIn);

  final DeepLinkRepo _links;
  final bool Function() _isSignedIn;

  /// Stream operators, not `async*`: cancelling an `async*` stream waits for
  /// its next `yield`, so wrapping an endless link stream would make
  /// `close()` hang until another link arrives.
  Stream<AppLinkTarget> watchTargets() => _links
      .watchLinks()
      .map(AppLinkParser.parse)
      .where((target) => target != null)
      .cast<AppLinkTarget>();

  bool get isSignedIn => _isSignedIn();
}

// ---------------------------------------------------------------------------
// lib/presentation/deep_link/cubit/deep_link_effect.dart  (part)
// ---------------------------------------------------------------------------

sealed class DeepLinkEffect {
  const DeepLinkEffect();
}

final class DeepLinkOpenEffect extends DeepLinkEffect {
  const DeepLinkOpenEffect(this.target);

  final AppLinkTarget target;
}

/// The target needs a session. The Screen opens sign-in; the link stays
/// pending and opens after `onSessionStarted`.
final class DeepLinkSignInRequiredEffect extends DeepLinkEffect {
  const DeepLinkSignInRequiredEffect();
}

// ---------------------------------------------------------------------------
// lib/presentation/deep_link/cubit/deep_link_state.dart  (part)
// ---------------------------------------------------------------------------

class DeepLinkState extends BaseAppState<Object> {
  const DeepLinkState({
    required super.loading,
    super.error,
    required this.ready,
    this.pending,
    this.effect,
  });

  factory DeepLinkState.initial() =>
      const DeepLinkState(loading: LoadingStatus.initial, ready: false);

  /// True once splash has placed the first route. Links wait until then.
  final bool ready;

  /// The latest link that is waiting for [ready] or for sign-in.
  final AppLinkTarget? pending;

  final UiEffect<DeepLinkEffect>? effect;

  DeepLinkState copyWith({
    bool? ready,
    AppLinkTarget? pending,
    bool clearPending = false,
    UiEffect<DeepLinkEffect>? effect,
  }) {
    return DeepLinkState(
      loading: loading,
      ready: ready ?? this.ready,
      pending: clearPending ? null : pending ?? this.pending,
      effect: effect ?? this.effect,
    );
  }

  @override
  List<Object?> get props => [loading, error, ready, pending, effect];
}

// ---------------------------------------------------------------------------
// lib/presentation/deep_link/cubit/deep_link_cubit.dart
// App-scope: resolved once in buildMainApp() and closed with the app.
// ---------------------------------------------------------------------------

// @injectable
class DeepLinkCubit extends BaseCubit<DeepLinkState> {
  DeepLinkCubit(this._useCase) : super(DeepLinkState.initial());

  final DeepLinkUseCase _useCase;
  StreamSubscription<AppLinkTarget>? _subscription;

  /// Called once from MainApp.initState.
  void start() {
    _subscription ??= _useCase.watchTargets().listen(_handle);
  }

  /// Called by splash after it navigated to the first screen.
  void markReady() {
    emit(state.copyWith(ready: true));
    _replayPending();
  }

  /// Called after sign-in completes.
  void onSessionStarted() => _replayPending();

  /// Push notification taps enter here, through the same parser and gate.
  void openUri(Uri uri) {
    final target = AppLinkParser.parse(uri);
    if (target != null) _handle(target);
  }

  void _replayPending() {
    final pending = state.pending;
    if (pending != null) _handle(pending);
  }

  void _handle(AppLinkTarget target) {
    if (isClosed) return;
    if (!state.ready) {
      emit(state.copyWith(pending: target));
      return;
    }
    if (target.requiresSession && !_useCase.isSignedIn) {
      emit(
        state.copyWith(
          pending: target,
          effect: createEffect<DeepLinkEffect>(
            const DeepLinkSignInRequiredEffect(),
          ),
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        clearPending: true,
        effect: createEffect<DeepLinkEffect>(DeepLinkOpenEffect(target)),
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}

// ---------------------------------------------------------------------------
// lib/core/app/main_app.dart  (listener excerpt; AppPage names are examples)
// ---------------------------------------------------------------------------

abstract final class LinkRoutes {
  static const String signIn = '/sign_in';
  static const String orderDetail = '/order_detail';
  static const String inviteConfirm = '/invite_confirm';
  static const String promotion = '/promotion';
}

void handleDeepLinkEffect(DeepLinkEffect? effect) {
  switch (effect) {
    case DeepLinkSignInRequiredEffect():
      SLIRouting.toNamed(LinkRoutes.signIn);
    case DeepLinkOpenEffect(:final target):
      final (route, argument) = switch (target) {
        OrderDetailLink(:final orderId) => (LinkRoutes.orderDetail, orderId),
        InviteLink(:final code) => (LinkRoutes.inviteConfirm, code),
        PromotionLink(:final promotionId) => (
          LinkRoutes.promotion,
          promotionId,
        ),
      };
      SLIRouting.toNamed(route, arguments: argument);
    case null:
      break;
  }
}

// ===========================================================================
// Tests
// ===========================================================================

void main() {
  group('AppLinkParser', () {
    test('accepts allowlisted https and custom-scheme links', () {
      expect(
        AppLinkParser.parse(Uri.parse('https://app.example.com/orders/o-1')),
        const OrderDetailLink('o-1'),
      );
      expect(
        AppLinkParser.parse(Uri.parse('blocbase://invites/ABC_123')),
        const InviteLink('ABC_123'),
      );
      expect(
        AppLinkParser.parse(
          Uri.parse('https://app.example.com/promotions/p1/?utm_source=mail'),
        ),
        const PromotionLink('p1'),
      );
    });

    test('rejects anything outside the allowlist', () {
      for (final link in [
        'http://app.example.com/orders/o-1',
        'https://evil.example.com/orders/o-1',
        'https://app.example.com.evil.test/orders/o-1',
        'https://user@app.example.com/orders/o-1',
        'https://app.example.com:8443/orders/o-1',
        'https://app.example.com/orders',
        'https://app.example.com/orders/o-1/pay',
        'https://app.example.com/orders/..%2Fadmin',
        'https://app.example.com/accounts/42',
        'otherapp://orders/o-1',
        'blocbase://orders/${'x' * 65}',
      ]) {
        expect(AppLinkParser.parse(Uri.parse(link)), isNull, reason: link);
      }
    });
  });

  group('DeepLinkCubit', () {
    late StreamController<Uri> links;
    late bool signedIn;
    late DeepLinkCubit cubit;

    setUp(() {
      links = StreamController<Uri>();
      signedIn = true;
      cubit = DeepLinkCubit(
        DeepLinkUseCase(_FakeDeepLinkRepo(links.stream), () => signedIn),
      )..start();
    });

    tearDown(() => cubit.close());

    Future<void> receive(String link) async {
      links.add(Uri.parse(link));
      await pumpEventQueue();
    }

    test('a cold-start link waits for splash, then opens', () async {
      await receive('https://app.example.com/orders/o-1');
      expect(cubit.state.pending, const OrderDetailLink('o-1'));
      expect(cubit.state.effect, isNull);

      cubit.markReady();

      final effect = cubit.state.effect!.value as DeepLinkOpenEffect;
      expect(effect.target, const OrderDetailLink('o-1'));
      expect(cubit.state.pending, isNull);
    });

    test('the latest link before ready wins', () async {
      await receive('https://app.example.com/orders/o-1');
      await receive('https://app.example.com/orders/o-2');

      cubit.markReady();

      final effect = cubit.state.effect!.value as DeepLinkOpenEffect;
      expect(effect.target, const OrderDetailLink('o-2'));
    });

    test('signed out: sign-in first, then the same link', () async {
      signedIn = false;
      cubit.markReady();

      await receive('https://app.example.com/invites/inv-1');
      expect(cubit.state.effect!.value, isA<DeepLinkSignInRequiredEffect>());
      expect(cubit.state.pending, const InviteLink('inv-1'));

      signedIn = true;
      cubit.onSessionStarted();

      final effect = cubit.state.effect!.value as DeepLinkOpenEffect;
      expect(effect.target, const InviteLink('inv-1'));
    });

    test('a public link opens without a session', () async {
      signedIn = false;
      cubit.markReady();

      await receive('blocbase://promotions/p1');

      final effect = cubit.state.effect!.value as DeepLinkOpenEffect;
      expect(effect.target, const PromotionLink('p1'));
    });

    test('an unknown link changes nothing', () async {
      cubit.markReady();
      final before = cubit.state;

      await receive('https://evil.example.com/orders/o-1');

      expect(cubit.state, before);
    });

    test('the same link twice opens twice', () async {
      cubit.markReady();
      await receive('blocbase://orders/o-1');
      final first = cubit.state.effect!;
      await receive('blocbase://orders/o-1');

      expect(cubit.state.effect!.revision, first.revision + 1);
    });

    test('push taps share the parser and the gate', () {
      cubit.openUri(Uri.parse('blocbase://orders/o-9'));
      expect(cubit.state.pending, const OrderDetailLink('o-9'));

      cubit.openUri(Uri.parse('https://evil.example.com/orders/o-1'));
      expect(cubit.state.pending, const OrderDetailLink('o-9'));
    });

    test('close stops listening', () async {
      await cubit.close();

      expect(links.hasListener, isFalse);
    });
  });

  testWidgets('the app listener routes each target through SLIRouting', (
    tester,
  ) async {
    final links = StreamController<Uri>();
    var signedIn = false;
    final cubit = DeepLinkCubit(
      DeepLinkUseCase(_FakeDeepLinkRepo(links.stream), () => signedIn),
    )..start();
    addTearDown(cubit.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: BlocListener<DeepLinkCubit, DeepLinkState>(
          listenWhen: (previous, current) => previous.effect != current.effect,
          listener: (_, state) => handleDeepLinkEffect(state.effect?.value),
          child: MaterialApp(
            navigatorKey: SLIRouting.key,
            onGenerateRoute: (settings) => MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => Text('${settings.name} ${settings.arguments}'),
            ),
          ),
        ),
      ),
    );
    cubit.markReady();

    links.add(Uri.parse('https://app.example.com/orders/o-1'));
    await tester.pumpAndSettle();
    expect(find.text('/sign_in null'), findsOneWidget);

    signedIn = true;
    cubit.onSessionStarted();
    await tester.pumpAndSettle();
    expect(find.text('/order_detail o-1'), findsOneWidget);
  });
}

class _FakeDeepLinkRepo implements DeepLinkRepo {
  _FakeDeepLinkRepo(this._links);

  final Stream<Uri> _links;

  @override
  Stream<Uri> watchLinks() => _links;
}
