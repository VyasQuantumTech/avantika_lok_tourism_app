import 'package:flutter/material.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/config/app_flavor.dart';
import '../../../../app/di/injection.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../auth/domain/usecases/logout_user.dart';
import '../../domain/entities/profile_dashboard.dart';
import '../../domain/entities/profile_snapshot.dart';
import '../../domain/usecases/get_my_profile_dashboard.dart';
import '../widgets/profile_ui.dart';

class ProviderProfilePage extends StatefulWidget {
  const ProviderProfilePage({super.key});
  @override
  State<ProviderProfilePage> createState() => _ProviderProfilePageState();
}

class _ProviderProfilePageState extends State<ProviderProfilePage> {
  late Future<ProfileDashboard> _future;

  @override
  void initState() {
    super.initState();
    _future = getIt<GetMyProfileDashboard>()();
  }

  void _reload() => setState(() => _future = getIt<GetMyProfileDashboard>()());

  Future<void> _logout() async {
    try { await getIt<LogoutUser>()(); } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(RouteNames.login, (_) => false);
  }

  void _soon(String label) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label will use its dedicated provider API in the next module.')));
  }

  @override
  Widget build(BuildContext context) {
    if (getIt<AppConfig>().flavor != AppFlavor.provider) {
      return const Scaffold(body: Center(child: Text('Provider profile is only available in provider flavor.')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      body: SafeArea(
        child: FutureBuilder<ProfileDashboard>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: AppColors.primary));
            }
            if (snapshot.hasError || snapshot.data == null) {
              final message = snapshot.error is ApiException
                  ? (snapshot.error! as ApiException).message
                  : 'Unable to load provider profile.';
              return ProfileErrorView(message: message, onRetry: _reload);
            }
            final data = snapshot.data!;
            final provider = data.provider;
            final info = data.identity.providerProfile;
            if (provider == null || info == null) {
              return ProfileErrorView(
                message: 'Provider profile is not registered for this account.',
                onRetry: () => Navigator.of(context).pushNamedAndRemoveUntil(RouteNames.providerGate, (_) => false),
              );
            }

            final personal = data.identity.personalProfile;
            final rawAvatar = personal?.avatarUrl;
            final avatar = rawAvatar == null
                ? null
                : (rawAvatar.startsWith('http') ? rawAvatar : '${getIt<AppConfig>().baseUrl}$rawAvatar');
            final variant = _ProviderVariant.from(provider.providerType);

            return RefreshIndicator(
              onRefresh: () async { _reload(); await _future; },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  ProfileHeader(
                    name: info.publicName,
                    subtitle: variant.title,
                    location: info.locationText.isNotEmpty ? info.locationText : (personal?.locationText ?? ''),
                    avatarUrl: avatar,
                    onEdit: () async {
                      await Navigator.of(context).pushNamed(RouteNames.providerProfileEdit);
                      if (mounted) _reload();
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 18, 14, 24),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            ProfileStatTile(icon: Icons.receipt_long_outlined, value: '${provider.totalBookings}', label: 'Bookings', onTap: () => _soon('Booking list')),
                            const SizedBox(width: 9),
                            ProfileStatTile(icon: Icons.upcoming_outlined, value: '${provider.upcomingBookings}', label: 'Upcoming', onTap: () => _soon('Upcoming bookings')),
                            const SizedBox(width: 9),
                            ProfileStatTile(icon: Icons.star_outline, value: provider.ratings.averageRating?.toStringAsFixed(1) ?? '—', label: 'Rating', onTap: () => _soon('Reviews')),
                            const SizedBox(width: 9),
                            ProfileStatTile(icon: variant.domainIcon, value: variant.primaryDomainValue(provider), label: variant.primaryDomainLabel, onTap: () => _soon(variant.primaryDomainLabel)),
                          ],
                        ),
                        const SizedBox(height: 18),
                        ProfileMenuRow(icon: Icons.person_outline, label: 'Provider Account', value: info.providerType, onTap: () async {
                          await Navigator.of(context).pushNamed(RouteNames.providerProfileEdit);
                          if (mounted) _reload();
                        }),
                        ProfileMenuRow(icon: Icons.verified_user_outlined, label: 'KYC Status', value: _pretty(provider.kycStatus), onTap: () => _soon('KYC management')),
                        ProfileMenuRow(icon: Icons.account_balance_wallet_outlined, label: 'My Earnings', value: '₹${provider.financial.netCollected.toStringAsFixed(0)}', onTap: () => Navigator.of(context).pushNamed(RouteNames.providerEarnings)),
                        ProfileMenuRow(icon: variant.domainIcon, label: variant.managementLabel, value: variant.secondaryDomainValue(provider), onTap: () => _soon(variant.managementLabel)),
                        ProfileMenuRow(icon: Icons.calendar_month_outlined, label: variant.availabilityLabel, value: variant.availabilityValue(provider), onTap: () => _soon(variant.availabilityLabel)),
                        ProfileMenuRow(icon: Icons.rate_review_outlined, label: 'Reviews', value: '${provider.ratings.count}', onTap: () => _soon('Reviews')),
                        ProfileMenuRow(icon: Icons.logout, label: 'Log Out', destructive: true, onTap: _logout),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

String _pretty(String value) => value.split('_').map((e) => e.isEmpty ? e : '${e[0].toUpperCase()}${e.substring(1)}').join(' ');

class _ProviderVariant {
  const _ProviderVariant({
    required this.title,
    required this.domainIcon,
    required this.primaryDomainLabel,
    required this.managementLabel,
    required this.availabilityLabel,
  });

  final String title;
  final IconData domainIcon;
  final String primaryDomainLabel;
  final String managementLabel;
  final String availabilityLabel;

  factory _ProviderVariant.from(String type) {
    switch (type) {
      case 'pandit':
        return const _ProviderVariant(title: 'Pandit Partner', domainIcon: Icons.temple_hindu_outlined, primaryDomainLabel: 'Poojas', managementLabel: 'Manage Pooja Services', availabilityLabel: 'Availability Rules');
      case 'hotel_manager':
        return const _ProviderVariant(title: 'Stay Partner', domainIcon: Icons.apartment_outlined, primaryDomainLabel: 'Properties', managementLabel: 'Manage Rooms & Inventory', availabilityLabel: 'Room Units');
      case 'vehicle_owner':
        return const _ProviderVariant(title: 'Transport Partner', domainIcon: Icons.directions_car_outlined, primaryDomainLabel: 'Vehicles', managementLabel: 'Manage Fleet & Routes', availabilityLabel: 'Future Availability');
      default:
        return const _ProviderVariant(title: 'Service Partner', domainIcon: Icons.work_outline, primaryDomainLabel: 'Services', managementLabel: 'Manage Services', availabilityLabel: 'Availability');
    }
  }

  String primaryDomainValue(ProviderDashboardSummary p) {
    switch (p.providerType) {
      case 'pandit': return '${p.domain.offerings}';
      case 'hotel_manager': return '${p.domain.accommodationTotal}';
      case 'vehicle_owner': return '${p.domain.vehicleTotal}';
      default: return '${p.domain.packageTotal}';
    }
  }

  String secondaryDomainValue(ProviderDashboardSummary p) {
    switch (p.providerType) {
      case 'pandit': return '${p.domain.offerings} active';
      case 'hotel_manager': return '${p.domain.accommodationActive} active';
      case 'vehicle_owner': return '${p.domain.vehicleActive} active • ${p.domain.routes} routes';
      default: return '${p.domain.packageActive} active';
    }
  }

  String availabilityValue(ProviderDashboardSummary p) {
    switch (p.providerType) {
      case 'pandit': return '${p.domain.weeklyAvailabilityRules}';
      case 'hotel_manager': return '${p.domain.units}';
      case 'vehicle_owner': return '${p.domain.futureAvailabilityRows}';
      default: return p.domain.configured ? 'Configured' : 'Not configured';
    }
  }
}
