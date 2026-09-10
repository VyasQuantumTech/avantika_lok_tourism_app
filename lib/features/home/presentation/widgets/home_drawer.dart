import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../auth/domain/usecases/logout_user.dart';
import '../../domain/entities/home_dashboard.dart';
import 'home_icon_mapper.dart';

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({required this.dashboard, super.key});

  final HomeDashboard dashboard;

  Future<void> _signOut(BuildContext context) async {
    // Capture the app navigator before closing the drawer. The previous
    // implementation closed the drawer first and then tried to open the
    // confirmation dialog with the drawer's now-deactivated BuildContext,
    // so the logout flow never actually started.
    final appNavigator = Navigator.of(context, rootNavigator: true);

    final shouldSignOut = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again to access your account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (shouldSignOut != true) return;

    // The confirmation dialog has finished, so it is now safe to close the
    // drawer. Do not use the drawer BuildContext for navigation after this.
    if (context.mounted) {
      Navigator.of(context).pop();
    }

    try {
      await getIt<LogoutUser>()();
    } catch (_) {
      // Logout remains local-first. Even if the backend cannot be reached,
      // the repository invalidates and clears the persisted local session.
    }

    if (!appNavigator.mounted) return;
    appNavigator.pushNamedAndRemoveUntil(
      RouteNames.login,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: AppDimensions.drawerWidth,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            _ProfileHeader(profile: dashboard.profile),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 8),
                  ...dashboard.menu.map(
                    (item) => _DrawerItem(
                      item: item,
                      onTap: () {
                        if (item.title == 'Sign out') {
                          _signOut(context);
                          return;
                        }
                        if (item.title != 'Home') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${item.title} screen will be connected next.'),
                              duration: const Duration(milliseconds: 900),
                            ),
                          );
                        }
                        Navigator.of(context).maybePop();
                      },
                    ),
                  ),
                  const Divider(height: 32, thickness: 1),
                  ...dashboard.secondaryMenu.map(
                    (item) => _DrawerItem(
                      item: item,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${item.title} screen will be connected next.'),
                            duration: const Duration(milliseconds: 900),
                          ),
                        );
                        Navigator.of(context).maybePop();
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 50, 16, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.brandGradientEnd, AppColors.brandGradientStart],
        ),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
                backgroundImage: AssetImage(profile.avatar),
              ),
              const SizedBox(height: 14),
              Text(
                profile.name,
                style: AppTypography.body.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      profile.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(color: Colors.white),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 18),
                ],
              ),
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.96),
              ),
              child: Icon(
                Icons.notifications_none,
                color: AppColors.primary,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({required this.item, required this.onTap});

  final MenuItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18),
      minLeadingWidth: 23,
      leading: Icon(
        HomeIconMapper.fromKey(item.icon),
        color: AppColors.iconPink,
        size: 20,
      ),
      title: Text(
        item.title,
        style: AppTypography.body.copyWith(
          fontSize: 13,
          color: const Color(0xFF767676),
        ),
      ),
      onTap: onTap,
    );
  }
}
