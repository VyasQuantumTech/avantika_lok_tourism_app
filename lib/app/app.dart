import 'package:flutter/material.dart';

import '../features/system/presentation/pages/health_page.dart';
import 'config/app_config.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF57C00)),
        useMaterial3: true,
      ),
      home: const HealthPage(),
    );
  }
}
