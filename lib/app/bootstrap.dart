import 'package:flutter/material.dart';

import 'app.dart';
import 'config/app_config.dart';
import 'di/injection.dart';
import 'theme/app_colors.dart';

Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();
  AppColors.configure(config.flavor);
  await configureDependencies(config);
  runApp(AvantikaLokApp(config: config));
}
