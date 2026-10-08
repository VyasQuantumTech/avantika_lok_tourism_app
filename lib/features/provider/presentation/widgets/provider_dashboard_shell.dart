import '../../../notifications/presentation/widgets/notification_bell.dart';
import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/widgets/provider_ui.dart';
import '../../../auth/domain/usecases/logout_user.dart';
import '../../../profile/domain/entities/profile_dashboard.dart';
import '../../../profile/domain/usecases/get_my_profile_dashboard.dart';
import '../../../marketplace/domain/entities/marketplace_entities.dart';
import '../../../marketplace/presentation/marketplace_pages.dart';
import '../../../pooja/presentation/pages/pandit_pooja_bookings_page.dart';
import '../../../pooja/presentation/pages/pandit_pooja_services_page.dart';
import '../../../profile/presentation/pages/provider_earnings_page.dart';
import '../../../profile/presentation/pages/provider_profile_page.dart';

class ProviderQuickAction {
  const ProviderQuickAction({
    required this.icon,
    required this.label,
    this.routeName,
  });

  final IconData icon;
  final String label;
  final String? routeName;
}

class ProviderDashboardConfig {
  const ProviderDashboardConfig({
    required this.expectedProviderType,
    required this.partnerTitle,
    required this.quickActions,
    required this.domainTitle,
    required this.bottomItems,
  });

  final String expectedProviderType;
  final String partnerTitle;
  final List<ProviderQuickAction> quickActions;
  final String domainTitle;
  final List<NavigationDestination> bottomItems;
}

class ProviderDashboardShell extends StatefulWidget {
  const ProviderDashboardShell({required this.config, super.key});

  final ProviderDashboardConfig config;

  @override
  State<ProviderDashboardShell> createState() => _ProviderDashboardShellState();
}

class _ProviderDashboardShellState extends State<ProviderDashboardShell> {
  late Future<ProfileDashboard> _future;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _future = getIt<GetMyProfileDashboard>()();

  void _reload() => setState(_load);

  void _unavailable(String label) {
    AppFeedback.info(
      context,
      '$label is not exposed by the current provider API yet.',
    );
  }

