import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/entities/home_dashboard.dart';
import '../../domain/usecases/get_home_dashboard.dart';
import '../widgets/accommodation_card.dart';
import '../widgets/destination_card.dart';
import '../widgets/home_drawer.dart';
import '../widgets/home_section_header.dart';
import '../widgets/service_tile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<HomeDashboard> _dashboardFuture;
  int _selectedBottomIndex = 0;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = getIt<GetHomeDashboard>()();
  }

  void _reload() {
    setState(() {
      _dashboardFuture = getIt<GetHomeDashboard>()();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HomeDashboard>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 12),
                      const Text('Unable to load local dashboard data.'),
                      const SizedBox(height: 14),
                      FilledButton(onPressed: _reload, child: const Text('Retry')),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final dashboard = snapshot.data!;
        return Scaffold(
          drawer: HomeDrawer(dashboard: dashboard),
          body: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _TopHeader(onFilterTap: () {})),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.pagePadding,
                    12,
                    AppDimensions.pagePadding,
                    104,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _ServicesSection(
                        items: dashboard.services,
                        onExploreTap: () => Navigator.of(context).pushNamed(RouteNames.explore),
                      ),
                      const SizedBox(height: AppDimensions.sectionGap),
                      _DestinationsSection(items: dashboard.destinations),
                      const SizedBox(height: AppDimensions.sectionGap),
                      _AccommodationSection(items: dashboard.accommodations),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedBottomIndex,
            onTap: (index) => setState(() => _selectedBottomIndex = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month_outlined),
                label: 'Booking',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.location_on_outlined),
                label: 'Discover',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite_border),
                label: 'Favourite',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({required this.onFilterTap});

  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.pagePadding,
        14,
        AppDimensions.pagePadding,
        0,
      ),
      child: Column(
        children: [
          SizedBox(
            height: 46,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Builder(
                    builder: (context) => IconButton(
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      icon: const Icon(Icons.menu, size: 30),
                      color: AppColors.textPrimary,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Avantika Lok',
                      style: AppTypography.brandTitle.copyWith(fontSize: 18),
                    ),
                    Text('A Holy March', style: AppTypography.brandSubtitle),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.softSurface,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search,
                        color: AppColors.iconPink,
                        size: 20,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'Ujjain, Madhya Pradesh',
                          style: AppTypography.caption.copyWith(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: onFilterTap,
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.tune,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ServicesSection extends StatelessWidget {
  const _ServicesSection({required this.items, required this.onExploreTap});

  final List<ServiceItem> items;
  final VoidCallback onExploreTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const HomeSectionHeader(title: 'Avantika Lok Services'),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.9,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return ServiceTile(
              item: item,
              onTap: item.title.trim().toLowerCase() == 'explore' ? onExploreTap : null,
            );
          },
        ),
      ],
    );
  }
}

class _DestinationsSection extends StatelessWidget {
  const _DestinationsSection({required this.items});

  final List<DestinationItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const HomeSectionHeader(title: 'Popular Destination'),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.02,
          ),
          itemBuilder: (context, index) => DestinationCard(item: items[index]),
        ),
      ],
    );
  }
}

class _AccommodationSection extends StatelessWidget {
  const _AccommodationSection({required this.items});

  final List<AccommodationItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const HomeSectionHeader(title: 'Trending Accommodation'),
        const SizedBox(height: 10),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AccommodationCard(item: item),
          ),
        ),
      ],
    );
  }
}
