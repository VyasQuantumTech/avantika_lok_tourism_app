import '../../../../core/ network/api_client.dart';
import '../../../../core/ network/endpoints.dart';
import '../models/auth_session_model.dart';
import '../models/auth_user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthUserModel> register({
    required String firstName,
    String? lastName,
    required String email,
    required String password,
  });

  Future<AuthSessionModel> login({
    required String email,
    required String password,
  });

  Future<AuthUserModel> currentUser();

  Future<void> logout({required String refreshToken});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<AuthUserModel> register({
    required String firstName,
    String? lastName,
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      Endpoints.register,
      body: <String, dynamic>{
        'firstName': firstName.trim(),
        'lastName': lastName?.trim().isEmpty == true ? null : lastName?.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
      },
    );
    final data = _asMap(response['data']);
    return AuthUserModel.fromJson(_asMap(data['user']));
  }

  @override
  Future<AuthSessionModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      Endpoints.login,
      body: <String, dynamic>{
        'email': email.trim().toLowerCase(),
        'password': password,
      },
    );
    return AuthSessionModel.fromJson(response);
  }

  @override
  Future<AuthUserModel> currentUser() async {
    final response = await _apiClient.get(
      Endpoints.me,
      authenticated: true,
    );
    final data = _asMap(response['data']);
    return AuthUserModel.fromJson(_asMap(data['user']));
  }

  @override
  Future<void> logout({required String refreshToken}) async {
    await _apiClient.post(
      Endpoints.logout,
      authenticated: true,
      body: <String, dynamic>{'refreshToken': refreshToken},
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return <String, dynamic>{};
  }
}
