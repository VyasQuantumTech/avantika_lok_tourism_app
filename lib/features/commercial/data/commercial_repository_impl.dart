import '../../../core/ network/api_client.dart';
import '../domain/commercial_repository.dart';

class CommercialRemoteDataSource {
  const CommercialRemoteDataSource(this.api);
  final ApiClient api;
  Map<String, dynamic> data(Map<String, dynamic> value) => value['data'] is Map
      ? Map<String, dynamic>.from(value['data'] as Map)
      : value;
  Future<Map<String, dynamic>> get(String path) async =>
      data(await api.get('/api/v1$path', authenticated: true));
  Future<Map<String, dynamic>> post(
          String path, Map<String, dynamic> body) async =>
      data(await api.post('/api/v1$path', authenticated: true, body: body));
  Future<Map<String, dynamic>> put(
          String path, Map<String, dynamic> body) async =>
      data(await api.put('/api/v1$path', authenticated: true, body: body));
}

class CommercialRepositoryImpl implements CommercialRepository {
  const CommercialRepositoryImpl(this.remote);
  final CommercialRemoteDataSource remote;
  @override
  Future<Map<String, dynamic>> get(String path) => remote.get(path);
  @override
  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) =>
      remote.post(path, body);
  @override
  Future<Map<String, dynamic>> taxProfile(Map<String, dynamic> body) =>
      remote.put('/provider/tax-profile', body);
}
