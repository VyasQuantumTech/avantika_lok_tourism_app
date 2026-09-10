class StorageKeys {
  const StorageKeys._();

  static const String accessToken = 'auth.access_token';
  static const String refreshToken = 'auth.refresh_token';

  /// Local session marker written only after both authentication tokens have
  /// been persisted successfully. This lets app startup distinguish a real
  /// signed-in session from an incomplete/partial storage state.
  static const String sessionActive = 'auth.session_active';
}
