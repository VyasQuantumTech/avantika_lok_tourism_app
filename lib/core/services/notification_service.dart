import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../app/config/app_config.dart';
import '../../app/config/app_flavor.dart';
import '../../features/notifications/domain/entities/app_notification.dart';
import '../../features/notifications/domain/usecases/notification_actions.dart';
import '../storage/notification_device_storage.dart';
import 'notification_push_client.dart';

String notificationAppFlavor(AppFlavor flavor) =>
    flavor == AppFlavor.user ? 'customer' : flavor.name;

class NotificationService extends ChangeNotifier {
  NotificationService(this._actions, this._config, this._push, this._storage);
  final NotificationActions _actions;
  final AppConfig _config;
  final NotificationPushClient _push;
  final NotificationDeviceStorage _storage;
  final _foreground = StreamController<AppNotification>.broadcast();
  Stream<AppNotification> get foreground => _foreground.stream;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  Timer? _timer;
  Future<void> _registration = Future.value();
  Future<void>? _starting;
  int _generation = 0;
  bool _active = false,
      _disposed = false,
      _refreshing = false,
      _pushAvailable = false;
  String? _registeredToken;
  int unreadCount = 0;
  String? pendingNotificationId;
  String get appFlavor => notificationAppFlavor(_config.flavor);
  bool get active => _active;
  bool get pushAvailable => _pushAvailable;

  Future<void> initialize() async {
    try {
      _pushAvailable = await _push.initialize();
    } catch (_) {
      _pushAvailable = false;
    }
    _subscriptions.add(_push.tokenRefresh
        .listen((token) => _queueRegistration(token), onError: (_) {}));
    _subscriptions.add(_push.received
        .listen((value) => unawaited(_receive(value)), onError: (_) {}));
    _subscriptions.add(_push.opened.listen(_open, onError: (_) {}));
    try {
      final initial = await _push.initialMessage();
      if (initial != null) _open(initial);
    } catch (_) {}
  }

  Future<void> startSession() {
    if (_starting != null) return _starting!;
    _active = true;
    final generation = _generation;
    final work = _start(generation);
    _starting = work;
    return work.whenComplete(() {
      if (_starting == work) _starting = null;
    });
  }

  Future<void> _start(int generation) async {
    _timer?.cancel();
    _timer = Timer.periodic(
        const Duration(seconds: 60), (_) => unawaited(refreshUnreadCount()));
    await refreshUnreadCount();
    if (!_active || generation != _generation) return;
    try {
      if (await _push.permissionGranted()) {
        final token = await _push.token();
        if (token != null && _active && generation == _generation) {
          _queueRegistration(token);
        }
      }
    } catch (_) {/* Retried on resume; push never blocks authentication. */}
    _notify();
  }

  Future<void> resume() async {
    if (_active) await startSession();
  }

  void pause() {
    _timer?.cancel();
  }

  Future<void> refreshUnreadCount() async {
    if (!_active || _refreshing) return;
    _refreshing = true;
    final generation = _generation;
    try {
      final count = await _actions.unreadCount(appFlavor);
      if (_active && generation == _generation) {
        unreadCount = count;
        _notify();
      }
    } catch (_) {
      /* Keep the last authoritative count during connectivity loss. */
    } finally {
      _refreshing = false;
    }
  }

  void _queueRegistration(String token) {
    if (!_active) return;
    final generation = _generation;
    _registration = _registration.then((_) async {
      if (!_active || generation != _generation || _push.platform == null) {
        return;
      }
      try {
        final installation = await _storage.installationId();
        if (!_active || generation != _generation) return;
        final id = await _actions.registerDevice(
            deviceId: installation,
            token: token,
            appFlavor: appFlavor,
            environment: _config.environment.name,
            platform: _push.platform!);
        await _storage.saveRegistrationId(id);
        if (!_active || generation != _generation) {
          await _actions.deactivateDevice(id);
        } else {
          _registeredToken = token;
        }
      } catch (_) {/* Retry token registration on the next app resume. */}
    });
  }

  Future<bool> enablePush() async {
    if (!_active || !_pushAvailable) return false;
    if (!await _push.permissionGranted(request: true)) return false;
    final token = await _push.token();
    if (token == null) return false;
    _queueRegistration(token);
    await _registration;
    return _registeredToken == token && _active;
  }

  void _open(NotificationPushMessage message) {
    if (message.id.isEmpty || message.appFlavor != appFlavor) return;
    pendingNotificationId = message.id;
    _notify();
  }

  void openNotification(String id) {
    if (!_active) return;
    pendingNotificationId = id;
    _notify();
  }

  String? takePendingNotification() {
    if (!_active) return null;
    final id = pendingNotificationId;
    pendingNotificationId = null;
    return id;
  }

  Future<void> _receive(NotificationPushMessage message) async {
    if (!_active || message.appFlavor != appFlavor || message.id.isEmpty) {
      return;
    }
    final generation = _generation;
    try {
      final item = await _actions.detail(message.id);
      if (!_active ||
          generation != _generation ||
          item.appFlavor != appFlavor) {
        return;
      }
      _foreground.add(item);
      unawaited(recordInteraction(item.id, 'delivered', channel: 'push'));
      await refreshUnreadCount();
    } catch (_) {
      /* Never show unverified push content for a signed-out account. */
    }
  }

  Future<void> recordInteraction(String id, String kind,
      {String channel = 'in_app'}) async {
    if (!_active) return;
    try {
      await _actions.interaction(id, kind, channel: channel);
    } catch (_) {}
  }

  Future<void> stopSession() async {
    _active = false;
    _generation++;
    _starting = null;
    _refreshing = false;
    _timer?.cancel();
    pendingNotificationId = null;
    unreadCount = 0;
    _registeredToken = null;
    _notify();
    // Wait for token rotations before removing credentials. A late registration
    // must not reactivate the previous account's device after logout.
    await _registration;
    try {
      await _push.deleteToken();
    } catch (_) {}
    try {
      final id = await _storage.registrationId();
      if (id != null) await _actions.deactivateDevice(id);
      await _storage.clearRegistrationId();
    } catch (_) {
      /* Local token deletion still stops this device receiving push. */
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _active = false;
    _generation++;
    _timer?.cancel();
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    unawaited(_foreground.close());
    super.dispose();
  }
}
