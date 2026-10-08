import 'package:avantika_lok_tourism_app/app/config/environment_config.dart';
import 'package:avantika_lok_tourism_app/app/di/injection.dart';
import 'package:avantika_lok_tourism_app/core/services/notification_service.dart';
import 'package:avantika_lok_tourism_app/features/notifications/domain/usecases/notification_actions.dart';
import 'package:avantika_lok_tourism_app/features/notifications/presentation/pages/notifications_page.dart';
import 'package:avantika_lok_tourism_app/features/notifications/presentation/pages/notification_detail_page.dart';
import 'package:avantika_lok_tourism_app/features/notifications/presentation/pages/notification_preferences_page.dart';
import 'package:avantika_lok_tourism_app/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'notification_fakes.dart';

void main() {
  late FakeNotificationRepository repository;
  late FakeNotificationPush push;
  late NotificationService service;
  setUp(() async {
    await getIt.reset();
    repository = FakeNotificationRepository();
    push = FakeNotificationPush();
    final actions = NotificationActions(repository);
    service = NotificationService(actions, EnvironmentConfig.userDevelopment,
        push, FakeNotificationStorage());
    getIt.registerSingleton<NotificationActions>(actions);
    getIt.registerSingleton<NotificationService>(service);
    getIt.registerSingleton(EnvironmentConfig.userDevelopment);
    await service.startSession();
  });
  tearDown(() async {
    service.dispose();
    await push.dispose();
    await getIt.reset();
  });
  testWidgets('inbox paginates, filters unread, and marks a flavor read',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: NotificationsPage()));
    await tester.pumpAndSettle();
    expect(find.text('Booking confirmed'), findsOneWidget);
    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();
    expect(find.text('Booking confirmed'), findsNWidgets(2));
    expect(repository.requests.last['page'], 2);
    await tester.tap(find.text('Unread'));
    await tester.pumpAndSettle();
    expect(repository.requests.last['page'], 1);
    expect(repository.requests.last['unreadOnly'], true);
    expect(repository.requests.last['appFlavor'], 'customer');
    await tester.tap(find.byTooltip('Mark all as read'));
    await tester.pumpAndSettle();
    expect(repository.markedAll, 1);
    expect(service.unreadCount, 0);
  });
  testWidgets('inbox can retry after a connection failure', (tester) async {
    repository.failInbox = true;
    await tester.pumpWidget(const MaterialApp(home: NotificationsPage()));
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    repository.failInbox = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Booking confirmed'), findsOneWidget);
  });
  testWidgets('badge displays server count and clears after read',
      (tester) async {
    repository.count = 105;
    await service.refreshUnreadCount();
    await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: NotificationBell())));
    expect(find.text('99+'), findsOneWidget);
    repository.count = 0;
    await service.refreshUnreadCount();
    await tester.pump();
    expect(find.text('99+'), findsNothing);
  });
  testWidgets('detail marks read and analytics outage does not hide content',
      (tester) async {
    repository.failInteraction = true;
    await tester.pumpWidget(
        const MaterialApp(home: NotificationDetailPage(id: 'notice-1')));
    await tester.pumpAndSettle();
    expect(find.text('Booking confirmed'), findsOneWidget);
    expect(repository.markedRead, 1);
    expect(service.unreadCount, 0);
    expect(find.text('View related details'), findsOneWidget);
  });
  testWidgets(
      'detail refuses a notification from another flavor before marking read',
      (tester) async {
    repository.flavor = 'provider';
    await tester.pumpWidget(
        const MaterialApp(home: NotificationDetailPage(id: 'notice-1')));
    await tester.pumpAndSettle();
    expect(find.text('This notification is not available in this app.'),
        findsOneWidget);
    expect(repository.markedRead, 0);
    expect(find.text('Booking confirmed'), findsNothing);
  });
  testWidgets(
      'preference center preserves security and saves explicit marketing consent',
      (tester) async {
    await tester
        .pumpWidget(const MaterialApp(home: NotificationPreferencesPage()));
    await tester.pumpAndSettle();
    final security = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, 'Security'));
    expect(security.value, true);
    expect(security.onChanged, null);
    final marketing = find.widgetWithText(SwitchListTile, 'Marketing consent');
    await tester.scrollUntilVisible(marketing, 150,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(marketing);
    await tester.pumpAndSettle();
    final save = find.text('Save settings');
    await tester.scrollUntilVisible(save, 150,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(repository.saved.marketingConsent, true);
    expect(repository.saved.categories['security'], true);
    expect(find.text('Notification settings saved.'), findsOneWidget);
  });
}
