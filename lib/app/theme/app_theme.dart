import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_dimensions.dart';
import 'app_typography.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      error: AppColors.error,
    );

    final textTheme = TextTheme(
      displaySmall: AppTypography.display,
      headlineSmall: AppTypography.titleLarge,
      titleLarge: AppTypography.title,
      titleMedium: AppTypography.sectionTitle,
      bodyLarge: AppTypography.body,
      bodyMedium: AppTypography.body,
      labelLarge: AppTypography.label,
      bodySmall: AppTypography.caption,
      labelSmall: AppTypography.tiny,
    );

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.smallRadius),
      borderSide: BorderSide(color: AppColors.border),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: AppTypography.fontFamily,
      textTheme: textTheme,
      dividerColor: AppColors.divider,
      splashColor: AppColors.primary.withValues(alpha: .08),
      highlightColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTypography.title,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          side: BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: AppTypography.body.copyWith(color: AppColors.textMuted),
        labelStyle: AppTypography.body.copyWith(color: AppColors.textSecondary),
        enabledBorder: inputBorder,
        border: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: AppColors.primary, width: 1.4),
        ),
        errorBorder: inputBorder.copyWith(borderSide: BorderSide(color: AppColors.error)),
        focusedErrorBorder: inputBorder.copyWith(borderSide: BorderSide(color: AppColors.error, width: 1.4)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          textStyle: AppTypography.label,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.smallRadius)),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.border),
          textStyle: AppTypography.label,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.smallRadius)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTypography.label,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.smallRadius)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.softSurface,
        side: BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.pillRadius)),
        labelStyle: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.dialogRadius)),
        titleTextStyle: AppTypography.title,
        contentTextStyle: AppTypography.body.copyWith(color: AppColors.textSecondary),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: AppColors.primary,
        headerForegroundColor: AppColors.onPrimary,
        todayForegroundColor: WidgetStatePropertyAll(AppColors.primary),
        todayBorder: BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.dialogRadius)),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.surface,
        hourMinuteColor: AppColors.primarySoft,
        hourMinuteTextColor: AppColors.textPrimary,
        dayPeriodColor: AppColors.primarySoft,
        dayPeriodTextColor: AppColors.textPrimary,
        dialBackgroundColor: AppColors.softSurface,
        dialHandColor: AppColors.primary,
        entryModeIconColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.dialogRadius)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: AppTypography.body.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.smallRadius)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primarySoft,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => AppTypography.tiny.copyWith(
          color: states.contains(WidgetState.selected) ? AppColors.primaryDark : AppColors.navInactive,
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
        )),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? AppColors.primary : AppColors.navInactive,
        )),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.navInactive,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
        selectedLabelStyle: AppTypography.tiny.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: AppTypography.tiny,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: AppColors.primary),
    );
  }
}
