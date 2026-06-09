extension StringExtension on String? {
  bool get isNullOrEmpty => this == null || this!.trim().isEmpty;

  bool get isNotNullOrEmpty => this != null && this!.trim().isNotEmpty;

  List<RegExpMatch> get getAllUrlPosition {
    if (isNullOrEmpty) return [];
    RegExp exp = RegExp(r'(http|https)://[\w-]+(\.[\w-]+)+([\w.,@?^=%&amp;:/~+#-]*[\w@?^=%&amp;/~+#-])?');
    return exp.allMatches(this!).toList();
  }

  DateTime? get timeFromMillisecond {
    if (isNullOrEmpty) return null;
    return DateTime.fromMillisecondsSinceEpoch(int.parse(this!));
  }

  bool get isUrl {
    if (isNullOrEmpty) return false;
    return this!.contains('http://') || this!.contains('https://');
  }
}
