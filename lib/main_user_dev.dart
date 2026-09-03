import 'app/bootstrap.dart';
import 'app/config/environment_config.dart';

Future<void> main() async {
  await bootstrap(EnvironmentConfig.userDevelopment);
}
