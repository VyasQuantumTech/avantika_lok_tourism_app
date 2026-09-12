import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../auth/domain/usecases/logout_user.dart';
import '../../../profile/domain/entities/profile_dashboard.dart';
import '../../../profile/domain/usecases/get_my_profile_dashboard.dart';

class ProviderQuickAction {
  const ProviderQuickAction({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class ProviderListing {
  const ProviderListing({required this.imageAsset, required this.title, required this.price});
  final String imageAsset;
  final String title;
  final String price;
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
    _future = getIt<GetMyProfileDashboard>()();
  }

  void _reload() => setState(() => _future = getIt<GetMyProfileDashboard>()());

  void _showComingSoon(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label requires its dedicated provider management API/UI.')),
    );
  }

  Future<void> _logout() async {
    try { await getIt<LogoutUser>()(); } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(RouteNames.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProfileDashboard>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: const Color(0xFFF7FAFC),
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        if (snapshot.hasError || snapshot.data?.provider == null) {
          final message = snapshot.error is ApiException
              ? (snapshot.error! as ApiException).message
              : 'Unable to load provider dashboard.';
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off_outlined, color: AppColors.primary, size: 46),
                    const SizedBox(height: 12),
                    Text(message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _reload, child: const Text('Retry')),
                  ],
                ),
              ),
            ),
          );
        }

        final dashboard = snapshot.data!;
        final provider = dashboard.provider!;
        if (provider.providerType != widget.config.expectedProviderType) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Text(
                  'Provider type mismatch. This dashboard is for ${widget.config.expectedProviderType}, but the authenticated profile is ${provider.providerType}.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        return _buildDashboard(dashboard, provider);
      },
    );
  }

  Widget _buildDashboard(ProfileDashboard dashboard, ProviderDashboardSummary provider) {
    final config = widget.config;
    final identity = dashboard.identity.providerProfile;
    final displayName = identity?.publicName ?? config.partnerTitle;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      drawer: _ProviderDrawer(
        partnerTitle: config.partnerTitle,
        name: displayName,
        onLogout: _logout,
        onProfile: () => Navigator.of(context).pushNamed(RouteNames.providerProfile),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _DashboardHeader(partnerTitle: config.partnerTitle),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async { _reload(); await _future; },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
                  children: [
                    _WelcomeCard(name: displayName, kycStatus: provider.kycStatus),
                    const SizedBox(height: 14),
                    const _SectionHeader(title: 'Quick Actions'),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(
                        config.quickActions.length,
                        (index) => Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: index == config.quickActions.length - 1 ? 0 : 8),
                            child: _QuickActionCard(
                              action: config.quickActions[index],
                              onTap: () {
                                if (config.quickActions[index].label == 'View Earnings') {
                                  Navigator.of(context).pushNamed(RouteNames.providerEarnings);
                                } else {
                                  _showComingSoon(config.quickActions[index].label);
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const _SectionHeader(title: 'Business Overview'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _MetricCard(label: 'Net Collected', value: '₹${provider.financial.netCollected.toStringAsFixed(0)}', footer: '${provider.financial.currency} transactions', icon: Icons.currency_rupee)),
                        const SizedBox(width: 8),
                        Expanded(child: _MetricCard(label: 'Pending Action', value: '${provider.pendingActionBookings}', footer: '${provider.upcomingBookings} upcoming', icon: Icons.pending_actions_outlined)),
                        const SizedBox(width: 8),
                        Expanded(child: _MetricCard(label: 'Rating', value: provider.ratings.averageRating?.toStringAsFixed(1) ?? '—', footer: '${provider.ratings.count} reviews', icon: Icons.star_outline)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const _SectionHeader(title: 'Booking Summary'),
                    const SizedBox(height: 8),
                    _SummaryCard(
                      rows: [
                        ('Total bookings', '${provider.totalBookings}', Icons.receipt_long_outlined),
                        ('Upcoming', '${provider.upcomingBookings}', Icons.upcoming_outlined),
                        ('Completed', '${provider.completedBookings}', Icons.task_alt_outlined),
                        ('Pending action', '${provider.pendingActionBookings}', Icons.notification_important_outlined),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _SectionHeader(title: config.domainTitle),
                    const SizedBox(height: 8),
                    _DomainCard(provider: provider),
                    const SizedBox(height: 14),
                    const _SectionHeader(title: 'Financial Snapshot'),
                    const SizedBox(height: 8),
                    _SummaryCard(
                      rows: [
                        ('Gross captured', '₹${provider.financial.grossCaptured.toStringAsFixed(0)}', Icons.south_west),
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
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        height: 66,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.brandSoft,
        onDestinationSelected: (index) {
          if (index == config.bottomItems.length - 1) {
            Navigator.of(context).pushNamed(RouteNames.providerProfile);
            return;
          }
          if (index == 3) {
            Navigator.of(context).pushNamed(RouteNames.providerEarnings);
            return;
          }
          setState(() => _selectedIndex = index);
          if (index != 0) _showComingSoon(config.bottomItems[index].label);
        },
        destinations: config.bottomItems,
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.partnerTitle});
  final String partnerTitle;
  @override
  Widget build(BuildContext context) => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(6, 4, 8, 8),
    child: Row(
      children: [
        Builder(builder: (context) => IconButton(onPressed: () => Scaffold.of(context).openDrawer(), icon: const Icon(Icons.menu_rounded))),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/common/provider_logo.png', width: 42, height: 42, fit: BoxFit.contain),
              const SizedBox(width: 7),
              Flexible(child: Text(partnerTitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.body.copyWith(fontSize: 15, height: 1.05, fontWeight: FontWeight.w700, color: AppColors.primaryDark))),
            ],
          ),
        ),
        IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded)),
      ],
    ),
  );
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.name, required this.kycStatus});
  final String name;
  final String kycStatus;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [AppColors.brandGradientStart.withValues(alpha: .13), AppColors.brandGradientEnd.withValues(alpha: .11)]),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.brandBorder),
    ),
    child: Row(
      children: [
        CircleAvatar(backgroundColor: AppColors.primary, child: const Icon(Icons.person, color: Colors.white)),
        const SizedBox(width: 11),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.body.copyWith(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text('KYC: ${_pretty(kycStatus)}', style: AppTypography.caption),
        ])),
        const Icon(Icons.circle, size: 10, color: Color(0xFF27AE60)),
        const SizedBox(width: 4),
        const Text('Online', style: TextStyle(fontSize: 10, color: Color(0xFF27AE60), fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Text(title, style: AppTypography.sectionTitle.copyWith(fontSize: 14, color: AppColors.primaryDark));
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.action, required this.onTap});
  final ProviderQuickAction action;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      height: 86,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(action.icon, color: AppColors.primary, size: 25),
        const SizedBox(height: 7),
        Text(action.label, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: AppTypography.caption.copyWith(fontSize: 9.5, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.footer, required this.icon});
  final String label;
  final String value;
  final String footer;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 18, color: AppColors.accent),
      const SizedBox(height: 6),
      Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.body.copyWith(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
      const SizedBox(height: 2),
      Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.caption.copyWith(fontSize: 8.5)),
      const SizedBox(height: 3),
      Text(footer, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.caption.copyWith(fontSize: 8, color: AppColors.primary)),
    ]),
  );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.rows});
  final List<(String, String, IconData)> rows;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
    child: Column(
      children: List.generate(rows.length, (index) {
        final row = rows[index];
        return Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            child: Row(children: [
              Icon(row.$3, size: 19, color: AppColors.accent),
              const SizedBox(width: 10),
              Expanded(child: Text(row.$1, style: AppTypography.body)),
              Text(row.$2, style: AppTypography.body.copyWith(fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
            ]),
          ),
          if (index != rows.length - 1) const Divider(height: 1),
        ]);
      }),
    ),
  );
}

