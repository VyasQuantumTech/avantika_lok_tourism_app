import '../../../../core/ network/api_client.dart';
import '../../../../core/ network/endpoints.dart';
import '../models/health_model.dart';

abstract class SystemRemoteDataSource {
  Future<HealthModel> getHealth();
}

class SystemRemoteDataSourceImpl implements SystemRemoteDataSource {
  SystemRemoteDataSourceImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<HealthModel> getHealth() async {
    final json = await _apiClient.get(Endpoints.health);
    return HealthModel.fromJson(json);
  }
}
