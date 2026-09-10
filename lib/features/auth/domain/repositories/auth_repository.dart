import '../entities/auth_user.dart';

abstract class AuthRepository {
  Future<AuthUser> register({
    required String firstName,
    String? lastName,
    required String email,
    required String password,
  });

  Future<AuthUser> login({
    required String email,
    required String password,
  });

  Future<bool> restoreSession();

  Future<void> logout();
}
