/// One notification for the signed-in account (spec 002-notifications).
/// Data models implement it; no JSON here.
abstract class AppNotification {
  String get id;

  String get title;

  String get body;

  /// Null when the server sends no or an unreadable time.
  DateTime? get createdAt;

  bool get isRead;
}
