import 'package:flutter/foundation.dart';

class Log {
  static void t({dynamic message = '', dynamic error}) {
    if (kDebugMode) {
      debugPrint('LOG_T: $message');
      if (error != null) debugPrint('ERROR: $error');
    }
  }

  static void d({dynamic message = '', dynamic error}) {
    if (kDebugMode) {
      debugPrint('LOG_D: $message');
      if (error != null) debugPrint('ERROR: $error');
    }
  }

  static void i({dynamic message = '', dynamic error}) {
    if (kDebugMode) {
      debugPrint('LOG_I: $message');
      if (error != null) debugPrint('ERROR: $error');
    }
  }

  static void w({dynamic message = '', dynamic error}) {
    if (kDebugMode) {
      debugPrint('LOG_W: $message');
      if (error != null) debugPrint('ERROR: $error');
    }
  }

  static void e({dynamic message = '', dynamic error}) {
    if (kDebugMode) {
      debugPrint('LOG_E: $message');
      if (error != null) debugPrint('ERROR: $error');
    }
  }
}
