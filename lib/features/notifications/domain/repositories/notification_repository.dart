import '../entities/app_notification.dart';

abstract class NotificationRepository {
  Future<NotificationInbox> inbox(
      {required String appFlavor,
      int page = 1,
      bool unreadOnly = false,
      String? category});
  Future<int> unreadCount(String appFlavor);
  Future<AppNotification> detail(String id);
  Future<AppNotification> markRead(String id);
  Future<void> markAllRead(String appFlavor);
  Future<NotificationPreferences> preferences();
  Future<NotificationPreferences> updatePreferences(
      NotificationPreferences preferences);
  Future<String> registerDevice(
      {required String deviceId,
      required String token,
      required String appFlavor,
      required String environment,
      required String platform});
  Future<void> deactivateDevice(String id);
  Future<void> interaction(String id, String kind, {String channel = 'in_app'});
}
