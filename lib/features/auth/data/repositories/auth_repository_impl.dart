import '../../../../core/errors/exceptions.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(
    this._remoteDataSource,
    this._secureStorage,
  );

  final AuthRemoteDataSource _remoteDataSource;
  final SecureStorageService _secureStorage;

  @override
  Future<AuthUser> register({
    required String firstName,
    String? lastName,
    required String email,
    required String password,
  }) {
    return _remoteDataSource.register(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
    );
  }

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final session = await _remoteDataSource.login(
      email: email,
      password: password,
    );

    if (session.accessToken.trim().isEmpty ||
        session.refreshToken.trim().isEmpty) {
      await _secureStorage.clearSession();
      throw const ApiException(
        'The server returned an invalid authentication session.',
      );
    }

    // A successful login becomes persistent only after both tokens and the
    // active-session marker have been written by SecureStorageService.
    await _secureStorage.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );

    return session.user;
  }

  @override
  Future<bool> restoreSession() async {
    // Secure storage is the single source of truth for startup authentication.
    // No persisted session means Splash must send the user to Login.
    if (!await _secureStorage.hasSession()) {
      return false;
    }

    try {
      // This also exercises ApiClient's refresh-token flow when the stored
      // access token has expired. A successful refresh persists the rotated
      // access/refresh token pair again.
      await _remoteDataSource.currentUser();
      return true;
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        // The persisted credentials are no longer accepted by the backend.
        // Clear them so every subsequent app launch remains on Login.
        await _secureStorage.clearSession();
        return false;
      }

      // A temporary timeout/server/connectivity problem must not destroy a
      // locally persisted login. The next authenticated request can retry and
      // refresh once connectivity is available again.
      return true;
    } catch (_) {
      // Preserve an already-persisted session for non-authentication failures.
      return true;
    }
  }

  @override
  Future<void> logout() async {
    final refreshToken = await _secureStorage.readRefreshToken();

    // Invalidate persistence before making the network request. Tokens stay in
    // secure storage just long enough for the authenticated backend logout to
    // run, but Splash can no longer restore this session if the app is killed
    // while that request is in flight.
    await _secureStorage.markSessionInactive();

    try {
      if (refreshToken != null && refreshToken.trim().isNotEmpty) {
        await _remoteDataSource.logout(refreshToken: refreshToken);
      }
    } finally {
      // Always remove the token pair locally, irrespective of API success.
      await _secureStorage.clearSession();
    }
  }
}
