class RouteNames {
  const RouteNames._();

  // Auth
  static const String login = '/login';
  static const String register = '/register';

  // Provider onboarding
  static const String providerGate = '/provider/gate';
  static const String providerRegistration = '/provider/register';
  static const String providerKyc = '/provider/kyc';

  // Provider dashboards
  static const String panditDashboard = '/provider/dashboard/pandit';
  static const String accommodationDashboard =
      '/provider/dashboard/accommodation';
  static const String transportDashboard = '/provider/dashboard/transport';
  static const String providerProfile = '/provider/profile';
  static const String providerProfileEdit = '/provider/profile/edit';
  static const String providerEarnings = '/provider/earnings';
  static const String providerReviews = '/provider/reviews';

  // App
  static const String splash = '/';
  static const String home = '/home';
  static const String customerProfile = '/profile';
  static const String customerProfileEdit = '/profile/edit';


  // Pooja - customer
  static const String poojas = '/poojas';
  static const String poojaDetail = '/poojas/detail';
  static const String poojaBooking = '/poojas/book';
  static const String poojaPayment = '/poojas/payment';
  static const String customerPoojaBookings = '/poojas/bookings';
  static const String customerPoojaBookingDetail = '/poojas/bookings/detail';

  // Pooja - pandit provider
  static const String panditPoojaServices = '/provider/pandit/poojas';
  static const String panditPoojaForm = '/provider/pandit/poojas/form';
  static const String panditAvailability = '/provider/pandit/availability';
  static const String panditPoojaBookings = '/provider/pandit/bookings';

  // Explore
  static const String explore = '/explore';
  static const String exploreDetail = '/explore/detail';
  static const String imageGallery = '/explore/gallery/images';
  static const String videoGallery = '/explore/gallery/videos';
}
