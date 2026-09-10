import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/storage_keys.dart';

class SecureStorageService {
  SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  Future<String?> readAccessToken() =>
      _storage.read(key: StorageKeys.accessToken);

  Future<String?> readRefreshToken() =>
      _storage.read(key: StorageKeys.refreshToken);

  Future<bool> hasSession() async {
    final values = await Future.wait<String?>([
      _storage.read(key: StorageKeys.sessionActive),
      readAccessToken(),
      readRefreshToken(),
    ]);

    final marker = values[0];
    final accessToken = values[1];
    final refreshToken = values[2];

    final hasAccessToken =
        accessToken != null && accessToken.trim().isNotEmpty;
    final hasRefreshToken =
        refreshToken != null && refreshToken.trim().isNotEmpty;
    final hasCompleteTokenPair = hasAccessToken && hasRefreshToken;

    if (!hasCompleteTokenPair) {
      // Never keep a partial authentication state. It can otherwise make
      // startup behaviour inconsistent after an interrupted write.
      await clearSession();
      return false;
    }

    if (marker == 'true') {
      return true;
    }

    // Backward-compatible migration for users authenticated by the previous
    // app build, where access/refresh tokens were already persisted but the
    // explicit session marker did not yet exist.
    if (marker == null) {
      await _storage.write(
        key: StorageKeys.sessionActive,
        value: 'true',
      );
      return true;
    }

    // An explicit inactive marker must never be treated as authenticated.
    await clearSession();
    return false;
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final normalizedAccessToken = accessToken.trim();
    final normalizedRefreshToken = refreshToken.trim();

    if (normalizedAccessToken.isEmpty || normalizedRefreshToken.isEmpty) {
      await clearSession();
      throw ArgumentError('Authentication tokens cannot be empty.');
    }

    // Persist the token pair first. The active marker is deliberately written
    // last, so a partially interrupted write can never look like a valid login.
    await _storage.write(
      key: StorageKeys.accessToken,
      value: normalizedAccessToken,
    );
    await _storage.write(
      key: StorageKeys.refreshToken,
      value: normalizedRefreshToken,
    );
    await _storage.write(
      key: StorageKeys.sessionActive,
      value: 'true',
    );
  }

  Future<void> markSessionInactive() async {
    // Invalidate the durable login state immediately when logout starts,
    // while temporarily keeping the tokens available for the backend logout
    // request. If the app is killed during that request, Splash will still
    // treat this installation as signed out on the next launch.
    await _storage.write(
      key: StorageKeys.sessionActive,
      value: 'false',
    );
  }

  Future<void> clearSession() async {
    // Mark the session inactive before deleting tokens. This makes logout
    // deterministic even if the app is killed while secure-storage cleanup is
    // still in progress.
    await _storage.write(
      key: StorageKeys.sessionActive,
      value: 'false',
    );

    await Future.wait<void>([
      _storage.delete(key: StorageKeys.accessToken),
      _storage.delete(key: StorageKeys.refreshToken),
    ]);
  }
}
