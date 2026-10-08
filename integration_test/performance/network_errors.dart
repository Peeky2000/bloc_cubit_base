/// Classifies failed HTTP requests so a run can tell who has to act.
///
/// Pure Dart so it can be unit tested on the host. Rules follow RFC 9110:
/// 4xx means the request is wrong (client), 5xx means the server failed.
library;

/// Who should look at a failed request first.
enum FailureOwner {
  /// The app sent a wrong request: bad path, payload, headers or auth flow.
  mobile,

  /// The server failed or overloaded: 5xx, 429.
  backend,

  /// Connectivity between device and server: DNS, TLS, refused, timeout.
  network,

  /// The test setup: expired test account, missing credentials, wrong base URL.
  environment,
}

/// Whether running the scenario again later can succeed without a code change.
enum RetryAdvice { now, later, never }

class FailureVerdict {
  const FailureVerdict(this.owner, this.retry, this.reason);
  final FailureOwner owner;
  final RetryAdvice retry;
  final String reason;

  Map<String, Object> toJson() => {
    'owner': owner.name,
    'retry': retry.name,
    'reason': reason,
  };
}

/// Classifies one failed request from its status code or transport error.
///
/// [authenticated] says whether the scenario expected a logged-in session,
/// which separates an expired test account (environment) from an app that
/// forgot to send its token (mobile).
FailureVerdict classifyFailure({
  int? statusCode,
  String? error,
  bool authenticated = true,
}) {
  final status = statusCode;
  if (status == null || status == 0) return _transport(error ?? '');
  if (status == 401 || status == 403) {
    return authenticated
        ? const FailureVerdict(
            FailureOwner.environment,
            RetryAdvice.never,
            'Auth rejected. Check that the test account is valid and active; '
            'if it is, the app is not sending or refreshing its token.',
          )
        : const FailureVerdict(
            FailureOwner.mobile,
            RetryAdvice.never,
            'Auth rejected before login. The app called a protected endpoint '
            'too early.',
          );
  }
  if (status == 408) {
    return const FailureVerdict(
      FailureOwner.network,
      RetryAdvice.now,
      'Server timed out waiting for the request body (408).',
    );
  }
  if (status == 429) {
    return const FailureVerdict(
      FailureOwner.backend,
      RetryAdvice.later,
      'Rate limited (429). RetryAdvice after the RetryAdvice-After window; if the app '
      'sends a burst of identical calls, that is a mobile finding too.',
    );
  }
  if (status == 404 || status == 405 || status == 400 || status == 422) {
    return FailureVerdict(
      FailureOwner.mobile,
      RetryAdvice.never,
      'Client error $status. The app sent a request the API does not accept: '
      'check path, method, parameters and the API contract.',
    );
  }
  if (status >= 400 && status < 500) {
    return FailureVerdict(
      FailureOwner.mobile,
      RetryAdvice.never,
      'Client error $status. The request is rejected as sent.',
    );
  }
  if (status == 502 || status == 503 || status == 504) {
    return FailureVerdict(
      FailureOwner.backend,
      RetryAdvice.later,
      'Server unavailable or gateway timeout ($status). Usually temporary.',
    );
  }
  if (status >= 500) {
    return FailureVerdict(
      FailureOwner.backend,
      RetryAdvice.later,
      'Server error $status. Send the endpoint and time to the backend team.',
    );
  }
  return FailureVerdict(
    FailureOwner.mobile,
    RetryAdvice.never,
    'Unexpected status $status.',
  );
}

FailureVerdict _transport(String error) {
  final e = error.toLowerCase();
  if (e.contains('handshake') ||
      e.contains('certificate') ||
      e.contains('tls') ||
      e.contains('ssl')) {
    return const FailureVerdict(
      FailureOwner.environment,
      RetryAdvice.never,
      'TLS failure. Check the base URL, certificate and device clock.',
    );
  }
  if (e.contains('failed host lookup') || e.contains('nodename')) {
    return const FailureVerdict(
      FailureOwner.environment,
      RetryAdvice.later,
      'DNS lookup failed. Check the base URL and the device network.',
    );
  }
  if (e.contains('timed out') || e.contains('timeout')) {
    return const FailureVerdict(
      FailureOwner.network,
      RetryAdvice.now,
      'Connection or response timed out.',
    );
  }
  if (e.contains('connection refused') ||
      e.contains('connection reset') ||
      e.contains('connection closed') ||
      e.contains('network is unreachable') ||
      e.contains('socketexception')) {
    return const FailureVerdict(
      FailureOwner.network,
      RetryAdvice.now,
      'Connection dropped or refused.',
    );
  }
  return FailureVerdict(
    FailureOwner.network,
    RetryAdvice.now,
    error.isEmpty ? 'Request failed without a response.' : error,
  );
}
