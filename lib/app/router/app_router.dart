import 'package:flutter/material.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/explore/domain/entities/tourism_place.dart';
import '../../features/explore/presentation/pages/explore_detail_page.dart';
import '../../features/explore/presentation/pages/explore_page.dart';
import '../../features/explore/presentation/pages/image_gallery_page.dart';
import '../../features/explore/presentation/pages/video_gallery_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/pages/splash_page.dart';
import '../../features/profile/presentation/pages/customer_profile_page.dart';
import '../../features/pooja/domain/entities/pooja_entities.dart';
import '../../features/pooja/presentation/pages/customer_pooja_booking_detail_page.dart';
import '../../features/pooja/presentation/pages/customer_pooja_booking_page.dart';
import '../../features/pooja/presentation/pages/customer_pooja_bookings_page.dart';
import '../../features/pooja/presentation/pages/customer_pooja_detail_page.dart';
import '../../features/pooja/presentation/pages/customer_pooja_list_page.dart';
import '../../features/pooja/presentation/pages/customer_pooja_payment_page.dart';
import '../../features/pooja/presentation/pages/pandit_availability_page.dart';
import '../../features/pooja/presentation/pages/pandit_pooja_bookings_page.dart';
import '../../features/pooja/presentation/pages/pandit_pooja_form_page.dart';
import '../../features/pooja/presentation/pages/pandit_pooja_services_page.dart';
import '../../features/profile/presentation/pages/profile_edit_page.dart';
import '../../features/profile/presentation/pages/provider_earnings_page.dart';
import '../../features/profile/presentation/pages/provider_profile_page.dart';
import '../../features/provider/presentation/pages/provider_gate_page.dart';
import '../../features/provider/presentation/pages/provider_registration_page.dart';
import '../../features/reviews/presentation/pages/provider_reviews_page.dart';
import '../../features/provider/presentation/pages/provider_kyc_page.dart';
import '../../features/provider/presentation/pages/dashboards/accommodation_dashboard_page.dart';
import '../../features/provider/presentation/pages/dashboards/pandit_dashboard_page.dart';
import '../../features/provider/presentation/pages/dashboards/transport_dashboard_page.dart';
import 'route_names.dart';

class AppRouter {
  const AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      // ---------------------------------------------------------------------
      // Splash
      // ---------------------------------------------------------------------
      case RouteNames.splash:
        return MaterialPageRoute<void>(
          builder: (_) => const SplashPage(),
          settings: settings,
        );

      // ---------------------------------------------------------------------
      // Authentication
      // ---------------------------------------------------------------------
      case RouteNames.login:
        return MaterialPageRoute<void>(
          builder: (_) => const LoginPage(),
          settings: settings,
        );

      case RouteNames.register:
        return MaterialPageRoute<void>(
          builder: (_) => const RegisterPage(),
          settings: settings,
        );

      // ---------------------------------------------------------------------
      // Provider onboarding gate
      // ---------------------------------------------------------------------
      case RouteNames.providerGate:
        return MaterialPageRoute<void>(
          builder: (_) => const ProviderGatePage(),
          settings: settings,
        );

      case RouteNames.providerRegistration:
        return MaterialPageRoute<void>(
          builder: (_) => const ProviderRegistrationPage(),
          settings: settings,
        );

      case RouteNames.providerKyc:
        return MaterialPageRoute<void>(
          builder: (_) => const ProviderKycPage(),
          settings: settings,
        );


      // ---------------------------------------------------------------------
      // Provider dashboards
      // ---------------------------------------------------------------------
      case RouteNames.panditDashboard:
        return MaterialPageRoute<void>(
          builder: (_) => const PanditDashboardPage(),
          settings: settings,
        );

      case RouteNames.accommodationDashboard:
        return MaterialPageRoute<void>(
          builder: (_) => const AccommodationDashboardPage(),
          settings: settings,
        );

      case RouteNames.transportDashboard:
        return MaterialPageRoute<void>(
          builder: (_) => const TransportDashboardPage(),
          settings: settings,
        );


      case RouteNames.providerProfile:
        return MaterialPageRoute<void>(
          builder: (_) => const ProviderProfilePage(),
          settings: settings,
        );

      case RouteNames.providerProfileEdit:
        return MaterialPageRoute<void>(
          builder: (_) => const ProviderProfileEditPage(),
          settings: settings,
        );

      case RouteNames.providerEarnings:
        return MaterialPageRoute<void>(
          builder: (_) => const ProviderEarningsPage(),
          settings: settings,
        );


      case RouteNames.providerReviews:
        return MaterialPageRoute<void>(
          builder: (_) => const ProviderReviewsPage(),
          settings: settings,
        );

