import '../entities/app_notification.dart';
import '../repositories/notification_repository.dart';

class NotificationActions {
  const NotificationActions(this._repository);
  final NotificationRepository _repository;
  Future<NotificationInbox> inbox(
          {required String appFlavor,
          int page = 1,
          bool unreadOnly = false,
          String? category}) =>
      _repository.inbox(
          appFlavor: appFlavor,
          page: page,
          unreadOnly: unreadOnly,
          category: category);
  Future<int> unreadCount(String flavor) => _repository.unreadCount(flavor);
  Future<AppNotification> detail(String id) => _repository.detail(id);
  Future<AppNotification> markRead(String id) => _repository.markRead(id);
  Future<void> markAllRead(String flavor) => _repository.markAllRead(flavor);
  Future<NotificationPreferences> preferences() => _repository.preferences();
  Future<NotificationPreferences> updatePreferences(
          NotificationPreferences value) =>
      _repository.updatePreferences(value);
  Future<String> registerDevice(
          {required String deviceId,
          required String token,
          required String appFlavor,
          required String environment,
          required String platform}) =>
      _repository.registerDevice(
          deviceId: deviceId,
          token: token,
          appFlavor: appFlavor,
          environment: environment,
          platform: platform);
  Future<void> deactivateDevice(String id) => _repository.deactivateDevice(id);
  Future<void> interaction(String id, String kind,
          {String channel = 'in_app'}) =>
      _repository.interaction(id, kind, channel: channel);
}
