import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/app_flavor.dart';

class AppThemeConfig {
  AppThemeConfig._(this._data);

  final Map<String, dynamic> _data;

  static late AppThemeConfig _instance;

  static AppThemeConfig get instance => _instance;

  static Future<void> load(AppFlavor flavor) async {
    final asset = flavor == AppFlavor.provider
        ? 'assets/theme/provider_colour.json'
        : 'assets/theme/general_colours.json';
    final raw = await rootBundle.loadString(asset);
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid application theme JSON.');
    }
    _instance = AppThemeConfig._(decoded);
  }

  Map<String, dynamic> get _colors =>
      (_data['colors'] as Map?)?.cast<String, dynamic>() ?? const {};
  Map<String, dynamic> get _typography =>
      (_data['typography'] as Map?)?.cast<String, dynamic>() ?? const {};
  Map<String, dynamic> get _shape =>
      (_data['shape'] as Map?)?.cast<String, dynamic>() ?? const {};
  Map<String, dynamic> get _spacing =>
      (_data['spacing'] as Map?)?.cast<String, dynamic>() ?? const {};
  Map<String, dynamic> get _motion =>
      (_data['motion'] as Map?)?.cast<String, dynamic>() ?? const {};

  Color color(String key, {Color fallback = Colors.transparent}) {
    final value = _colors[key]?.toString().trim();
    if (value == null || value.isEmpty) return fallback;
    final hex = value.replaceFirst('#', '');
    final normalized = hex.length == 6 ? 'FF$hex' : hex;
    final parsed = int.tryParse(normalized, radix: 16);
    return parsed == null ? fallback : Color(parsed);
  }

  double typography(String key, double fallback) =>
      (_typography[key] as num?)?.toDouble() ?? fallback;

  String typographyText(String key, String fallback) =>
      _typography[key]?.toString() ?? fallback;

  double shape(String key, double fallback) =>
      (_shape[key] as num?)?.toDouble() ?? fallback;

  double spacing(String key, double fallback) =>
      (_spacing[key] as num?)?.toDouble() ?? fallback;

  int motion(String key, int fallback) =>
      (_motion[key] as num?)?.toInt() ?? fallback;
}