  Future<void> _logout() async {
    try {
      await getIt<LogoutUser>()();
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(RouteNames.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProfileDashboard>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: AppLoadingView(message: 'Loading dashboard…'));
        }
        if (snapshot.hasError || snapshot.data?.provider == null) {
          final message = snapshot.error is ApiException
              ? (snapshot.error! as ApiException).message
              : 'Unable to load provider dashboard.';
          return Scaffold(body: AppErrorState(message: message, onRetry: _reload));
        }

        final dashboard = snapshot.data!;
        final provider = dashboard.provider!;
        if (provider.providerType != widget.config.expectedProviderType) {
          return Scaffold(
            body: AppEmptyState(
              icon: Icons.sync_problem_outlined,
              title: 'Provider profile mismatch',
              message:
                  'This dashboard is for ${widget.config.expectedProviderType}, while the authenticated provider profile is ${provider.providerType}.',
            ),
          );
        }
        return _dashboard(dashboard, provider);
      },
    );
  }

  Widget _dashboard(ProfileDashboard dashboard, ProviderDashboardSummary provider) {
    final config = widget.config;
    final identity = dashboard.identity.providerProfile;
    final providerName = identity?.publicName.trim();
    final displayName = providerName != null && providerName.isNotEmpty
        ? providerName
        : config.partnerTitle.replaceAll('\n', ' ');

    final tabs = <Widget>[
      _dashboardTab(displayName, provider),
      _providerBookingsTab(config.expectedProviderType),
      _providerManagementTab(config.expectedProviderType),
      const ProviderEarningsPage(),
      const ProviderProfilePage(),
    ];

    return Scaffold(
      drawer: _ProviderDrawer(
        partnerTitle: config.partnerTitle,
        name: displayName,
        onLogout: _logout,
        onProfile: () => setState(() => _selectedIndex = 4),
      ),
      body: IndexedStack(index: _selectedIndex, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        height: 68,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: config.bottomItems,
      ),
    );
  }

  Widget _dashboardTab(String displayName, ProviderDashboardSummary provider) {
    final config = widget.config;
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _DashboardHeader(partnerTitle: config.partnerTitle),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _reload();
                await _future;
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  AppDimensions.pagePadding,
                  10,
                  AppDimensions.pagePadding,
                  AppDimensions.sectionGap,
                ),
                children: [
                  _WelcomeCard(name: displayName, kycStatus: provider.kycStatus),
                  const SizedBox(height: 12),
                  _EarningsHero(
                    amount: provider.financial.netCollected,
                    currency: provider.financial.currency,
                    onTap: () => setState(() => _selectedIndex = 3),
                  ),
                  SizedBox(height: AppDimensions.sectionGap),
                  const AppSectionTitle(
                    title: 'Quick actions',
                    subtitle: 'Most-used provider operations',
                  ),
                  const SizedBox(height: 10),
                  _QuickActions(actions: config.quickActions, onTap: _handleQuickAction),
                  SizedBox(height: AppDimensions.sectionGap),
                  const AppSectionTitle(
                    title: 'Business overview',
                    subtitle: 'Live figures from your provider dashboard',
                  ),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = (constraints.maxWidth - 20) / 3;
                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          SizedBox(
                            width: width,
                            child: AppMetricCard(
                              label: 'Net collected',
                              value: '₹${provider.financial.netCollected.toStringAsFixed(0)}',
                              footer: provider.financial.currency,
                              icon: Icons.account_balance_wallet_outlined,
                              onTap: () => setState(() => _selectedIndex = 3),
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: AppMetricCard(
                              label: 'Pending action',
                              value: '${provider.pendingActionBookings}',
                              footer: '${provider.upcomingBookings} upcoming',
                              icon: Icons.pending_actions_outlined,
                              onTap: () => setState(() => _selectedIndex = 1),
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: AppMetricCard(
                              label: 'Rating',
                              value: provider.ratings.averageRating?.toStringAsFixed(1) ?? '—',
                              footer: '${provider.ratings.count} reviews',
                              icon: Icons.star_rounded,
                              onTap: () => Navigator.of(context).pushNamed(RouteNames.providerReviews),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: AppDimensions.sectionGap),
                  const AppSectionTitle(title: 'Booking summary'),
                  const SizedBox(height: 10),
                  _SummaryPanel(
                    rows: [
                      ('Total bookings', '${provider.totalBookings}', Icons.receipt_long_outlined),
                      ('Upcoming', '${provider.upcomingBookings}', Icons.upcoming_outlined),
                      ('Completed', '${provider.completedBookings}', Icons.task_alt_outlined),
                      ('Pending action', '${provider.pendingActionBookings}', Icons.notification_important_outlined),
                    ],
                  ),
                  SizedBox(height: AppDimensions.sectionGap),
                  AppSectionTitle(title: config.domainTitle),
                  const SizedBox(height: 10),
                  _DomainPanel(provider: provider),
                  SizedBox(height: AppDimensions.sectionGap),
                  const AppSectionTitle(title: 'Financial snapshot'),
                  const SizedBox(height: 10),
                  _SummaryPanel(
                    rows: [
                      ('Gross captured', '₹${provider.financial.grossCaptured.toStringAsFixed(0)}', Icons.south_west_rounded),
                      ('Processed refunds', '₹${provider.financial.processedRefunds.toStringAsFixed(0)}', Icons.replay_outlined),
                      ('Net collected', '₹${provider.financial.netCollected.toStringAsFixed(0)}', Icons.account_balance_wallet_outlined),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _providerBookingsTab(String providerType) {
    switch (providerType) {
      case 'pandit':
        return const PanditPoojaBookingsPage();
      case 'hotel_manager':
        return const ProviderMarketplaceBookingsPage(type: MarketplaceType.accommodation);
      case 'vehicle_owner':
        return const ProviderMarketplaceBookingsPage(type: MarketplaceType.transport);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _providerManagementTab(String providerType) {
    switch (providerType) {
      case 'pandit':
        return const PanditPoojaServicesPage();
      case 'hotel_manager':
        return const ProviderMarketplaceManagementPage(type: MarketplaceType.accommodation);
      case 'vehicle_owner':
        return const ProviderMarketplaceManagementPage(type: MarketplaceType.transport);
      default:
        return const SizedBox.shrink();
    }
  }

  void _handleQuickAction(ProviderQuickAction action) {
    final route = action.routeName;
    if (route == RouteNames.panditPoojaBookings ||
        route == RouteNames.providerAccommodationBookings ||
        route == RouteNames.providerTransportBookings) {
      setState(() => _selectedIndex = 1);
      return;
    }
    if (route == RouteNames.panditPoojaServices ||
        route == RouteNames.providerAccommodationManagement ||
        route == RouteNames.providerTransportManagement) {
      setState(() => _selectedIndex = 2);
      return;
    }
    if (action.label == 'View Earnings' || route == RouteNames.providerEarnings) {
      setState(() => _selectedIndex = 3);
      return;
    }
    if (route != null) {
      Navigator.of(context).pushNamed(route);
      return;
    }
    _unavailable(action.label);
  }

}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.partnerTitle});

  final String partnerTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(6, 6, 8, 10),
      child: Row(
        children: [
          Builder(
            builder: (context) => IconButton(
              tooltip: 'Menu',
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu_rounded),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/common/provider_logo.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    partnerTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label.copyWith(
                      color: AppColors.primaryDark,
                      height: 1.08,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const NotificationBell(),
        ],
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.name, required this.kycStatus});

  final String name;
  final String kycStatus;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      backgroundColor: AppColors.primarySoft,
      borderColor: AppColors.brandBorder,
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.person_rounded, color: AppColors.onPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.sectionTitle),
                const SizedBox(height: 5),
                AppStatusChip(label: 'KYC ${_pretty(kycStatus)}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _EarningsHero extends StatelessWidget {
  const _EarningsHero({required this.amount, required this.currency, required this.onTap});
  final double amount;
  final String currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ProviderHeroCard(
        eyebrow: 'Total earnings',
        value: '₹ ${amount.toStringAsFixed(0)}',
        subtitle: currency,
        icon: Icons.bar_chart_rounded,
        onTap: onTap,
      );
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.actions, required this.onTap});

  final List<ProviderQuickAction> actions;
  final ValueChanged<ProviderQuickAction> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(actions.length, (index) {
        final action = actions[index];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == actions.length - 1 ? 0 : 10),
            child: ProviderQuickActionTile(
              icon: action.icon,
              label: action.label,
              onTap: () => onTap(action),
            ),
          ),
        );
      }),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({required this.rows});

  final List<(String, String, IconData)> rows;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      padding: EdgeInsets.zero,
      child: Column(
        children: List.generate(rows.length, (index) {
          final row = rows[index];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.softSurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(row.$3, size: 18, color: AppColors.primary),
                    ),
                    const SizedBox(width: 11),
                    Expanded(child: Text(row.$1, style: AppTypography.body)),
                    Text(row.$2, style: AppTypography.label.copyWith(color: AppColors.primaryDark)),
                  ],
                ),
              ),
              if (index != rows.length - 1)
                Divider(height: 1, indent: 60, color: AppColors.divider),
            ],
          );
        }),
      ),
    );
  }
}

