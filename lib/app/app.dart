import 'package:flutter/material.dart';

import 'config/app_config.dart';
import 'router/app_router.dart';
import 'router/route_names.dart';
import 'theme/app_theme.dart';

class AvantikaLokApp extends StatelessWidget {
  const AvantikaLokApp({
    required this.config,
    super.key,
  });

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: config.appName,
      theme: AppTheme.light,
      initialRoute: RouteNames.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
