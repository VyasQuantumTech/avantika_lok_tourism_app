import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationPushMessage {
  const NotificationPushMessage({required this.id, required this.appFlavor});
  final String id, appFlavor;
}

abstract class NotificationPushClient {
  String? get platform;
  Future<bool> initialize();
  Future<bool> permissionGranted({bool request = false});
  Future<String?> token();
  Future<void> deleteToken();
  Future<NotificationPushMessage?> initialMessage();
  Stream<String> get tokenRefresh;
  Stream<NotificationPushMessage> get received;
  Stream<NotificationPushMessage> get opened;
}

class FirebaseNotificationPushClient implements NotificationPushClient {
  bool _available = false;
  @override
  String? get platform => kIsWeb
      ? null
      : switch (defaultTargetPlatform) {
          TargetPlatform.android => 'android',
          TargetPlatform.iOS => 'ios',
          _ => null
        };

  @override
  Future<bool> initialize() async {
    if (platform == null) return false;
    try {
      if (Firebase.apps.isEmpty) {
        // Values must belong to the selected role/environment build. Native
        // Firebase configuration is also supported when no defines are supplied.
        const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
        const appId = String.fromEnvironment('FIREBASE_APP_ID');
        const senderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
        const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
        const bundleId = String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID');
        await Firebase.initializeApp(
            options: apiKey.isEmpty ||
                    appId.isEmpty ||
                    senderId.isEmpty ||
                    projectId.isEmpty
                ? null
                : const FirebaseOptions(
                    apiKey: apiKey,
                    appId: appId,
                    messagingSenderId: senderId,
                    projectId: projectId,
                    iosBundleId: bundleId == '' ? null : bundleId));
      }
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
              alert: false, badge: false, sound: false);
      _available = true;
    } catch (_) {
      // The inbox does not depend on Firebase configuration or OS permission.
      _available = false;
    }
    return _available;
  }

  @override
  Future<bool> permissionGranted({bool request = false}) async {
    if (!_available) return false;
    final settings = request
        ? await FirebaseMessaging.instance.requestPermission()
        : await FirebaseMessaging.instance.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<String?> token() async {
    if (!_available) return null;
    if (platform == 'ios' &&
        await FirebaseMessaging.instance.getAPNSToken() == null) {
      return null;
    }
    return FirebaseMessaging.instance.getToken();
  }

  @override
  Future<void> deleteToken() async {
    if (_available) await FirebaseMessaging.instance.deleteToken();
  }

  NotificationPushMessage _message(RemoteMessage message) =>
      NotificationPushMessage(
          id: message.data['notificationId']?.toString() ?? '',
          appFlavor: message.data['appFlavor']?.toString() ?? '');
  @override
  Future<NotificationPushMessage?> initialMessage() async {
    if (!_available) return null;
    final value = await FirebaseMessaging.instance.getInitialMessage();
    return value == null ? null : _message(value);
  }

  @override
  Stream<String> get tokenRefresh => _available
      ? FirebaseMessaging.instance.onTokenRefresh
      : const Stream.empty();
  @override
  Stream<NotificationPushMessage> get received => _available
      ? FirebaseMessaging.onMessage.map(_message)
      : const Stream.empty();
  @override
  Stream<NotificationPushMessage> get opened => _available
      ? FirebaseMessaging.onMessageOpenedApp.map(_message)
      : const Stream.empty();
}
