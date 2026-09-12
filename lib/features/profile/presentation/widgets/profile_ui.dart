import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    required this.name,
    required this.location,
    required this.avatarUrl,
    required this.onEdit,
    this.subtitle,
    super.key,
  });

  final String name;
  final String location;
  final String? avatarUrl;
  final String? subtitle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.brandGradientEnd, AppColors.brandGradientStart],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .24),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                ),
              ),
              const Expanded(
                child: Text(
                  'My Profile',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 34),
            ],
          ),
          const SizedBox(height: 18),
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                foregroundImage: avatarUrl == null ? null : NetworkImage(avatarUrl!),
                child: avatarUrl == null
                    ? Icon(Icons.person, size: 48, color: AppColors.textSecondary)
                    : null,
              ),
              Positioned(
                right: -2,
                bottom: 0,
                child: InkWell(
                  onTap: onEdit,
                  child: Container(
                    width: 25,
                    height: 25,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.edit, size: 14, color: AppColors.headingPink),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
          if (location.trim().isNotEmpty) ...[
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on_outlined, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class ProfileStatTile extends StatelessWidget {
  const ProfileStatTile({
    required this.icon,
    required this.value,
    required this.label,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.brandSoft.withValues(alpha: .48),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.headingPink, size: 22),
              const SizedBox(height: 5),
              Text(
                value,
                maxLines: 1,
                style: TextStyle(
                  color: AppColors.headingPink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(fontSize: 9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileMenuRow extends StatelessWidget {
  const ProfileMenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
    this.destructive = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? const Color(0xFFB42335) : AppColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
            child: Row(
              children: [
                Icon(icon, color: destructive ? color : AppColors.accent, size: 19),
                const SizedBox(width: 12),
                Expanded(child: Text(label, style: AppTypography.body.copyWith(color: color))),
                if (value != null) ...[
                  Text(value!, style: AppTypography.caption),
                  const SizedBox(width: 6),
                ],
                Icon(Icons.chevron_right, color: destructive ? color : AppColors.accent, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileErrorView extends StatelessWidget {
  const ProfileErrorView({required this.message, required this.onRetry, super.key});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, color: AppColors.primary, size: 44),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: AppTypography.body),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
