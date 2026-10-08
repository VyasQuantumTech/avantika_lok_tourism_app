import 'dart:async';
import 'package:avantika_lok_tourism_app/core/services/notification_push_client.dart';
import 'package:avantika_lok_tourism_app/core/storage/notification_device_storage.dart';
import 'package:avantika_lok_tourism_app/features/notifications/domain/entities/app_notification.dart';
import 'package:avantika_lok_tourism_app/features/notifications/domain/repositories/notification_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

AppNotification notification(
        {String id = 'notice-1',
        String flavor = 'customer',
        String route = '/customer/bookings/booking-1',
        Map<String, dynamic> data = const {
          'bookingType': 'pooja',
          'bookingId': 'booking-1'
        },
        bool read = false}) =>
    AppNotification(
        id: id,
        title: 'Booking confirmed',
        body: 'Your booking has been confirmed.',
        appFlavor: flavor,
        category: 'booking_updates',
        eventType: 'booking.confirmed',
        priority: 'high',
        mandatory: true,
        data: data,
        route: route,
        createdAt: DateTime.utc(2026, 10, 8),
        readAt: read ? DateTime.utc(2026, 10, 8) : null);

class FakeNotificationRepository implements NotificationRepository {
  int count = 3;
  String flavor = 'customer';
  bool failRegistration = false, failInbox = false, failInteraction = false;
  Completer<int>? unreadResponse;
  Completer<String>? registrationResponse;
  final registrationStarted = Completer<void>();
  final registrations = <Map<String, String>>[];
  final deactivated = <String>[];
  final requests = <Map<String, dynamic>>[];
  final interactions = <String>[];
  NotificationPreferences saved = const NotificationPreferences();
  int markedAll = 0, markedRead = 0;
  AppNotification? detailOverride;
  @override
  Future<int> unreadCount(String appFlavor) async =>
      unreadResponse?.future ?? count;
  @override
  Future<NotificationInbox> inbox(
      {required String appFlavor,
      int page = 1,
      bool unreadOnly = false,
      String? category}) async {
    requests.add({
      'appFlavor': appFlavor,
      'page': page,
      'unreadOnly': unreadOnly,
      'category': category
    });
    if (failInbox) throw Exception('offline');
    return NotificationInbox(items: [
      notification(id: 'notice-$page', flavor: appFlavor, read: count == 0)
    ], unreadCount: count, page: page, totalPages: 2);
  }

  @override
  Future<AppNotification> detail(String id) async =>
      detailOverride ?? notification(id: id, flavor: flavor);
  @override
  Future<AppNotification> markRead(String id) async {
    markedRead++;
    count = 0;
    return notification(id: id, flavor: flavor, read: true);
  }

  @override
  Future<void> markAllRead(String appFlavor) async {
    markedAll++;
    count = 0;
  }

  @override
  Future<NotificationPreferences> preferences() async => saved;
  @override
  Future<NotificationPreferences> updatePreferences(
      NotificationPreferences value) async {
    saved = value;
    return saved;
  }

  @override
  Future<String> registerDevice(
      {required String deviceId,
      required String token,
      required String appFlavor,
      required String environment,
      required String platform}) async {
    registrations.add({
      'deviceId': deviceId,
      'token': token,
      'appFlavor': appFlavor,
      'environment': environment,
      'platform': platform
    });
    if (!registrationStarted.isCompleted) registrationStarted.complete();
    if (failRegistration) throw Exception('offline');
    return registrationResponse?.future ?? 'device-record';
  }

  @override
  Future<void> deactivateDevice(String id) async {
    deactivated.add(id);
  }

  @override
  Future<void> interaction(String id, String kind,
      {String channel = 'in_app'}) async {
    if (failInteraction) throw Exception('analytics offline');
    interactions.add('$id:$kind:$channel');
  }
}

class FakeNotificationPush extends NotificationPushClient {
  bool granted = false, available = true, deleted = false;
  String currentToken = 'first-push-token-long-enough';
  NotificationPushMessage? initial;
  final refreshController = StreamController<String>.broadcast(sync: true);
  final receivedController =
      StreamController<NotificationPushMessage>.broadcast(sync: true);
  final openedController =
      StreamController<NotificationPushMessage>.broadcast(sync: true);
  @override
  String get platform => 'android';
  @override
  Future<bool> initialize() async => available;
  @override
  Future<bool> permissionGranted({bool request = false}) async => granted;
  @override
  Future<String?> token() async => currentToken;
  @override
  Future<void> deleteToken() async {
    deleted = true;
  }

  @override
  Future<NotificationPushMessage?> initialMessage() async => initial;
  @override
  Stream<String> get tokenRefresh => refreshController.stream;
  @override
  Stream<NotificationPushMessage> get received => receivedController.stream;
  @override
  Stream<NotificationPushMessage> get opened => openedController.stream;
  Future<void> dispose() async {
    await refreshController.close();
    await receivedController.close();
    await openedController.close();
  }
}

class FakeNotificationStorage extends NotificationDeviceStorage {
  FakeNotificationStorage() : super(const FlutterSecureStorage());
  String? id;
  @override
  Future<String> installationId() async => 'stable-installation-id';
  @override
  Future<String?> registrationId() async => id;
  @override
  Future<void> saveRegistrationId(String value) async {
    id = value;
  }

  @override
  Future<void> clearRegistrationId() async {
    id = null;
  }
}
