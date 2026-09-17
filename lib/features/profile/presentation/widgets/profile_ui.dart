import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_ui.dart';

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
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppDimensions.cardRadius + 14),
          bottomRight: Radius.circular(AppDimensions.cardRadius + 14),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                borderRadius: BorderRadius.circular(99),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.onPrimary.withValues(alpha: .18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.onPrimary,
                    size: 20,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'My Profile',
                  textAlign: TextAlign.center,
                  style: AppTypography.sectionTitle.copyWith(
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 36),
            ],
          ),
          const SizedBox(height: 18),
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: AppColors.surface,
                foregroundImage:
                    avatarUrl == null ? null : NetworkImage(avatarUrl!),
                child: avatarUrl == null
                    ? Icon(
                        Icons.person_rounded,
                        size: 46,
                        color: AppColors.textSecondary,
                      )
                    : null,
              ),
              Positioned(
                right: -2,
                bottom: 0,
                child: InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(99),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Icon(
                      Icons.edit_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            name,
            textAlign: TextAlign.center,
            style: AppTypography.title.copyWith(color: AppColors.onPrimary),
          ),
          if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: AppColors.onPrimary.withValues(alpha: .78),
              ),
            ),
          ],
          if (location.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: AppColors.onPrimary,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.onPrimary,
                    ),
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
      child: AppPanel(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(height: 7),
            Text(
              value,
              maxLines: 1,
              style: AppTypography.label.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.tiny,
            ),
          ],
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
    final color = destructive ? AppColors.error : AppColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppPanel(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: destructive ? AppColors.errorSoft : AppColors.primarySoft,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                color: destructive ? AppColors.error : AppColors.primary,
                size: 19,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTypography.body.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (value != null) ...[
              Text(value!, style: AppTypography.caption),
              const SizedBox(width: 6),
            ],
            Icon(
              Icons.chevron_right_rounded,
              color: destructive ? AppColors.error : AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileErrorView extends StatelessWidget {
  const ProfileErrorView({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppErrorState(message: message, onRetry: onRetry);
  }
}
