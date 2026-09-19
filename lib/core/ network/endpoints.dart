class Endpoints {
  const Endpoints._();

  static const String health = '/health';
  static const String tourismPlaces = '/api/v1/tourism/places';

  static const String poojas = '/api/v1/tourism/poojas';
  static const String accommodations = '/api/v1/tourism/accommodations';
  static const String transport = '/api/v1/tourism/transport';
  static const String bookings = '/api/v1/bookings';
  static const String payments = '/api/v1/payments';
  static const String reviews = '/api/v1/reviews';

  static const String providerPandit = '/api/v1/provider/pandit';
  static const String providerAccommodations = '/api/v1/provider/accommodations';
  static const String providerTransport = '/api/v1/provider/transport';
  static const String providerPanditPoojas = '/api/v1/provider/pandit/poojas';
  static const String providerPanditAvailability =
      '/api/v1/provider/pandit/availability';
  static const String providerBookings = '/api/v1/provider/bookings';
  static const String providerReviews = '/api/v1/provider/reviews';

  static const String register = '/api/v1/auth/register';
  static const String login = '/api/v1/auth/login';
  static const String refresh = '/api/v1/auth/refresh';
  static const String logout = '/api/v1/auth/logout';
  static const String me = '/api/v1/auth/me';

  static const String providerStatus = '/api/v1/provider/me/status';
  static const String providerMe = '/api/v1/provider/me';
  static const String providerKyc = '/api/v1/provider/me/kyc';
  static const String providerKycRequirements = '/api/v1/provider/me/kyc/requirements';
  static const String providerKycDocuments = '/api/v1/provider/me/kyc/documents';
  static const String providerKycSubmit = '/api/v1/provider/me/kyc/submit';
  static const String media = '/api/v1/media';

  static const String profileMe = '/api/v1/profile/me';
  static const String profileDashboard = '/api/v1/profile/me/dashboard';
}
