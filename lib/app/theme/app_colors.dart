import 'package:flutter/material.dart';

import '../config/app_flavor.dart';

class AppColors {
  const AppColors._();

  static AppFlavor _flavor = AppFlavor.user;

  static void configure(AppFlavor flavor) {
    _flavor = flavor;
  }

  static bool get _provider => _flavor == AppFlavor.provider;

  // User flavor intentionally keeps the existing palette unchanged.
  // Provider flavor uses the blue/cyan/violet family from the supplied logo.
  static Color get primary =>
      _provider ? const Color(0xFF258FC4) : const Color(0xFFFF755A);
  static Color get primaryDark =>
      _provider ? const Color(0xFF4A238D) : const Color(0xFFF45170);
  static Color get accent =>
      _provider ? const Color(0xFF24B9D6) : const Color(0xFFFFAA57);
  static Color get splashBackground =>
      _provider ? const Color(0xFFE8F7FB) : const Color(0xFFFFE5CF);
  static Color get border =>
      _provider ? const Color(0xFFDDECF4) : const Color(0xFFF0E4E5);
  static Color get iconPink =>
      _provider ? const Color(0xFF2A9CC9) : const Color(0xFFFF6D8E);
  static Color get headingPink =>
      _provider ? const Color(0xFF4A238D) : const Color(0xFFF63F6C);

  static Color get brandGradientStart =>
      _provider ? const Color(0xFF28B8D6) : const Color(0xFFFFAF58);
  static Color get brandGradientEnd =>
      _provider ? const Color(0xFF4A238D) : const Color(0xFFE92F61);
  static Color get brandBorder =>
      _provider ? const Color(0xFFCCE8F3) : const Color(0xFFFFD5DB);
  static Color get brandSoft =>
      _provider ? const Color(0xFFDDF3F9) : const Color(0xFFFFE4C7);
  static Color get destinationOverlay =>
      _provider ? const Color(0xBB39237F) : const Color(0xBBF34266);

  static const Color background = Color(0xFFFDFDFD);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color softSurface = Color(0xFFF8F8F8);
  static const Color textPrimary = Color(0xFF555555);
  static const Color textSecondary = Color(0xFF8B8B8B);
  static const Color textMuted = Color(0xFFB1B1B1);
  static const Color navInactive = Color(0xFF7F7F7F);
  static const Color shadow = Color(0x16000000);
}