      // ---------------------------------------------------------------------
      // Home
      // ---------------------------------------------------------------------
      case RouteNames.home:
        return PageRouteBuilder<void>(
          settings: settings,
          transitionDuration: const Duration(milliseconds: 280),
          pageBuilder: (_, animation, __) => const HomePage(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        );


      case RouteNames.customerProfile:
        return MaterialPageRoute<void>(
          builder: (_) => const CustomerProfilePage(),
          settings: settings,
        );

      case RouteNames.customerProfileEdit:
        return MaterialPageRoute<void>(
          builder: (_) => const CustomerProfileEditPage(),
          settings: settings,
        );


      // ---------------------------------------------------------------------
      // Customer Pooja
      // ---------------------------------------------------------------------
      case RouteNames.poojas:
        return MaterialPageRoute<void>(
          builder: (_) => const CustomerPoojaListPage(),
          settings: settings,
        );

      case RouteNames.poojaDetail:
        final identifier = settings.arguments;
        if (identifier is! String || identifier.trim().isEmpty) {
          return _errorRoute(settings, 'Invalid Pooja identifier.');
        }
        return MaterialPageRoute<void>(
          builder: (_) => CustomerPoojaDetailPage(identifier: identifier),
          settings: settings,
        );

      case RouteNames.poojaBooking:
        final args = settings.arguments;
        if (args is! Map ||
            args['pooja'] is! Pooja ||
            args['offering'] is! PoojaOffering) {
          return _errorRoute(settings, 'Invalid Pooja booking arguments.');
        }
        return MaterialPageRoute<void>(
          builder: (_) => CustomerPoojaBookingPage(
            pooja: args['pooja'] as Pooja,
            offering: args['offering'] as PoojaOffering,
          ),
          settings: settings,
        );

      case RouteNames.poojaPayment:
        final booking = settings.arguments;
        if (booking is! PoojaBooking) {
          return _errorRoute(settings, 'Invalid Pooja payment arguments.');
        }
        return MaterialPageRoute<void>(
          builder: (_) => CustomerPoojaPaymentPage(booking: booking),
          settings: settings,
        );

      case RouteNames.customerPoojaBookings:
        return MaterialPageRoute<void>(
          builder: (_) => const CustomerPoojaBookingsPage(),
          settings: settings,
        );


      case RouteNames.customerPoojaBookingDetail:
        final bookingId = settings.arguments;
        if (bookingId is! String || bookingId.trim().isEmpty) {
          return _errorRoute(settings, 'Invalid Pooja booking identifier.');
        }
        return MaterialPageRoute<void>(
          builder: (_) => CustomerPoojaBookingDetailPage(bookingId: bookingId),
          settings: settings,
        );

      // ---------------------------------------------------------------------
      // Pandit Pooja management
      // ---------------------------------------------------------------------
      case RouteNames.panditPoojaServices:
        return MaterialPageRoute<void>(
          builder: (_) => const PanditPoojaServicesPage(),
          settings: settings,
        );

      case RouteNames.panditPoojaForm:
        final offering = settings.arguments;
        return MaterialPageRoute<void>(
          builder: (_) => PanditPoojaFormPage(
            offering: offering is PanditOffering ? offering : null,
          ),
          settings: settings,
        );

      case RouteNames.panditAvailability:
        return MaterialPageRoute<void>(
          builder: (_) => const PanditAvailabilityPage(),
          settings: settings,
        );

      case RouteNames.panditPoojaBookings:
        return MaterialPageRoute<void>(
          builder: (_) => const PanditPoojaBookingsPage(),
          settings: settings,
        );

      // ---------------------------------------------------------------------
      // Explore
      // ---------------------------------------------------------------------
      case RouteNames.explore:
        return MaterialPageRoute<void>(
          builder: (_) => const ExplorePage(),
          settings: settings,
        );

      case RouteNames.exploreDetail:
        final arguments = settings.arguments;

        if (arguments is! TourismPlace) {
          return _errorRoute(
            settings,
            'Invalid place supplied to Explore Detail.',
          );
        }

        return MaterialPageRoute<void>(
          builder: (_) => ExploreDetailPage(
            initialPlace: arguments,
          ),
          settings: settings,
        );

      case RouteNames.imageGallery:
        final arguments = settings.arguments;

        if (arguments is! TourismPlace) {
          return _errorRoute(
            settings,
            'Invalid place supplied to Image Gallery.',
          );
        }

        return MaterialPageRoute<void>(
          builder: (_) => ImageGalleryPage(
            place: arguments,
          ),
          settings: settings,
        );

      case RouteNames.videoGallery:
        final arguments = settings.arguments;

        if (arguments is! TourismPlace) {
          return _errorRoute(
            settings,
            'Invalid place supplied to Video Gallery.',
          );
        }

        return MaterialPageRoute<void>(
          builder: (_) => VideoGalleryPage(
            place: arguments,
          ),
          settings: settings,
        );

      // ---------------------------------------------------------------------
      // Unknown route
      // ---------------------------------------------------------------------
      default:
        return _errorRoute(
          settings,
          'Route not found: ${settings.name}',
        );
    }
  }

  static Route<dynamic> _errorRoute(
    RouteSettings settings,
    String message,
  ) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                message,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
