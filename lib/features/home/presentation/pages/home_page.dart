import 'feed_section_page.dart';
import '../widgets/feed_item_card.dart';
import '../../../notifications/presentation/widgets/notification_bell.dart';
import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../domain/entities/home_dashboard.dart';
import '../../domain/usecases/get_home_dashboard.dart';
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
              body: AppLoadingView(message: 'Preparing Avantika Lok…'));
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            body: SafeArea(
              child: AppErrorState(
                message: 'Unable to load the home dashboard.',
                onRetry: _reload,
              ),
            ),
          );
        }

        final dashboard = snapshot.data!;
        return Scaffold(
          drawer: HomeDrawer(dashboard: dashboard),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                _reload();
                await _dashboardFuture;
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                      child: _TopHeader(
                          onFilterTap: () => Navigator.of(context)
                              .pushNamed(RouteNames.explore))),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      AppDimensions.pagePadding,
                      12,
                      AppDimensions.pagePadding,
                      104,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _ServicesSection(
                          items: dashboard.services,
                          onExploreTap: () => Navigator.of(context)
                              .pushNamed(RouteNames.explore),
                        ),
                        SizedBox(height: AppDimensions.sectionGap),
                        for (final section in dashboard.sections) ...[
                          HomeSectionHeader(
                              title: section.title,
                              onAction: () => Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                      builder: (_) => FeedSectionPage(
                                          type: section.type,
                                          title: section.title)))),
                          if (section.items.isEmpty)
                            Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                    'No ${section.title.toLowerCase()} available yet.')),
                          ...section.items
                              .map((item) => FeedItemCard(item: item)),
                          SizedBox(height: AppDimensions.sectionGap),
                        ],
                      ]),
                    ),
                  ),
                ],
              ),
            ),
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
      padding: EdgeInsets.fromLTRB(
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
                const Align(
                    alignment: Alignment.centerRight,
                    child: NotificationBell()),
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
                      Icon(
                        Icons.search,
                        color: AppColors.iconPink,
                        size: 20,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'Explore destinations and services',
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
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.tune,
                    color: AppColors.onPrimary,
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
            final service = item.title.trim().toLowerCase();
            return ServiceTile(
              item: item,
              onTap: service == 'explore'
                  ? onExploreTap
                  : (service == 'puja' ||
                          service == 'pooja' ||
                          service == 'panditji')
                      ? () => Navigator.of(context).pushNamed(RouteNames.poojas)
                      : (service == 'hotel' ||
                              service == 'stay' ||
                              service == 'accommodation')
                          ? () => Navigator.of(context)
                              .pushNamed(RouteNames.accommodations)
                          : (service == 'transport' ||
                                  service == 'cab' ||
                                  service == 'taxi')
                              ? () => Navigator.of(context)
                                  .pushNamed(RouteNames.transport)
                              : service == 'packages'
                                  ? () => Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                          builder: (_) => const FeedSectionPage(
                                              type: 'package',
                                              title: 'Packages')))
                                  : null,
            );
          },
        ),
      ],
    );
  }
}
