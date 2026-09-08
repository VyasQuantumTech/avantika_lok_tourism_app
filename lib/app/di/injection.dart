import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import '../../core/ network/api_client.dart';
import '../../features/system/data/datasources/system_remote_data_source.dart';
import '../../features/system/data/repositories/system_repository_impl.dart';
import '../../features/system/domain/repositories/system_repository.dart';
import '../../features/system/domain/usecases/get_service_health.dart';
import '../../features/home/data/datasources/home_local_data_source.dart';
import '../../features/home/data/repositories/home_repository_impl.dart';
import '../../features/home/domain/repositories/home_repository.dart';
import '../../features/home/domain/usecases/get_home_dashboard.dart';
import '../config/app_config.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies(AppConfig config) async {
  await getIt.reset();

  getIt.registerSingleton<AppConfig>(config);
  getIt.registerLazySingleton<http.Client>(http.Client.new);
  getIt.registerLazySingleton<ApiClient>(
    () => ApiClient(
      baseUrl: getIt<AppConfig>().baseUrl,
      client: getIt<http.Client>(),
    ),
  );
  getIt.registerLazySingleton<SystemRemoteDataSource>(
    () => SystemRemoteDataSourceImpl(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<SystemRepository>(
    () => SystemRepositoryImpl(getIt<SystemRemoteDataSource>()),
  );
  getIt.registerLazySingleton<GetServiceHealth>(
    () => GetServiceHealth(getIt<SystemRepository>()),
  );

  getIt.registerLazySingleton<HomeLocalDataSource>(
    HomeLocalDataSourceImpl.new,
  );
  getIt.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(getIt<HomeLocalDataSource>()),
  );
  getIt.registerLazySingleton<GetHomeDashboard>(
    () => GetHomeDashboard(getIt<HomeRepository>()),
  );
}
