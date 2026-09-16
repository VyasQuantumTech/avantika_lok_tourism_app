import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import '../../core/ network/api_client.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_user.dart';
import '../../features/auth/domain/usecases/logout_user.dart';
import '../../features/auth/domain/usecases/register_user.dart';
import '../../features/auth/domain/usecases/restore_session.dart';
import '../../features/explore/data/datasources/tourism_remote_data_source.dart';
import '../../features/explore/data/repositories/tourism_repository_impl.dart';
import '../../features/explore/domain/repositories/tourism_repository.dart';
import '../../features/explore/domain/usecases/get_tourism_place_detail.dart';
import '../../features/explore/domain/usecases/get_tourism_places.dart';
import '../../features/home/data/datasources/home_local_data_source.dart';
import '../../features/home/data/repositories/home_repository_impl.dart';
import '../../features/home/domain/repositories/home_repository.dart';
import '../../features/home/domain/usecases/get_home_dashboard.dart';
import '../../features/profile/data/datasources/profile_remote_data_source.dart';
import '../../features/pooja/data/datasources/pooja_remote_data_source.dart';
import '../../features/pooja/data/repositories/pooja_repository_impl.dart';
import '../../features/pooja/domain/repositories/pooja_repository.dart';
import '../../features/pooja/domain/usecases/pooja_actions.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/domain/usecases/get_my_profile.dart';
import '../../features/profile/domain/usecases/get_my_profile_dashboard.dart';
import '../../features/profile/domain/usecases/update_my_profile.dart';
import '../../features/profile/domain/usecases/update_my_provider_profile.dart';
import '../../features/provider/data/datasources/provider_remote_data_source.dart';
import '../../features/provider/data/repositories/provider_repository_impl.dart';
import '../../features/provider/domain/repositories/provider_repository.dart';
import '../../features/provider/domain/usecases/check_provider_status.dart';
import '../../features/provider/domain/usecases/register_provider.dart';
import '../../features/provider/domain/usecases/manage_provider_kyc.dart';
import '../../features/system/data/datasources/system_remote_data_source.dart';
import '../../features/system/data/repositories/system_repository_impl.dart';
import '../../features/system/domain/repositories/system_repository.dart';
import '../../features/system/domain/usecases/get_service_health.dart';
import '../config/app_config.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies(AppConfig config) async {
  await getIt.reset();

  getIt.registerSingleton<AppConfig>(config);
  getIt.registerLazySingleton<http.Client>(http.Client.new);
  getIt.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );
  getIt.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService(getIt<FlutterSecureStorage>()),
  );
  getIt.registerLazySingleton<ApiClient>(
    () => ApiClient(
      baseUrl: getIt<AppConfig>().baseUrl,
      client: getIt<http.Client>(),
      secureStorage: getIt<SecureStorageService>(),
    ),
  );

  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      getIt<AuthRemoteDataSource>(),
      getIt<SecureStorageService>(),
    ),
  );
  getIt.registerLazySingleton<LoginUser>(
    () => LoginUser(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<RegisterUser>(
    () => RegisterUser(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<RestoreSession>(
    () => RestoreSession(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<LogoutUser>(
    () => LogoutUser(getIt<AuthRepository>()),
  );


  getIt.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(getIt<ProfileRemoteDataSource>()),
  );
  getIt.registerLazySingleton<GetMyProfile>(
    () => GetMyProfile(getIt<ProfileRepository>()),
  );
  getIt.registerLazySingleton<GetMyProfileDashboard>(
    () => GetMyProfileDashboard(getIt<ProfileRepository>()),
  );
  getIt.registerLazySingleton<UpdateMyProfile>(
    () => UpdateMyProfile(getIt<ProfileRepository>()),
  );
  getIt.registerLazySingleton<UpdateMyProviderProfile>(
    () => UpdateMyProviderProfile(getIt<ProfileRepository>()),
  );

  getIt.registerLazySingleton<ProviderRemoteDataSource>(
    () => ProviderRemoteDataSourceImpl(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<ProviderRepository>(
    () => ProviderRepositoryImpl(getIt<ProviderRemoteDataSource>()),
  );
  getIt.registerLazySingleton<CheckProviderStatus>(
    () => CheckProviderStatus(getIt<ProviderRepository>()),
  );
  getIt.registerLazySingleton<RegisterProvider>(
    () => RegisterProvider(getIt<ProviderRepository>()),
  );
  getIt.registerLazySingleton<ManageProviderKyc>(
    () => ManageProviderKyc(getIt<ProviderRepository>()),
  );


  getIt.registerLazySingleton<PoojaRemoteDataSource>(
    () => PoojaRemoteDataSourceImpl(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<PoojaRepository>(
    () => PoojaRepositoryImpl(getIt<PoojaRemoteDataSource>()),
  );
  getIt.registerLazySingleton<CustomerPoojaActions>(
    () => CustomerPoojaActions(getIt<PoojaRepository>()),
  );
  getIt.registerLazySingleton<PanditPoojaActions>(
    () => PanditPoojaActions(getIt<PoojaRepository>()),
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

  getIt.registerLazySingleton<TourismRemoteDataSource>(
    () => TourismRemoteDataSourceImpl(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<TourismRepository>(
    () => TourismRepositoryImpl(getIt<TourismRemoteDataSource>()),
  );
  getIt.registerLazySingleton<GetTourismPlaces>(
    () => GetTourismPlaces(getIt<TourismRepository>()),
  );
  getIt.registerLazySingleton<GetTourismPlaceDetail>(
    () => GetTourismPlaceDetail(getIt<TourismRepository>()),
  );
}
