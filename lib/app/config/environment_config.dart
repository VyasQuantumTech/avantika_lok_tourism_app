import 'app_config.dart';
import 'app_environment.dart';
import 'app_flavor.dart';

class EnvironmentConfig {
  const EnvironmentConfig._();

  static const String _developmentBaseUrl = String.fromEnvironment(
    'AVANTIKA_API_BASE_URL',
    defaultValue: 'https://api-dev.tirthsangam.com',
  );

  static const String _productionBaseUrl = String.fromEnvironment(
    'AVANTIKA_API_BASE_URL',
    defaultValue: 'https://api.tirthsangam.com',
  );

  static const String _userLogo = 'assets/images/common/user_logo.png';
  static const String _providerLogo = 'assets/images/common/provider_logo.png';
  static const String _adminLogo = 'assets/images/common/logo_mark.png';

  static const userDevelopment = AppConfig(
    flavor: AppFlavor.user,
    environment: AppEnvironment.development,
    appName: 'Avantika Lok',
    baseUrl: _developmentBaseUrl,
    logoAsset: _userLogo,
  );

  static const userProduction = AppConfig(
    flavor: AppFlavor.user,
    environment: AppEnvironment.production,
    appName: 'Avantika Lok',
    baseUrl: _productionBaseUrl,
    logoAsset: _userLogo,
  );

  static const providerDevelopment = AppConfig(
    flavor: AppFlavor.provider,
    environment: AppEnvironment.development,
    appName: 'Avantika Lok Seva provider',
    baseUrl: _developmentBaseUrl,
    logoAsset: _providerLogo,
  );

  static const providerProduction = AppConfig(
    flavor: AppFlavor.provider,
    environment: AppEnvironment.production,
    appName: 'Avantika Lok Seva provider',
    baseUrl: _productionBaseUrl,
    logoAsset: _providerLogo,
  );

  static const adminDevelopment = AppConfig(
    flavor: AppFlavor.admin,
    environment: AppEnvironment.development,
    appName: 'Avantika Lok Admin Dev',
    baseUrl: _developmentBaseUrl,
    logoAsset: _adminLogo,
  );

  static const adminProduction = AppConfig(
    flavor: AppFlavor.admin,
    environment: AppEnvironment.production,
    appName: 'Avantika Lok Admin',
    baseUrl: _productionBaseUrl,
    logoAsset: _adminLogo,
  );
}
