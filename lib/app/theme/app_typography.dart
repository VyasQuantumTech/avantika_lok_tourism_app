import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_theme_config.dart';

class AppTypography {
  AppTypography._();

  /// Font comes entirely from the active theme JSON.
  ///
  /// Provider:
  ///   "fontFamily": "Karma"
  ///
  /// Customer/general:
  ///   "fontFamily": "Dancing Script"
  static String get fontFamily =>
      AppThemeConfig.instance.typographyText(
        'fontFamily',
        'Roboto',
      );

  static double _s(
      String key,
      double fallback,
      ) =>
      AppThemeConfig.instance.typography(
        key,
        fallback,
      );

  /// Central font resolver.
  ///
  /// Do not use GoogleFonts directly anywhere else in the application.
  static TextStyle _style({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? height,
    double? letterSpacing,
  }) {
    final baseStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    );

    switch (fontFamily.trim().toLowerCase()) {
      case 'karma':
        return GoogleFonts.karma(
          textStyle: baseStyle,
        );

      case 'dancing script':
      case 'dancingscript':
        return GoogleFonts.dancingScript(
          textStyle: baseStyle,
        );

      case 'roboto':
        return GoogleFonts.roboto(
          textStyle: baseStyle,
        );

      default:
        return GoogleFonts.getFont(
          fontFamily,
          textStyle: baseStyle,
        );
    }
  }

  static TextStyle get display => _style(
    fontSize: _s('displaySize', 28),
    fontWeight: FontWeight.w700,
    height: 1.15,
    color: AppColors.textPrimary,
  );

  static TextStyle get titleLarge => _style(
    fontSize: _s('titleLargeSize', 22),
    fontWeight: FontWeight.w700,
    height: 1.20,
    color: AppColors.textPrimary,
  );

  static TextStyle get title => _style(
    fontSize: _s('titleSize', 18),
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: AppColors.textPrimary,
  );

  static TextStyle get sectionTitle => _style(
    fontSize: _s('sectionSize', 16),
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: AppColors.textPrimary,
  );

  static TextStyle get body => _style(
    fontSize: _s('bodySize', 14),
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.textPrimary,
  );

  static TextStyle get label => _style(
    fontSize: _s('labelSize', 13),
    fontWeight: FontWeight.w600,
    height: 1.30,
    color: AppColors.textPrimary,
  );

  static TextStyle get caption => _style(
    fontSize: _s('captionSize', 12),
    fontWeight: FontWeight.w400,
    height: 1.35,
    color: AppColors.textSecondary,
  );

  static TextStyle get tiny => _style(
    fontSize: _s('tinySize', 10),
    fontWeight: FontWeight.w500,
    height: 1.20,
    color: AppColors.textMuted,
  );

  static TextStyle get brandTitle => titleLarge.copyWith(
    color: AppColors.primary,
  );

  static TextStyle get brandSubtitle => caption;
}