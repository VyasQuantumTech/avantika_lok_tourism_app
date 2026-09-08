import 'app_config.dart';
import 'app_environment.dart';
import 'app_flavor.dart';

class EnvironmentConfig {
  const EnvironmentConfig._();

  static const userDevelopment = AppConfig(
    flavor: AppFlavor.user,
    environment: AppEnvironment.development,
    appName: 'Avantika Lok Dev',
    baseUrl: 'https://api-dev.tirthsangam.com',
  );
}