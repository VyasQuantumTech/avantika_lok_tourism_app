import '../core/widgets/error_fallback.dart';
import '../core/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'config/app_config.dart';
import 'di/injection.dart';
import 'theme/app_theme_config.dart';

Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  installAppErrorFallback();
  await AppThemeConfig.load(config.flavor);
  await configureDependencies(config);
  await getIt<NotificationService>().initialize();
  runApp(AvantikaLokApp(config: config));
}
