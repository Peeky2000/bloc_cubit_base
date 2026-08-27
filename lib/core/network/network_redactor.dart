import 'dart:convert';
import 'dart:typed_data';

class NetworkRedactor {
  const NetworkRedactor({this.replacement = '<redacted>'});

  final String replacement;

  static const _sensitiveKeys = {
    'authorization',
    'cookie',
    'setcookie',
    'accesstoken',
    'refreshtoken',
    'token',
    'password',
    'passcode',
    'secret',
    'apikey',
    'clientsecret',
    'idtoken',
    'phone',
    'email',
  };

  Map<String, String> headers(Map<String, dynamic> source) => source.map(
    (key, value) => MapEntry(
      key,
      _isSensitive(key) ? replacement : _redactText(value.toString()),
    ),
  );

  Map<String, dynamic> query(Map<String, dynamic> source) =>
      body(source) as Map<String, dynamic>;

  dynamic body(dynamic value, {String? key}) {
    if (key != null && _isSensitive(key)) {
      return replacement;
    }
    if (value is Map) {
      return value.map<String, dynamic>(
        (mapKey, mapValue) =>
            MapEntry(mapKey.toString(), body(mapValue, key: mapKey.toString())),
      );
    }
    if (value is Iterable) {
      return value.map(body).toList(growable: false);
    }
    if (value is Uint8List || value is List<int>) {
      return '<binary:${(value as List<int>).length} bytes>';
    }
    if (value is String) {
      try {
        return body(jsonDecode(value));
      } on FormatException {
        return _redactText(value);
      }
    }
    return value;
  }

  String text(String value) => _redactText(value);

  bool _isSensitive(String key) {
    final normalized = key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return _sensitiveKeys.contains(normalized);
  }

  String _redactText(String value) => value.replaceAll(
    RegExp(r'Bearer\s+[A-Za-z0-9._~+\-/]+=*', caseSensitive: false),
    'Bearer $replacement',
  );
}
