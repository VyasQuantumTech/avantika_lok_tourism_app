import 'app_theme_config.dart';

class AppDimensions {
  AppDimensions._();

  static double get pagePadding => AppThemeConfig.instance.spacing('page', 16);
  static double get sectionGap => AppThemeConfig.instance.spacing('section', 22);
  static double get cardPadding => AppThemeConfig.instance.spacing('card', 16);
  static double get compactGap => AppThemeConfig.instance.spacing('compact', 10);
  static double get cardRadius => AppThemeConfig.instance.shape('cardRadius', 18);
  static double get smallRadius => AppThemeConfig.instance.shape('controlRadius', 14);
  static double get pillRadius => AppThemeConfig.instance.shape('pillRadius', 999);
  static double get dialogRadius => AppThemeConfig.instance.shape('dialogRadius', 22);
  static const double drawerWidth = 286;
}
