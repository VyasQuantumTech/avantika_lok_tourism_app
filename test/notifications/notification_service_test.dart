import 'dart:async';
import 'package:avantika_lok_tourism_app/app/config/environment_config.dart';
import 'package:avantika_lok_tourism_app/core/services/notification_service.dart';
import 'package:avantika_lok_tourism_app/core/services/notification_push_client.dart';
import 'package:avantika_lok_tourism_app/features/notifications/domain/usecases/notification_actions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'notification_fakes.dart';

void main() {
  late FakeNotificationRepository repository;
  late FakeNotificationPush push;
  late FakeNotificationStorage storage;
  late NotificationService service;
  setUp(() {
    repository = FakeNotificationRepository();
    push = FakeNotificationPush();
    storage = FakeNotificationStorage();
    service = NotificationService(NotificationActions(repository),
        EnvironmentConfig.userDevelopment, push, storage);
  });
  tearDown(() async {
    service.dispose();
    await push.dispose();
  });
  test('denied permission leaves inbox functional without device registration',
      () async {
    await service.initialize();
    await service.startSession();
    expect(service.unreadCount, 3);
    expect(repository.registrations, isEmpty);
    expect(await service.enablePush(), false);
  });
  test('all six flavor/environment builds register the correct device identity',
      () async {
    for (final config in [
      EnvironmentConfig.userDevelopment,
      EnvironmentConfig.userProduction,
      EnvironmentConfig.providerDevelopment,
      EnvironmentConfig.providerProduction,
      EnvironmentConfig.adminDevelopment,
      EnvironmentConfig.adminProduction
    ]) {
      final localPush = FakeNotificationPush()..granted = true;
      final localRepository = FakeNotificationRepository();
      final local = NotificationService(NotificationActions(localRepository),
          config, localPush, FakeNotificationStorage());
      await local.initialize();
      await local.startSession();
      expect(await local.enablePush(), true);
      expect(localRepository.registrations.last, {
        'deviceId': 'stable-installation-id',
        'token': localPush.currentToken,
        'appFlavor': notificationAppFlavor(config.flavor),
        'environment': config.environment.name,
        'platform': 'android'
      });
      await local.stopSession();
      local.dispose();
      await localPush.dispose();
    }
  });
  test('failed registration is not reported as enabled and retries on resume',
      () async {
    repository.failRegistration = true;
    push.granted = true;
    await service.initialize();
    await service.startSession();
    expect(await service.enablePush(), false);
    repository.failRegistration = false;
    await service.resume();
    expect(await service.enablePush(), true);
  });
  test('cold-start push waits for authentication and wrong flavor is ignored',
      () async {
    push.initial =
        const NotificationPushMessage(id: 'notice-1', appFlavor: 'customer');
    await service.initialize();
    expect(service.takePendingNotification(), null);
    await service.startSession();
    expect(service.takePendingNotification(), 'notice-1');
    push.openedController
        .add(const NotificationPushMessage(id: 'wrong', appFlavor: 'provider'));
    expect(service.pendingNotificationId, null);
  });
  test('logout discards late unread responses', () async {
    repository.unreadResponse = Completer<int>();
    final starting = service.startSession();
    await service.stopSession();
    repository.unreadResponse!.complete(88);
    await starting;
    expect(service.active, false);
    expect(service.unreadCount, 0);
  });
  test(
      'logout deactivates an in-flight registration before removing the session',
      () async {
    push.granted = true;
    repository.registrationResponse = Completer<String>();
    await service.initialize();
    await service.startSession();
    await repository.registrationStarted.future;
    final stopping = service.stopSession();
    repository.registrationResponse!.complete('late-device');
    await stopping;
    expect(repository.deactivated, contains('late-device'));
    expect(push.deleted, true);
    expect(storage.id, null);
    expect(service.active, false);
    push.refreshController.add('late-rotation-token');
    await Future<void>.delayed(Duration.zero);
    expect(repository.registrations.length, 1);
  });
  test('rotated token is registered with the same installation identity',
      () async {
    push.granted = true;
    await service.initialize();
    await service.startSession();
    await service.enablePush();
    push.currentToken = 'rotated-push-token-long-enough';
    push.refreshController.add(push.currentToken);
    await service.enablePush();
    expect(repository.registrations.last['token'], push.currentToken);
    expect(repository.registrations.map((item) => item['deviceId']).toSet(),
        {'stable-installation-id'});
  });
  test('foreground notifications are verified and do not leak after logout',
      () async {
    await service.initialize();
    await service.startSession();
    final values = <String>[];
    final subscription =
        service.foreground.listen((item) => values.add(item.id));
    push.receivedController
        .add(const NotificationPushMessage(id: 'owned', appFlavor: 'customer'));
    await Future<void>.delayed(Duration.zero);
    expect(values, ['owned']);
    await service.stopSession();
    push.receivedController.add(
        const NotificationPushMessage(id: 'signed-out', appFlavor: 'customer'));
    await Future<void>.delayed(Duration.zero);
    expect(values, ['owned']);
    await subscription.cancel();
  });
  test('interaction reporting failure does not block normal notification use',
      () async {
    repository.failInteraction = true;
    await service.startSession();
    await service.recordInteraction('notice-1', 'opened');
    expect(service.active, true);
  });
}
