part of 'notification_list_cubit.dart';

/// One-shot UI actions. The screen handles them in a BlocListener.
sealed class NotificationListEffect {
  const NotificationListEffect();
}

/// A refresh failed while notifications are already on screen. The list stays;
/// the screen reports the error once (AC5).
final class NotificationListShowErrorEffect extends NotificationListEffect {
  const NotificationListShowErrorEffect({required this.error});

  final Object error;
}
