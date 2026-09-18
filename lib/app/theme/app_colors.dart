import 'package:flutter/material.dart';

import 'app_theme_config.dart';

class AppColors {
  AppColors._();

  static Color _c(String key, Color fallback) =>
      AppThemeConfig.instance.color(key, fallback: fallback);

  static Color get primary => _c('primary', const Color(0xFFF45170));
  static Color get primaryDark => _c('primaryDark', const Color(0xFFD93459));
  static Color get primarySoft => _c('primarySoft', const Color(0xFFFFF0F3));
  static Color get secondary => _c('secondary', const Color(0xFFFF755A));
  static Color get accent => _c('accent', const Color(0xFFFFAA57));
  static Color get brandGradientStart => _c('gradientStart', primary);
  static Color get brandGradientEnd => _c('gradientEnd', primaryDark);
  static Color get background => _c('background', const Color(0xFFF8F9FB));
  static Color get surface => _c('surface', Colors.white);
  static Color get softSurface => _c('surfaceSoft', const Color(0xFFF3F5F8));
  static Color get surfaceElevated => _c('surfaceElevated', Colors.white);
  static Color get border => _c('border', const Color(0xFFE7EAF0));
  static Color get divider => _c('divider', const Color(0xFFEDF0F4));
  static Color get textPrimary => _c('textPrimary', const Color(0xFF20242C));
  static Color get textSecondary => _c('textSecondary', const Color(0xFF626A78));
  static Color get textMuted => _c('textMuted', const Color(0xFF9299A6));
  static Color get onPrimary => _c('onPrimary', Colors.white);
  static Color get navInactive => _c('navInactive', const Color(0xFF7D8594));
  static Color get success => _c('success', const Color(0xFF198754));
  static Color get successSoft => _c('successSoft', const Color(0xFFEAF7F0));
  static Color get warning => _c('warning', const Color(0xFFB7791F));
  static Color get warningSoft => _c('warningSoft', const Color(0xFFFFF7E6));
  static Color get error => _c('error', const Color(0xFFC83B50));
  static Color get errorSoft => _c('errorSoft', const Color(0xFFFFF0F2));
  static Color get info => _c('info', const Color(0xFF2F6FED));
  static Color get infoSoft => _c('infoSoft', const Color(0xFFEDF3FF));
  static Color get star => _c('star', const Color(0xFFF5A623));
  static Color get shadow => _c('shadow', const Color(0x16000000));
  static Color get scrim => _c('scrim', const Color(0x66000000));
  static Color get splashBackground => _c('splashBackground', background);
  static Color get brandBorder => _c('brandBorder', border);
  static Color get brandSoft => _c('brandSoft', primarySoft);
  static Color get destinationOverlay => _c('destinationOverlay', const Color(0x88000000));
  static Color get transparent => _c('transparent', Colors.transparent);
  static Color get mediaBackground => _c('mediaBackground', Colors.black);
  static Color get onMedia => _c('onMedia', Colors.white);

  // Backward-compatible aliases used by older screens.
  static Color get iconPink => secondary;
  static Color get headingPink => primaryDark;
}
