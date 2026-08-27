import 'package:bloc_cubit_base/core/network/network_redactor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const redactor = NetworkRedactor();

  test('redacts sensitive headers regardless of casing', () {
    final result = redactor.headers({
      'Authorization': 'Bearer top-secret',
      'X-Request-Id': 'request-123',
      'Cookie': 'session=secret',
    });

    expect(result['Authorization'], '<redacted>');
    expect(result['Cookie'], '<redacted>');
    expect(result['X-Request-Id'], 'request-123');
  });

  test('redacts nested request and response values', () {
    final result =
        redactor.body({
              'profile': {'email': 'person@example.com', 'name': 'Ada'},
              'tokens': [
                {'access_token': 'secret'},
              ],
              'password': 'password-123',
            })
            as Map<String, dynamic>;

    expect(result['password'], '<redacted>');
    expect((result['profile'] as Map)['email'], '<redacted>');
    expect((result['profile'] as Map)['name'], 'Ada');
    expect(
      ((result['tokens'] as List).single as Map)['access_token'],
      '<redacted>',
    );
  });

  test('redacts bearer tokens embedded in text', () {
    expect(
      redactor.text('Authorization: Bearer abc.def.ghi'),
      'Authorization: Bearer <redacted>',
    );
  });
}
