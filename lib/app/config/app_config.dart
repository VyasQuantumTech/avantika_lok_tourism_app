import 'app_environment.dart';
import 'app_flavor.dart';

class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.environment,
    required this.appName,
    required this.baseUrl,
  });

  final AppFlavor flavor;
  final AppEnvironment environment;
  final String appName;
  final String baseUrl;
}
