import '../../../../core/ network/api_client.dart';
import '../../../../core/ network/endpoints.dart';
import '../models/profile_models.dart';
import '../../domain/entities/profile_dashboard.dart';
import '../../domain/entities/profile_snapshot.dart';

abstract class ProfileRemoteDataSource {
  Future<ProfileSnapshot> getMyProfile();
  Future<ProfileDashboard> getMyDashboard();
  Future<ProfileSnapshot> updateMyProfile(Map<String, dynamic> fields);
  Future<void> updateMyProviderProfile(Map<String, dynamic> fields);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  const ProfileRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<ProfileSnapshot> getMyProfile() async {
    final response = await _client.get(
      Endpoints.profileMe,
      authenticated: true,
    );
    return parseProfileSnapshot(_dataMap(response)['profile']);
  }

  @override
  Future<ProfileDashboard> getMyDashboard() async {
    final response = await _client.get(
      Endpoints.profileDashboard,
      authenticated: true,
    );
    return parseProfileDashboard(_dataMap(response)['dashboard']);
  }

  @override
  Future<ProfileSnapshot> updateMyProfile(Map<String, dynamic> fields) async {
    final response = await _client.patch(
      Endpoints.profileMe,
      body: fields,
      authenticated: true,
    );
    return parseProfileSnapshot(_dataMap(response)['profile']);
  }

  @override
  Future<void> updateMyProviderProfile(Map<String, dynamic> fields) async {
    await _client.put(
      Endpoints.providerMe,
      body: fields,
      authenticated: true,
    );
  }

  Map<String, dynamic> _dataMap(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }
}
