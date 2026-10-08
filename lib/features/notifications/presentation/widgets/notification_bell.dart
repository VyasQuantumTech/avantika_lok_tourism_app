import 'package:flutter/material.dart';
import '../../../../app/di/injection.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/services/notification_service.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});
  @override
  Widget build(BuildContext context) {
    final service = getIt<NotificationService>();
    return ListenableBuilder(
        listenable: service,
        builder: (context, _) => IconButton(
            tooltip: service.unreadCount == 0
                ? 'Notifications'
                : '${service.unreadCount} unread notifications',
            onPressed: () => Navigator.of(context, rootNavigator: true)
                .pushNamed(RouteNames.notifications),
            icon: Badge(
                isLabelVisible: service.unreadCount > 0,
                label: Text(service.unreadCount > 99
                    ? '99+'
                    : '${service.unreadCount}'),
                child: const Icon(Icons.notifications_outlined))));
  }
}
