import 'package:flutter/material.dart';

import 'app.dart';
import 'config/app_config.dart';
import 'di/injection.dart';

Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies(config);
  runApp(AvantikaLokApp(config: config));
}
