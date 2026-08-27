import 'package:intl/intl.dart';

final _numFormatCurrency = NumberFormat("###,###,###.##", 'vi_VN');

extension NumExtension on num {
  String get currencyFormat => _numFormatCurrency.format(this);

  String fileSize([int round = 2]) {
    /**
     * [size] can be passed as number or as string
     *
     * the optional parameter [round] specifies the number
     * of digits after comma/point (default is 2)
     */
    var divider = 1024;
    int size;
    try {
      size = int.parse(toString());
    } catch (e) {
      throw ArgumentError('Can not parse the size parameter: $e');
    }

    if (size < divider) {
      return '$size B';
    }

    if (size < divider * divider && size % divider == 0) {
      return '${(size / divider).toStringAsFixed(0)} KB';
    }

    if (size < divider * divider) {
      return '${(size / divider).toStringAsFixed(round)} KB';
    }

    if (size < divider * divider * divider && size % divider == 0) {
      return '${(size / (divider * divider)).toStringAsFixed(0)} MB';
    }

    if (size < divider * divider * divider) {
      return '${(size / divider / divider).toStringAsFixed(round)} MB';
    }

    if (size < divider * divider * divider * divider && size % divider == 0) {
      return '${(size / (divider * divider * divider)).toStringAsFixed(0)} GB';
    }

    if (size < divider * divider * divider * divider) {
      return '${(size / divider / divider / divider).toStringAsFixed(round)} GB';
    }

    if (size < divider * divider * divider * divider * divider &&
        size % divider == 0) {
      num r = size / divider / divider / divider / divider;
      return '${r.toStringAsFixed(0)} TB';
    }

    if (size < divider * divider * divider * divider * divider) {
      num r = size / divider / divider / divider / divider;
      return '${r.toStringAsFixed(round)} TB';
    }

    if (size < divider * divider * divider * divider * divider * divider &&
        size % divider == 0) {
      num r = size / divider / divider / divider / divider / divider;
      return '${r.toStringAsFixed(0)} PB';
    } else {
      num r = size / divider / divider / divider / divider / divider;
      return '${r.toStringAsFixed(round)} PB';
    }
  }
}
