import 'package:bloc_cubit_base/core/error/error_to_string_mapper.dart';
import 'package:bloc_cubit_base/core/error/exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const fallback = 'Something went wrong';
  const offline = 'No internet';

  test('maps network and general exceptions without BuildContext', () {
    expect(
      ErrorMapper.parse(
        NetworkIssueException(),
        fallbackMessage: fallback,
        noNetworkMessage: offline,
      ),
      offline,
    );
    expect(
      ErrorMapper.parse(
        GeneralException(messages: '  Invalid OTP  '),
        fallbackMessage: fallback,
        noNetworkMessage: offline,
      ),
      'Invalid OTP',
    );
  });

  test('extracts a server message and falls back for malformed data', () {
    final request = RequestOptions(path: '/auth');
    final withMessage = ServerException(
      DioException(
        requestOptions: request,
        response: Response<dynamic>(
          requestOptions: request,
          data: <String, dynamic>{'message': '  Unauthorized  '},
        ),
      ),
    );
    final malformed = ServerException(
      DioException(
        requestOptions: request,
        response: Response<dynamic>(
          requestOptions: request,
          data: <String, dynamic>{'message': 401},
        ),
      ),
    );

    expect(
      ErrorMapper.parse(
        withMessage,
        fallbackMessage: fallback,
        noNetworkMessage: offline,
      ),
      'Unauthorized',
    );
    expect(
      ErrorMapper.parse(
        malformed,
        fallbackMessage: fallback,
        noNetworkMessage: offline,
      ),
      fallback,
    );
  });
}
