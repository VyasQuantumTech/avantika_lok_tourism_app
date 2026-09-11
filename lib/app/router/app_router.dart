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
import '../../features/provider/presentation/pages/provider_gate_page.dart';
import '../../features/provider/presentation/pages/provider_registration_page.dart';
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
