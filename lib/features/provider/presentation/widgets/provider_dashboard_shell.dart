import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../auth/domain/usecases/logout_user.dart';

class ProviderQuickAction {
  const ProviderQuickAction({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}

class ProviderMetric {
  const ProviderMetric({
    required this.label,
    required this.value,
    required this.footer,
    required this.icon,
  });

  final String label;
  final String value;
  final String footer;
  final IconData icon;
}

class ProviderBooking {
  const ProviderBooking({
    required this.icon,
    required this.title,
    required this.lines,
    required this.primaryAction,
    required this.secondaryAction,
  });

  final IconData icon;
  final String title;
  final List<String> lines;
  final String primaryAction;
  final String secondaryAction;
}

class ProviderListing {
  const ProviderListing({
    required this.imageAsset,
    required this.title,
    required this.price,
  });

  final String imageAsset;
  final String title;
  final String price;
}

class ProviderDashboardConfig {
  const ProviderDashboardConfig({
    required this.partnerTitle,
    required this.quickActions,
    required this.metrics,
    required this.todayTitle,
    required this.todayBooking,
    required this.requestBooking,
    required this.listingsTitle,
    required this.listings,
    required this.bottomItems,
  });

  final String partnerTitle;
  final List<ProviderQuickAction> quickActions;
  final List<ProviderMetric> metrics;
  final String todayTitle;
  final ProviderBooking todayBooking;
  final ProviderBooking requestBooking;
  final String listingsTitle;
  final List<ProviderListing> listings;
  final List<NavigationDestination> bottomItems;
}

class ProviderDashboardShell extends StatefulWidget {
  const ProviderDashboardShell({
    required this.config,
    super.key,
  });

  final ProviderDashboardConfig config;

  @override
  State<ProviderDashboardShell> createState() => _ProviderDashboardShellState();
}

class _ProviderDashboardShellState extends State<ProviderDashboardShell> {
  int _selectedIndex = 0;

  void _showComingSoon(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label will be connected with live provider APIs next.'),
        duration: const Duration(milliseconds: 950),
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await getIt<LogoutUser>()();
    } catch (_) {
      // Logout is local-first; the auth repository clears local session state.
    }

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      RouteNames.login,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      drawer: _ProviderDrawer(
        partnerTitle: config.partnerTitle,
        onLogout: _logout,
        onTap: _showComingSoon,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _DashboardHeader(partnerTitle: config.partnerTitle),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _OnlineRow(),
                    const SizedBox(height: 10),
                    _SectionHeader(title: 'Quick Actions'),
                    const SizedBox(height: 8),
                    Row(
                      children: config.quickActions
                          .map(
                            (action) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _QuickActionCard(
                                  action: action,
                                  onTap: () => _showComingSoon(action.label),
                                ),
                              ),
                            ),
                          )
                          .toList()
                        ..last = Expanded(
                          child: _QuickActionCard(
                            action: config.quickActions.last,
                            onTap: () =>
                                _showComingSoon(config.quickActions.last.label),
                          ),
                        ),
                    ),
                    const SizedBox(height: 14),
                    _SectionHeader(
                      title: 'Business Overview',
                      trailing: 'See All',
                      onTrailingTap: () => _showComingSoon('Business Overview'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(
                        config.metrics.length,
                        (index) => Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: index == config.metrics.length - 1 ? 0 : 8,
                            ),
                            child: _MetricCard(metric: config.metrics[index]),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SectionHeader(
                      title: config.todayTitle,
                      trailing: 'See All',
                      onTrailingTap: () => _showComingSoon(config.todayTitle),
                    ),
                    const SizedBox(height: 7),
                    _BookingCard(
                      booking: config.todayBooking,
                      onPrimary: () =>
                          _showComingSoon(config.todayBooking.primaryAction),
                      onSecondary: () =>
                          _showComingSoon(config.todayBooking.secondaryAction),
                    ),
                    const SizedBox(height: 14),
                    _SectionHeader(
                      title: 'New Booking Requests',
                      trailing: 'See All',
                      onTrailingTap: () => _showComingSoon('Booking Requests'),
                    ),
                    const SizedBox(height: 7),
                    _BookingCard(
                      booking: config.requestBooking,
                      compact: true,
                      onPrimary: () =>
                          _showComingSoon(config.requestBooking.primaryAction),
                      onSecondary: () =>
                          _showComingSoon(config.requestBooking.secondaryAction),
                    ),
                    const SizedBox(height: 14),
                    _SectionHeader(
                      title: config.listingsTitle,
                      trailing: 'See All',
                      onTrailingTap: () => _showComingSoon(config.listingsTitle),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: List.generate(
                        config.listings.length,
                        (index) => Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: index == config.listings.length - 1 ? 0 : 8,
                            ),
                            child: _ListingCard(
                              listing: config.listings[index],
                              onTap: () =>
                                  _showComingSoon(config.listings[index].title),
                            ),
                          ),
                        ),
                      ),
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
          setState(() => _selectedIndex = index);
          if (index != 0) {
            _showComingSoon(config.bottomItems[index].label);
          }
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
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(6, 4, 8, 8),
      child: Row(
        children: [
          Builder(
            builder: (context) => IconButton(
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
                  width: 42,
                  height: 42,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    partnerTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body.copyWith(
                      fontSize: 15,
                      height: 1.05,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_rounded),
              ),
              Positioned(
                right: 9,
                top: 7,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE63652),
                    shape: BoxShape.circle,
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

class _OnlineRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F7E7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 8, color: Color(0xFF27A94F)),
            SizedBox(width: 5),
            Text(
              'Online',
              style: TextStyle(
                color: Color(0xFF208A42),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.trailing,
    this.onTrailingTap,
  });

  final String title;
  final String? trailing;
  final VoidCallback? onTrailingTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTypography.sectionTitle.copyWith(
              fontSize: 15,
              color: AppColors.primaryDark,
            ),
          ),
        ),
        if (trailing != null)
          InkWell(
            onTap: onTrailingTap,
            child: Text(
              trailing!,
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.action, required this.onTap});

  final ProviderQuickAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.brandSoft.withOpacity(0.72),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 74,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 9),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(action.icon, color: AppColors.primary, size: 25),
                const SizedBox(height: 6),
                Text(
                  action.label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final ProviderMetric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(metric.icon, size: 15, color: AppColors.primary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  metric.label,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 9, color: Color(0xFF737373)),
                ),
              ),
            ],
          ),
          Text(
            metric.value,
            maxLines: 1,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF252525),
            ),
          ),
          Text(
            metric.footer,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9,
              color: Color(0xFF27A94F),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.onPrimary,
    required this.onSecondary,
    this.compact = false,
  });

  final ProviderBooking booking;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EDF1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(booking.icon, color: AppColors.primary, size: 21),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  booking.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF222222),
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_up_rounded, size: 20),
            ],
          ),
          const SizedBox(height: 6),
          ...booking.lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.circle,
                    size: 5,
                    color: Color(0xFF98A0A7),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      line,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF4F5459),
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onSecondary,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primary),
                    foregroundColor: AppColors.primaryDark,
                    minimumSize: Size(0, compact ? 34 : 38),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(
                    booking.secondaryAction,
                    style: const TextStyle(fontSize: 10.5),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: onPrimary,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: Size(0, compact ? 34 : 38),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(
                    booking.primaryAction,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10.5),
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

class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.listing, required this.onTap});

  final ProviderListing listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE7ECEF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  listing.imageAsset,
                  height: 70,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                listing.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2A2A2A),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                listing.price,
                style: TextStyle(
                  fontSize: 10.5,
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text(
                    'Status: ',
                    style: TextStyle(fontSize: 9.5),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F7E7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '● Active',
                      style: TextStyle(
                        color: Color(0xFF208A42),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProviderDrawer extends StatelessWidget {
  const _ProviderDrawer({
    required this.partnerTitle,
    required this.onLogout,
    required this.onTap,
  });

  final String partnerTitle;
  final Future<void> Function() onLogout;
  final void Function(String label) onTap;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.brandGradientStart, AppColors.brandGradientEnd],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundImage: AssetImage('assets/images/common/avatar.png'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    partnerTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Avantika Lok Seva Provider',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  _drawerTile(Icons.dashboard_outlined, 'Dashboard'),
                  _drawerTile(Icons.calendar_month_outlined, 'Bookings'),
                  _drawerTile(Icons.account_balance_wallet_outlined, 'Earnings'),
                  _drawerTile(Icons.star_border_rounded, 'Reviews'),
                  _drawerTile(Icons.person_outline_rounded, 'Profile'),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.logout_rounded, color: AppColors.primary),
              title: const Text('Sign out'),
              onTap: () async {
                Navigator.of(context).pop();
                await onLogout();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _drawerTile(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryDark),
      title: Text(title),
      onTap: () => onTap(title),
    );
  }
}
