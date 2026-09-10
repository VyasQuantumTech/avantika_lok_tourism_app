import 'package:flutter/material.dart';

import '../../../../app/router/route_names.dart';

class ExploreBottomNavigation extends StatelessWidget {
  const ExploreBottomNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 2,
      onTap: (index) {
        if (index == 0) {
          Navigator.of(context).popUntil((route) => route.settings.name == RouteNames.home);
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: 'Booking'),
        BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'Discover'),
        BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'Favourite'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }
}
