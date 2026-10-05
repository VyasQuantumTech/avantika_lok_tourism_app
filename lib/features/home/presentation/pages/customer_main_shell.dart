import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../explore/presentation/pages/explore_page.dart';
import '../../../marketplace/presentation/marketplace_pages.dart';
import '../../../profile/presentation/pages/customer_profile_page.dart';
import 'home_page.dart';

/// Persistent customer navigation shell.
///
/// The five primary destinations live in one IndexedStack, so switching tabs
/// never pushes another primary page over the bottom navigation. This keeps the
/// navigation visible and preserves each tab's state/scroll position.
class CustomerMainShell extends StatefulWidget {
  const CustomerMainShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<CustomerMainShell> createState() => _CustomerMainShellState();
}

class _CustomerMainShellState extends State<CustomerMainShell> {
  late int _selectedIndex;

  late final List<Widget> _tabs = const [
    HomePage(),
    CustomerBookingsHubPage(),
    ExplorePage(),
    _CustomerFavouritesTab(),
    CustomerProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, _tabs.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _selectedIndex, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(Icons.location_on),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favourite',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _CustomerFavouritesTab extends StatelessWidget {
  const _CustomerFavouritesTab();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite_border_rounded, size: 52),
              SizedBox(height: 12),
              Text('Favourites', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              SizedBox(height: 6),
              Text(
                'Your saved places and services will appear here when favourites are available.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