class _DomainPanel extends StatelessWidget {
  const _DomainPanel({required this.provider});

  final ProviderDashboardSummary provider;

  @override
  Widget build(BuildContext context) {
    final d = provider.domain;
    switch (provider.providerType) {
      case 'pandit':
        return _SummaryPanel(rows: [
          ('Active pooja offerings', '${d.offerings}', Icons.temple_hindu_outlined),
          ('Weekly availability rules', '${d.weeklyAvailabilityRules}', Icons.calendar_month_outlined),
          ('Pandit profile', d.configured ? (d.active == false ? 'Inactive' : 'Configured') : 'Not configured', Icons.verified_outlined),
        ]);
      case 'hotel_manager':
        return _SummaryPanel(rows: [
          ('Accommodation properties', '${d.accommodationTotal}', Icons.apartment_outlined),
          ('Active properties', '${d.accommodationActive}', Icons.check_circle_outline),
          ('Room / unit records', '${d.units}', Icons.bed_outlined),
        ]);
      case 'vehicle_owner':
        return _SummaryPanel(rows: [
          ('Vehicles', '${d.vehicleTotal}', Icons.directions_car_outlined),
          ('Active vehicles', '${d.vehicleActive}', Icons.check_circle_outline),
          ('Routes', '${d.routes}', Icons.route_outlined),
          ('Future availability rows', '${d.futureAvailabilityRows}', Icons.calendar_month_outlined),
        ]);
      default:
        return _SummaryPanel(rows: [
          ('Packages', '${d.packageTotal}', Icons.inventory_2_outlined),
          ('Active packages', '${d.packageActive}', Icons.check_circle_outline),
        ]);
    }
  }
}

class _ProviderDrawer extends StatelessWidget {
  const _ProviderDrawer({
    required this.partnerTitle,
    required this.name,
    required this.onLogout,
    required this.onProfile,
  });

  final String partnerTitle;
  final String name;
  final VoidCallback onLogout;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Image.asset('assets/images/common/provider_logo.png', width: 72),
                  const SizedBox(height: 10),
                  Text(name, textAlign: TextAlign.center, style: AppTypography.sectionTitle),
                  const SizedBox(height: 4),
                  Text(partnerTitle.replaceAll('\n', ' '), textAlign: TextAlign.center, style: AppTypography.caption),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Dashboard'),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Provider account'),
              onTap: onProfile,
            ),
            ListTile(
              leading: const Icon(Icons.star_outline_rounded),
              title: const Text('Ratings & reviews'),
              onTap: () => Navigator.of(context).pushNamed(RouteNames.providerReviews),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: const Text('Earnings'),
              onTap: () => Navigator.of(context).pushNamed(RouteNames.providerEarnings),
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Notifications'),
              onTap: () {
                final navigator = Navigator.of(context);
                navigator.pop();
                navigator.pushNamed(RouteNames.notifications);
              },
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Log out'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _pretty(String value) => value
    .split('_')
    .map((e) => e.isEmpty ? e : '${e[0].toUpperCase()}${e.substring(1)}')
    .join(' ');
