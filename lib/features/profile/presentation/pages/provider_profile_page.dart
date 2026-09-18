import 'package:flutter/material.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/config/app_flavor.dart';
import '../../../../app/di/injection.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../auth/domain/usecases/logout_user.dart';
import '../../domain/entities/profile_dashboard.dart';
import '../../domain/usecases/get_my_profile_dashboard.dart';

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
    _reload();
  }

  void _reload() => _future = getIt<GetMyProfileDashboard>()();

  Future<void> _logout() async {
    final confirmed = await AppDialogs.confirm(
      context,
      title: 'Log out?',
      message: 'You will need to sign in again to manage your provider account.',
      confirmLabel: 'Log out',
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await getIt<LogoutUser>()();
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(RouteNames.login, (_) => false);
  }

  void _unavailable(String label) =>
      AppFeedback.info(context, '$label is not exposed by the current provider API yet.');

  @override
  Widget build(BuildContext context) {
    if (getIt<AppConfig>().flavor != AppFlavor.provider) {
      return const Scaffold(
        body: AppEmptyState(
          title: 'Provider account unavailable',
          message: 'This screen is only available in the provider flavor.',
          icon: Icons.person_off_outlined,
        ),
      );
    }

    return AppPage(
      title: 'Provider account',
      subtitle: 'Profile, KYC and provider tools',
      child: FutureBuilder<ProfileDashboard>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingView(message: 'Loading provider account…');
          }
          if (snapshot.hasError || snapshot.data == null) {
            return AppErrorState(
              message: snapshot.error is ApiException
                  ? (snapshot.error! as ApiException).message
                  : 'Unable to load provider account.',
              onRetry: () => setState(_reload),
            );
          }

          final data = snapshot.data!;
          final provider = data.provider;
          final info = data.identity.providerProfile;
          if (provider == null || info == null) {
            return AppEmptyState(
              title: 'Provider profile not registered',
              message: 'Complete provider registration before opening provider account tools.',
              icon: Icons.person_add_alt_1_outlined,
              actionLabel: 'Continue registration',
              onAction: () => Navigator.of(context)
                  .pushNamedAndRemoveUntil(RouteNames.providerGate, (_) => false),
            );
          }

          final personal = data.identity.personalProfile;
          final rawAvatar = personal?.avatarUrl;
          final avatar = rawAvatar == null
              ? null
              : (rawAvatar.startsWith('http')
                  ? rawAvatar
                  : '${getIt<AppConfig>().baseUrl}$rawAvatar');
          final variant = _ProviderVariant.from(provider.providerType);

          return RefreshIndicator(
            onRefresh: () async {
              setState(_reload);
              await _future;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _IdentityCard(
                  name: info.publicName,
                  role: variant.title,
                  location: info.locationText.isNotEmpty
                      ? info.locationText
                      : (personal?.locationText ?? ''),
                  avatarUrl: avatar,
                  kycStatus: provider.kycStatus,
                  onEdit: () async {
                    await Navigator.of(context).pushNamed(RouteNames.providerProfileEdit);
                    if (mounted) setState(_reload);
                  },
                ),
                SizedBox(height: AppDimensions.sectionGap),
                Row(
                  children: [
                    Expanded(
                      child: AppMetricCard(
                        label: 'Bookings',
                        value: '${provider.totalBookings}',
                        icon: Icons.receipt_long_outlined,
                        onTap: provider.providerType == 'pandit'
                            ? () => Navigator.of(context).pushNamed(RouteNames.panditPoojaBookings)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppMetricCard(
                        label: 'Rating',
                        value: provider.ratings.averageRating?.toStringAsFixed(1) ?? '—',
                        footer: '${provider.ratings.count} reviews',
                        icon: Icons.star_rounded,
                        onTap: () => Navigator.of(context).pushNamed(RouteNames.providerReviews),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppDimensions.sectionGap),
                const AppSectionTitle(title: 'Account & business'),
                const SizedBox(height: 10),
                AppPanel(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _MenuRow(
                        icon: Icons.person_outline_rounded,
                        label: 'Provider account',
                        value: _pretty(info.providerType),
                        onTap: () async {
                          await Navigator.of(context).pushNamed(RouteNames.providerProfileEdit);
                          if (mounted) setState(_reload);
                        },
                      ),
                      _divider(),
                      _MenuRow(
                        icon: Icons.verified_user_outlined,
                        label: 'KYC status',
                        value: _pretty(provider.kycStatus),
                        onTap: () => Navigator.of(context).pushNamed(RouteNames.providerKyc),
                      ),
                      _divider(),
                      _MenuRow(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'My earnings',
                        value: '${provider.financial.currency} ${provider.financial.netCollected.toStringAsFixed(0)}',
                        onTap: () => Navigator.of(context).pushNamed(RouteNames.providerEarnings),
                      ),
                      _divider(),
                      _MenuRow(
                        icon: Icons.rate_review_outlined,
                        label: 'Ratings & reviews',
                        value: '${provider.ratings.count}',
                        onTap: () => Navigator.of(context).pushNamed(RouteNames.providerReviews),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppDimensions.sectionGap),
                AppSectionTitle(title: variant.managementSectionTitle),
                const SizedBox(height: 10),
                AppPanel(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _MenuRow(
                        icon: variant.domainIcon,
                        label: variant.managementLabel,
                        value: variant.secondaryDomainValue(provider),
                        onTap: provider.providerType == 'pandit'
                            ? () => Navigator.of(context).pushNamed(RouteNames.panditPoojaServices)
                            : () => _unavailable(variant.managementLabel),
                      ),
                      _divider(),
                      _MenuRow(
                        icon: Icons.calendar_month_outlined,
                        label: variant.availabilityLabel,
                        value: variant.availabilityValue(provider),
                        onTap: provider.providerType == 'pandit'
                            ? () => Navigator.of(context).pushNamed(RouteNames.panditAvailability)
                            : () => _unavailable(variant.availabilityLabel),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Log out'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _divider() => Divider(height: 1, indent: 56, color: AppColors.divider);
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.name,
    required this.role,
    required this.location,
    required this.avatarUrl,
    required this.kycStatus,
    required this.onEdit,
  });

  final String name;
  final String role;
  final String location;
  final String? avatarUrl;
  final String kycStatus;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: AppColors.primarySoft,
            backgroundImage: avatarUrl == null ? null : NetworkImage(avatarUrl!),
            child: avatarUrl == null
                ? Icon(Icons.person_rounded, size: 32, color: AppColors.primary)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTypography.title),
                const SizedBox(height: 3),
                Text(role, style: AppTypography.caption),
                if (location.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 15, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Expanded(child: Text(location, style: AppTypography.caption)),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                AppStatusChip(label: 'KYC ${_pretty(kycStatus)}'),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit profile',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(label, style: AppTypography.label),
      subtitle: Text(value, style: AppTypography.caption),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}

String _pretty(String value) => value
    .split('_')
    .map((e) => e.isEmpty ? e : '${e[0].toUpperCase()}${e.substring(1)}')
    .join(' ');

class _ProviderVariant {
  const _ProviderVariant({
    required this.title,
    required this.domainIcon,
    required this.managementSectionTitle,
    required this.managementLabel,
    required this.availabilityLabel,
  });

  final String title;
  final IconData domainIcon;
  final String managementSectionTitle;
  final String managementLabel;
  final String availabilityLabel;

  factory _ProviderVariant.from(String type) {
    switch (type) {
      case 'pandit':
        return const _ProviderVariant(
          title: 'Pandit Partner',
          domainIcon: Icons.temple_hindu_outlined,
          managementSectionTitle: 'Pooja management',
          managementLabel: 'Manage Pooja services',
          availabilityLabel: 'Availability rules',
        );
      case 'hotel_manager':
        return const _ProviderVariant(
          title: 'Stay Partner',
          domainIcon: Icons.apartment_outlined,
          managementSectionTitle: 'Accommodation management',
          managementLabel: 'Manage rooms & inventory',
          availabilityLabel: 'Room units',
        );
      case 'vehicle_owner':
        return const _ProviderVariant(
          title: 'Transport Partner',
          domainIcon: Icons.directions_car_outlined,
          managementSectionTitle: 'Transport management',
          managementLabel: 'Manage fleet & routes',
          availabilityLabel: 'Future availability',
        );
      default:
        return const _ProviderVariant(
          title: 'Service Partner',
          domainIcon: Icons.work_outline,
          managementSectionTitle: 'Service management',
          managementLabel: 'Manage services',
          availabilityLabel: 'Availability',
        );
    }
  }

  String secondaryDomainValue(ProviderDashboardSummary p) {
    switch (p.providerType) {
      case 'pandit':
        return '${p.domain.offerings} offerings';
      case 'hotel_manager':
        return '${p.domain.accommodationActive} active';
      case 'vehicle_owner':
        return '${p.domain.vehicleActive} active • ${p.domain.routes} routes';
      default:
        return '${p.domain.packageActive} active';
    }
  }

  String availabilityValue(ProviderDashboardSummary p) {
    switch (p.providerType) {
      case 'pandit':
        return '${p.domain.weeklyAvailabilityRules} rules';
      case 'hotel_manager':
        return '${p.domain.units} units';
      case 'vehicle_owner':
        return '${p.domain.futureAvailabilityRows} rows';
      default:
        return p.domain.configured ? 'Configured' : 'Not configured';
    }
  }
}
