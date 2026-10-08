import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_data_source.dart';
import '../models/notification_models.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  const NotificationRepositoryImpl(this._remote);
  final NotificationRemoteDataSource _remote;
  @override
  Future<NotificationInbox> inbox(
          {required String appFlavor,
          int page = 1,
          bool unreadOnly = false,
          String? category}) async =>
      inboxFromJson(await _remote.inbox(
          appFlavor: appFlavor,
          page: page,
          unreadOnly: unreadOnly,
          category: category));
  @override
  Future<int> unreadCount(String appFlavor) => _remote.unreadCount(appFlavor);
  @override
  Future<AppNotification> detail(String id) async =>
      AppNotificationModel.fromJson(await _remote.detail(id));
  @override
  Future<AppNotification> markRead(String id) async =>
      AppNotificationModel.fromJson(await _remote.markRead(id));
  @override
  Future<void> markAllRead(String appFlavor) => _remote.markAllRead(appFlavor);
  @override
  Future<NotificationPreferences> preferences() async =>
      preferencesFromJson(await _remote.preferences());
  @override
  Future<NotificationPreferences> updatePreferences(
          NotificationPreferences value) async =>
      preferencesFromJson(
          await _remote.updatePreferences(preferencesToJson(value)));
  @override
  Future<String> registerDevice(
          {required String deviceId,
          required String token,
          required String appFlavor,
          required String environment,
          required String platform}) =>
      _remote.registerDevice({
        'deviceId': deviceId,
        'token': token,
        'appFlavor': appFlavor,
        'environment': environment,
        'platform': platform
      });
  @override
  Future<void> deactivateDevice(String id) => _remote.deactivateDevice(id);
  @override
  Future<void> interaction(String id, String kind,
          {String channel = 'in_app'}) =>
      _remote.interaction(id, kind, channel);
}
