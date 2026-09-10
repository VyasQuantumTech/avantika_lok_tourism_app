import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/entities/home_dashboard.dart';
import 'home_icon_mapper.dart';

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({required this.dashboard, super.key});

  final HomeDashboard dashboard;

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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFF56564), Color(0xFFFF925A)],
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
              child: const Icon(
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
