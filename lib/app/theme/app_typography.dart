import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_theme_config.dart';

class AppTypography {
  AppTypography._();

  static String get fontFamily =>
      AppThemeConfig.instance.typographyText('fontFamily', 'Roboto');

  static double _s(String key, double fallback) =>
      AppThemeConfig.instance.typography(key, fallback);

  static TextStyle get display => TextStyle(
        fontFamily: fontFamily,
        fontSize: _s('displaySize', 28),
        fontWeight: FontWeight.w800,
        height: 1.15,
        color: AppColors.textPrimary,
      );

  static TextStyle get titleLarge => TextStyle(
        fontFamily: fontFamily,
        fontSize: _s('titleLargeSize', 22),
        fontWeight: FontWeight.w800,
        height: 1.2,
        color: AppColors.textPrimary,
      );

  static TextStyle get title => TextStyle(
        fontFamily: fontFamily,
        fontSize: _s('titleSize', 18),
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: AppColors.textPrimary,
      );

  static TextStyle get sectionTitle => TextStyle(
        fontFamily: fontFamily,
        fontSize: _s('sectionSize', 16),
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: AppColors.textPrimary,
      );

  static TextStyle get body => TextStyle(
        fontFamily: fontFamily,
        fontSize: _s('bodySize', 14),
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: AppColors.textPrimary,
      );

  static TextStyle get label => TextStyle(
        fontFamily: fontFamily,
        fontSize: _s('labelSize', 13),
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AppColors.textPrimary,
      );

  static TextStyle get caption => TextStyle(
        fontFamily: fontFamily,
        fontSize: _s('captionSize', 12),
        fontWeight: FontWeight.w400,
        height: 1.35,
        color: AppColors.textSecondary,
      );

  static TextStyle get tiny => TextStyle(
        fontFamily: fontFamily,
        fontSize: _s('tinySize', 10),
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
      );

  static TextStyle get brandTitle => titleLarge.copyWith(color: AppColors.primary);
  static TextStyle get brandSubtitle => caption;
}
