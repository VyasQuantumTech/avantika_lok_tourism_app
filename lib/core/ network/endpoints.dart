class Endpoints {
  const Endpoints._();

  static const String health = '/health';
  static const String tourismPlaces = '/api/v1/tourism/places';

  static const String register = '/api/v1/auth/register';
  static const String login = '/api/v1/auth/login';
  static const String refresh = '/api/v1/auth/refresh';
  static const String logout = '/api/v1/auth/logout';
  static const String me = '/api/v1/auth/me';

  static const String providerStatus = '/api/v1/provider/me/status';
  static const String providerMe = '/api/v1/provider/me';

  static const String profileMe = '/api/v1/profile/me';
  static const String profileDashboard = '/api/v1/profile/me/dashboard';
}
