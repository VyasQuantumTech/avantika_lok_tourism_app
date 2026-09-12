import '../../domain/entities/profile_dashboard.dart';
import '../../domain/entities/profile_snapshot.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._remoteDataSource);
  final ProfileRemoteDataSource _remoteDataSource;

  @override
  Future<ProfileSnapshot> getMyProfile() => _remoteDataSource.getMyProfile();

  @override
  Future<ProfileDashboard> getMyDashboard() => _remoteDataSource.getMyDashboard();

  @override
  Future<ProfileSnapshot> updateMyProfile({
    required Map<String, dynamic> fields,
  }) {
    return _remoteDataSource.updateMyProfile(fields);
  }

  @override
  Future<void> updateMyProviderProfile({
    required String providerType,
    required String legalName,
    String? displayName,
    String? phone,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? postalCode,
    String countryCode = 'IN',
  }) {
    return _remoteDataSource.updateMyProviderProfile(<String, dynamic>{
      'providerType': providerType,
      'legalName': legalName,
      'displayName': displayName,
      'phone': phone,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'countryCode': countryCode,
    });
  }
}
