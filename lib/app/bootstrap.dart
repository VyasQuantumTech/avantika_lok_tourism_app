import 'package:flutter/material.dart';

import 'app.dart';
import 'config/app_config.dart';
import 'di/injection.dart';
import 'theme/app_theme_config.dart';

Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppThemeConfig.load(config.flavor);
  await configureDependencies(config);
  runApp(AvantikaLokApp(config: config));
}
