import 'package:flutter/material.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/config/app_flavor.dart';
import '../../../../app/di/injection.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../auth/domain/usecases/logout_user.dart';
import '../../domain/entities/profile_dashboard.dart';
import '../../domain/usecases/get_my_profile_dashboard.dart';
import '../widgets/profile_ui.dart';

class CustomerProfilePage extends StatefulWidget {
  const CustomerProfilePage({super.key});

  @override
  State<CustomerProfilePage> createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends State<CustomerProfilePage> {
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label is not exposed by the current backend API yet.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (getIt<AppConfig>().flavor == AppFlavor.provider) {
      return const Scaffold(body: Center(child: Text('Customer profile is unavailable in provider flavor.')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
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
                  : 'Unable to load your profile.';
              return ProfileErrorView(message: message, onRetry: _reload);
            }

            final data = snapshot.data!;
            final identity = data.identity;
            if (identity.isProvider) {
              return const ProfileErrorView(
                message: 'This account is a provider account. Open it from Avantika Lok Seva Provider.',
                onRetry: _noop,
              );
            }
            final personal = identity.personalProfile;
            final avatar = personal?.avatarUrl;
            final resolvedAvatar = avatar == null
                ? null
                : (avatar.startsWith('http') ? avatar : '${getIt<AppConfig>().baseUrl}$avatar');

            return RefreshIndicator(
              onRefresh: () async {
                _reload();
                await _future;
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  ProfileHeader(
                    name: identity.account.fullName,
                    location: personal?.locationText ?? '',
                    avatarUrl: resolvedAvatar,
                    onEdit: () async {
                      await Navigator.of(context).pushNamed(RouteNames.customerProfileEdit);
                      if (mounted) _reload();
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 18, 14, 24),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            ProfileStatTile(
                              icon: Icons.receipt_long_outlined,
                              value: '${data.customer.totalBookings}',
                              label: 'My Orders',
                              onTap: () => _soon('Order history'),
                            ),
                            const SizedBox(width: 9),
                            ProfileStatTile(
                              icon: Icons.rate_review_outlined,
                              value: '${data.customer.reviewsGiven}',
                              label: 'Reviews',
                              onTap: () => _soon('Reviews'),
                            ),
                            const SizedBox(width: 9),
                            ProfileStatTile(
                              icon: Icons.favorite_border,
                              value: '${data.customer.totalFavorites}',
                              label: 'Favourites',
                              onTap: () => _soon('Favourite details'),
                            ),
                            const SizedBox(width: 9),
                            ProfileStatTile(
                              icon: Icons.upcoming_outlined,
                              value: '${data.customer.upcomingBookings}',
                              label: 'Upcoming',
                              onTap: () => _soon('Upcoming bookings'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        ProfileMenuRow(
                          icon: Icons.person_outline,
                          label: 'Account',
                          value: identity.account.email,
                          onTap: () async {
                            await Navigator.of(context).pushNamed(RouteNames.customerProfileEdit);
                            if (mounted) _reload();
                          },
                        ),
                        ProfileMenuRow(
                          icon: Icons.task_alt_outlined,
                          label: 'Completed Bookings',
                          value: '${data.customer.completedBookings}',
                          onTap: () => _soon('Completed booking list'),
                        ),
                        ProfileMenuRow(
                          icon: Icons.favorite_outline,
                          label: 'Saved Places / Stays / Transport',
                          value: '${data.customer.totalFavorites}',
                          onTap: () => _soon('Saved items'),
                        ),
                        ProfileMenuRow(
                          icon: Icons.privacy_tip_outlined,
                          label: 'Privacy Policy',
                          onTap: () => _soon('Privacy Policy'),
                        ),
                        ProfileMenuRow(
                          icon: Icons.description_outlined,
                          label: 'Terms And Conditions',
                          onTap: () => _soon('Terms And Conditions'),
                        ),
                        ProfileMenuRow(
                          icon: Icons.support_agent,
                          label: 'Help Center',
                          onTap: () => _soon('Help Center'),
                        ),
                        ProfileMenuRow(
                          icon: Icons.logout,
                          label: 'Log Out',
                          destructive: true,
                          onTap: _logout,
                        ),
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

void _noop() {}
