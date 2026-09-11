import '../../domain/entities/provider_account_status.dart';
import '../../domain/repositories/provider_repository.dart';
import '../datasources/provider_remote_data_source.dart';

class ProviderRepositoryImpl implements ProviderRepository {
  const ProviderRepositoryImpl(this._remoteDataSource);

  final ProviderRemoteDataSource _remoteDataSource;

  @override
  Future<ProviderAccountStatus> getCurrentUserProviderStatus() {
    return _remoteDataSource.getCurrentUserProviderStatus();
  }

  @override
  Future<void> registerCurrentUserAsProvider({
    required String providerType,
    required String legalName,
    required String displayName,
    required String phone,
    required String city,
    required String state,
    required String countryCode,
  }) {
    return _remoteDataSource.registerCurrentUserAsProvider(
      providerType: providerType,
      legalName: legalName,
      displayName: displayName,
      phone: phone,
      city: city,
      state: state,
      countryCode: countryCode,
    );
  }
}