class _DomainCard extends StatelessWidget {
  const _DomainCard({required this.provider});
  final ProviderDashboardSummary provider;
  @override
  Widget build(BuildContext context) {
    final d = provider.domain;
    switch (provider.providerType) {
      case 'pandit':
        return _SummaryCard(rows: [
          ('Active pooja offerings', '${d.offerings}', Icons.temple_hindu_outlined),
          ('Weekly availability rules', '${d.weeklyAvailabilityRules}', Icons.calendar_month_outlined),
          ('Pandit profile', d.configured ? (d.active == false ? 'Inactive' : 'Configured') : 'Not configured', Icons.verified_outlined),
        ]);
      case 'hotel_manager':
        return _SummaryCard(rows: [
          ('Accommodation properties', '${d.accommodationTotal}', Icons.apartment_outlined),
          ('Active properties', '${d.accommodationActive}', Icons.check_circle_outline),
          ('Room / unit records', '${d.units}', Icons.bed_outlined),
        ]);
      case 'vehicle_owner':
        return _SummaryCard(rows: [
          ('Vehicles', '${d.vehicleTotal}', Icons.directions_car_outlined),
          ('Active vehicles', '${d.vehicleActive}', Icons.check_circle_outline),
          ('Routes', '${d.routes}', Icons.route_outlined),
          ('Future availability rows', '${d.futureAvailabilityRows}', Icons.calendar_month_outlined),
        ]);
      default:
        return _SummaryCard(rows: [
          ('Packages', '${d.packageTotal}', Icons.inventory_2_outlined),
          ('Active packages', '${d.packageActive}', Icons.check_circle_outline),
        ]);
    }
  }
}

class _ProviderDrawer extends StatelessWidget {
  const _ProviderDrawer({required this.partnerTitle, required this.name, required this.onLogout, required this.onProfile});
  final String partnerTitle;
  final String name;
  final VoidCallback onLogout;
  final VoidCallback onProfile;
  @override
  Widget build(BuildContext context) => Drawer(
    child: SafeArea(
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            Image.asset('assets/images/common/provider_logo.png', width: 76),
            const SizedBox(height: 8),
            Text(name, textAlign: TextAlign.center, style: AppTypography.sectionTitle),
            const SizedBox(height: 3),
            Text(partnerTitle.replaceAll('\n', ' '), textAlign: TextAlign.center, style: AppTypography.caption),
          ]),
        ),
        ListTile(leading: const Icon(Icons.dashboard_outlined), title: const Text('Dashboard'), onTap: () => Navigator.of(context).pop()),
        ListTile(leading: const Icon(Icons.person_outline), title: const Text('Profile'), onTap: onProfile),
        ListTile(leading: const Icon(Icons.account_balance_wallet_outlined), title: const Text('Earnings'), onTap: () => Navigator.of(context).pushNamed(RouteNames.providerEarnings)),
        const Spacer(),
        ListTile(leading: const Icon(Icons.logout), title: const Text('Log out'), onTap: onLogout),
        const SizedBox(height: 10),
      ]),
    ),
  );
}

String _pretty(String value) => value.split('_').map((e) => e.isEmpty ? e : '${e[0].toUpperCase()}${e.substring(1)}').join(' ');
