import 'dart:async';
import 'package:flutter/material.dart';
import '../core/services/notification_service.dart';
import '../features/notifications/domain/entities/app_notification.dart';
import 'config/app_config.dart';
import 'di/injection.dart';
import 'router/app_router.dart';
import 'router/route_names.dart';
import 'theme/app_theme.dart';

class AvantikaLokApp extends StatefulWidget {
  const AvantikaLokApp({required this.config, super.key});
  final AppConfig config;
  @override
  State<AvantikaLokApp> createState() => _AvantikaLokAppState();
}

class _AvantikaLokAppState extends State<AvantikaLokApp>
    with WidgetsBindingObserver {
  final _navigator = GlobalKey<NavigatorState>();
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  late final NotificationService _notifications;
  late final _NotificationNavigationObserver _observer;
  StreamSubscription<AppNotification>? _foreground;
  String? _route;
  bool _scheduled = false;
  @override
  void initState() {
    super.initState();
    _notifications = getIt<NotificationService>();
    _observer = _NotificationNavigationObserver((route) {
      _route = route;
      _scheduleOpen();
    });
    _notifications.addListener(_scheduleOpen);
    _foreground = _notifications.foreground.listen((item) {
      if (!mounted || !_notifications.active || !_ready) return;
      _messenger.currentState?.showSnackBar(SnackBar(
          content: Text(item.title),
          action: SnackBarAction(
              label: 'View',
              onPressed: () => _notifications.openNotification(item.id))));
    });
    WidgetsBinding.instance.addObserver(this);
  }

  bool get _ready =>
      _route != null &&
      !const [
        RouteNames.splash,
        RouteNames.login,
        RouteNames.register,
        RouteNames.providerGate,
        RouteNames.providerRegistration
      ].contains(_route);
  void _scheduleOpen() {
    if (!_notifications.active) _messenger.currentState?.clearSnackBars();
    if (_scheduled ||
        !_ready ||
        !_notifications.active ||
        _notifications.pendingNotificationId == null) {
      return;
    }
    _scheduled = true;
    WidgetsBinding.instance.ensureVisualUpdate();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted || !_ready || !_notifications.active) return;
      final id = _notifications.takePendingNotification();
      if (id != null) {
        _navigator.currentState?.pushNamed(RouteNames.notificationDetail,
            arguments: {'id': id, 'channel': 'push'});
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_notifications.resume());
    } else {
      _notifications.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notifications.removeListener(_scheduleOpen);
    unawaited(_foreground?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
      debugShowCheckedModeBanner: false,
      title: widget.config.appName,
      theme: AppTheme.light,
      navigatorKey: _navigator,
      scaffoldMessengerKey: _messenger,
      navigatorObservers: [_observer],
      initialRoute: RouteNames.splash,
      onGenerateRoute: AppRouter.onGenerateRoute);
}

class _NotificationNavigationObserver extends NavigatorObserver {
  _NotificationNavigationObserver(this.onRoute);
  final ValueChanged<String?> onRoute;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      onRoute(route.settings.name);
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      onRoute(previousRoute?.settings.name);
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      onRoute(newRoute?.settings.name);
}
