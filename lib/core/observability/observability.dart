import 'package:bloc_cubit_base/core/observability/analytics_tracker.dart';
import 'package:bloc_cubit_base/core/observability/crash_reporter.dart';
import 'package:bloc_cubit_base/core/observability/diagnostics.dart';
import 'package:bloc_cubit_base/core/observability/feature_flags.dart';
import 'package:bloc_cubit_base/core/observability/performance_tracer.dart';
import 'package:flutter/foundation.dart';

export 'package:bloc_cubit_base/core/observability/analytics_tracker.dart';
export 'package:bloc_cubit_base/core/observability/crash_reporter.dart';
export 'package:bloc_cubit_base/core/observability/diagnostics.dart'
    show DiagnosticLog, DiagnosticRedactor;
export 'package:bloc_cubit_base/core/observability/feature_flags.dart';
export 'package:bloc_cubit_base/core/observability/performance_tracer.dart';
export 'package:bloc_cubit_base/core/observability/uncaught_error_forwarder.dart';

/// Builds remote adapters, for example Firebase, for [Observability.select].
typedef RemoteObservabilityFactory = Observability Function();

/// Crash reports, analytics, performance traces and feature flags behind one
/// seam that works with or without a remote backend.
///
/// Whatever adapters sit behind it, every member keeps the same guarantees:
/// personal data is redacted or dropped, adapter failures never reach the
/// caller, and feature flags fall back to their in-code defaults. See
/// `docs/guides/enable-version-health.md`.
@immutable
final class Observability {
  factory Observability({
    required CrashReporter crash,
    required AnalyticsTracker analytics,
    required PerformanceTracer performance,
    required FeatureFlags flags,
    DiagnosticRedactor redactor = const DiagnosticRedactor(),
    DiagnosticLog log = logDiagnostic,
    bool debugLogging = kDebugMode,
    Duration flagRefreshTimeout = const Duration(seconds: 10),
  }) {
    final debug = DebugDiagnostics(log: log, enabled: debugLogging);
    return Observability._(
      crash: crash is RedactingCrashReporter
          ? crash
          : RedactingCrashReporter(crash, redactor: redactor, debug: debug),
      analytics: analytics is SanitizingAnalyticsTracker
          ? analytics
          : SanitizingAnalyticsTracker(
              analytics,
              redactor: redactor,
              debug: debug,
            ),
      performance: performance is SafePerformanceTracer
          ? performance
          : SafePerformanceTracer(
              performance,
              redactor: redactor,
              debug: debug,
            ),
      flags: flags is FallbackFeatureFlags
          ? flags
          : FallbackFeatureFlags(
              flags,
              refreshTimeout: flagRefreshTimeout,
              debug: debug,
            ),
    );
  }

  /// Nothing leaves the device. Debug builds print redacted diagnostics.
  factory Observability.local({
    DiagnosticLog log = logDiagnostic,
    bool debugLogging = kDebugMode,
    Map<String, Object> flagOverrides = const {},
  }) => Observability(
    crash: LocalCrashReporter(log: log, debugLogging: debugLogging),
    analytics: LocalAnalyticsTracker(log: log, debugLogging: debugLogging),
    performance: LocalPerformanceTracer(log: log, debugLogging: debugLogging),
    flags: LocalFeatureFlags(
      overrides: flagOverrides,
      log: log,
      debugLogging: debugLogging,
    ),
    log: log,
    debugLogging: debugLogging,
  );

  /// Uses [remote] adapters only when [enabled]; otherwise, or when [remote]
  /// is missing or throws, falls back to [Observability.local].
  factory Observability.select({
    required bool enabled,
    RemoteObservabilityFactory? remote,
    DiagnosticLog log = logDiagnostic,
    bool debugLogging = kDebugMode,
  }) {
    final debug = DebugDiagnostics(log: log, enabled: debugLogging);
    if (enabled && remote != null) {
      try {
        return remote();
      } catch (error) {
        debug(
          'observability: remote adapters failed with ${error.runtimeType}; '
          'using local diagnostics',
        );
      }
    } else if (enabled) {
      debug(
        'observability: enabled without remote adapters; '
        'using local diagnostics',
      );
    }
    return Observability.local(log: log, debugLogging: debugLogging);
  }

  const Observability._({
    required this.crash,
    required this.analytics,
    required this.performance,
    required this.flags,
  });

  final CrashReporter crash;
  final AnalyticsTracker analytics;
  final PerformanceTracer performance;
  final FeatureFlags flags;
}
