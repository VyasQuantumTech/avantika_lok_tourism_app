import 'package:flutter/material.dart';

import '../../features/explore/domain/entities/tourism_place.dart';
import '../../features/explore/presentation/pages/explore_detail_page.dart';
import '../../features/explore/presentation/pages/explore_page.dart';
import '../../features/explore/presentation/pages/image_gallery_page.dart';
import '../../features/explore/presentation/pages/video_gallery_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/pages/splash_page.dart';
import 'route_names.dart';

class AppRouter {
  const AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.splash:
        return MaterialPageRoute<void>(
          builder: (_) => const SplashPage(),
          settings: settings,
        );
      case RouteNames.home:
        return PageRouteBuilder<void>(
          settings: settings,
          transitionDuration: const Duration(milliseconds: 280),
          pageBuilder: (_, animation, __) => const HomePage(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      case RouteNames.explore:
        return MaterialPageRoute<void>(
          builder: (_) => const ExplorePage(),
          settings: settings,
        );
      case RouteNames.exploreDetail:
        final place = settings.arguments as TourismPlace;
        return MaterialPageRoute<void>(
          builder: (_) => ExploreDetailPage(initialPlace: place),
          settings: settings,
        );
      case RouteNames.imageGallery:
        final place = settings.arguments as TourismPlace;
        return MaterialPageRoute<void>(
          builder: (_) => ImageGalleryPage(place: place),
          settings: settings,
        );
      case RouteNames.videoGallery:
        final place = settings.arguments as TourismPlace;
        return MaterialPageRoute<void>(
          builder: (_) => VideoGalleryPage(place: place),
          settings: settings,
        );
      default:
        return MaterialPageRoute<void>(
          builder: (_) => const SplashPage(),
          settings: settings,
        );
    }
  }
}
