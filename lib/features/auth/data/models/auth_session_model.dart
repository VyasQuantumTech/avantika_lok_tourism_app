import 'auth_user_model.dart';

class AuthSessionModel {
  const AuthSessionModel({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  final AuthUserModel user;
  final String accessToken;
  final String refreshToken;

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']);
    final tokens = _asMap(data['tokens']);

    return AuthSessionModel(
      user: AuthUserModel.fromJson(_asMap(data['user'])),
      accessToken: tokens['accessToken']?.toString() ?? '',
      refreshToken: tokens['refreshToken']?.toString() ?? '',
    );
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return <String, dynamic>{};
  }
}
