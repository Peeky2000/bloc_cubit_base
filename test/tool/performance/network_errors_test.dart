import 'package:flutter_test/flutter_test.dart';

import '../../../integration_test/performance/network_errors.dart';

void main() {
  FailureVerdict http(int status, {bool authenticated = true}) =>
      classifyFailure(statusCode: status, authenticated: authenticated);
  FailureVerdict transport(String error) => classifyFailure(error: error);

  test('5xx and 429 belong to the backend and can be retried later', () {
    for (final status in [500, 502, 503, 504, 429]) {
      expect(http(status).owner, FailureOwner.backend, reason: '$status');
      expect(http(status).retry, RetryAdvice.later, reason: '$status');
    }
  });

  test('wrong requests belong to mobile and never pass on retry', () {
    for (final status in [400, 404, 405, 422, 409]) {
      expect(http(status).owner, FailureOwner.mobile, reason: '$status');
      expect(http(status).retry, RetryAdvice.never, reason: '$status');
    }
  });

  test('auth rejection depends on whether a session was expected', () {
    expect(http(401).owner, FailureOwner.environment);
    expect(http(403, authenticated: false).owner, FailureOwner.mobile);
  });

  test('transport errors split into network and environment', () {
    expect(transport('Connection timed out').owner, FailureOwner.network);
    expect(transport('Connection timed out').retry, RetryAdvice.now);
    expect(
      transport('SocketException: Connection refused').owner,
      FailureOwner.network,
    );
    expect(
      transport('Failed host lookup: api.dev').owner,
      FailureOwner.environment,
    );
    expect(
      transport('HandshakeException: CERTIFICATE_VERIFY_FAILED').owner,
      FailureOwner.environment,
    );
    expect(http(408).owner, FailureOwner.network);
  });
}
