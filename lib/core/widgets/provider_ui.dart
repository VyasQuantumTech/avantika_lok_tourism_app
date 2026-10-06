import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimensions.dart';
import '../../app/theme/app_typography.dart';
import 'app_button.dart';
import 'app_ui.dart';

/// Shared provider-facing visual system.
///
/// Keep provider screens composed from these widgets instead of defining
/// screen-specific colors, radii, shadows or action styles. All visual values
/// resolve through the active theme JSON via AppColors/AppDimensions.
class ProviderHeroCard extends StatelessWidget {
  const ProviderHeroCard({
    required this.eyebrow,
    required this.value,
    super.key,
    this.subtitle,
    this.icon = Icons.auto_graph_rounded,
    this.trailing,
    this.onTap,
  });

  final String eyebrow;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Ink(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.brandGradientStart, AppColors.brandGradientEnd],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .22),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.onPrimary.withValues(alpha: .82),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.tiny.copyWith(
                      color: AppColors.onPrimary.withValues(alpha: .76),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing ??
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.onPrimary.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: AppColors.onPrimary, size: 28),
              ),
        ],
      ),
    );
    if (onTap == null) return card;
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        child: card,
      ),
    );
  }
}

class ProviderInfoBanner extends StatelessWidget {
  const ProviderInfoBanner({
    required this.title,
    required this.message,
    super.key,
    this.icon = Icons.info_outline_rounded,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.infoSoft,
            AppColors.primarySoft.withValues(alpha: .54),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.smallRadius),
        border: Border.all(color: AppColors.info.withValues(alpha: .16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: .72),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.info, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.label.copyWith(color: AppColors.info),
                ),
                const SizedBox(height: 3),
                Text(message, style: AppTypography.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProviderFormSection extends StatelessWidget {
  const ProviderFormSection({
    required this.title,
    required this.children,
    super.key,
    this.subtitle,
    this.icon,
    this.trailing,
    this.padding,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      padding: padding ?? EdgeInsets.all(AppDimensions.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                ProviderIconBox(icon: icon!),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.sectionTitle),
                    if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(subtitle!, style: AppTypography.caption),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (children.isNotEmpty) const SizedBox(height: 14),
          ..._withGaps(children),
        ],
      ),
    );
  }

  static List<Widget> _withGaps(List<Widget> children) {
    final result = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      result.add(children[i]);
      if (i != children.length - 1) result.add(const SizedBox(height: 10));
    }
    return result;
  }
}

class ProviderIconBox extends StatelessWidget {
  const ProviderIconBox({
    required this.icon,
    super.key,
    this.size = 40,
    this.iconSize = 20,
    this.tone = ProviderIconTone.primary,
  });

  final IconData icon;
  final double size;
  final double iconSize;
  final ProviderIconTone tone;

  @override
  Widget build(BuildContext context) {
    final palette = switch (tone) {
      ProviderIconTone.primary => (AppColors.primary, AppColors.primarySoft),
      ProviderIconTone.success => (AppColors.success, AppColors.successSoft),
      ProviderIconTone.warning => (AppColors.warning, AppColors.warningSoft),
      ProviderIconTone.error => (AppColors.error, AppColors.errorSoft),
      ProviderIconTone.info => (AppColors.info, AppColors.infoSoft),
    };
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.$2,
        borderRadius: BorderRadius.circular(size * .3),
      ),
      child: Icon(icon, color: palette.$1, size: iconSize),
    );
  }
}

enum ProviderIconTone { primary, success, warning, error, info }

class ProviderQuickActionTile extends StatelessWidget {
  const ProviderQuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
    this.tone = ProviderIconTone.primary,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ProviderIconTone tone;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ProviderIconBox(icon: icon, tone: tone),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTypography.tiny.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class ProviderListCard extends StatelessWidget {
  const ProviderListCard({
    required this.title,
    required this.subtitle,
    super.key,
    this.imageUrl,
    this.placeholderIcon = Icons.image_outlined,
    this.status,
    this.statusTone,
    this.meta = const [],
    this.footer,
    this.onTap,
    this.actions = const [],
  });

  final String title;
  final String subtitle;
  final String? imageUrl;
  final IconData placeholderIcon;
  final String? status;
  final AppStatusTone? statusTone;
  final List<ProviderMetaItem> meta;
  final Widget? footer;
  final VoidCallback? onTap;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProviderMediaThumb(
                imageUrl: imageUrl,
                placeholderIcon: placeholderIcon,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.label.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (subtitle.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption,
                      ),
                    ],
                  ],
                ),
              ),
              if (status != null && status!.trim().isNotEmpty) ...[
                const SizedBox(width: 8),
                AppStatusChip(label: status!, tone: statusTone),
              ],
            ],
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 14,
              runSpacing: 8,
              children: meta.map((item) => _ProviderMeta(item: item)).toList(),
            ),
          ],
          if (footer != null) ...[
            const SizedBox(height: 12),
            footer!,
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          ],
        ],
      ),
    );
  }
}

class ProviderMetaItem {
  const ProviderMetaItem(this.icon, this.text);
  final IconData icon;
  final String text;
}

class _ProviderMeta extends StatelessWidget {
  const _ProviderMeta({required this.item});
  final ProviderMetaItem item;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icon, size: 15, color: AppColors.textMuted),
          const SizedBox(width: 5),
          Text(item.text, style: AppTypography.tiny.copyWith(color: AppColors.textSecondary)),
        ],
      );
}

class ProviderMediaThumb extends StatelessWidget {
  const ProviderMediaThumb({
    super.key,
    this.imageUrl,
    this.placeholderIcon = Icons.image_outlined,
    this.width = 68,
    this.height = 68,
  });

  final String? imageUrl;
  final IconData placeholderIcon;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primarySoft, AppColors.brandSoft],
        ),
      ),
      child: Icon(placeholderIcon, color: AppColors.primary, size: 28),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: imageUrl == null || imageUrl!.trim().isEmpty
          ? placeholder
          : Image.network(
              imageUrl!,
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => placeholder,
            ),
    );
  }
}

class ProviderActionButton extends StatelessWidget {
  const ProviderActionButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.loading = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) => AppGradientButton(
        label: label,
        onPressed: onPressed,
        icon: icon,
        loading: loading,
        expand: expand,
      );
}

class ProviderSecondaryButton extends StatelessWidget {
  const ProviderSecondaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.destructive = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.error : AppColors.primary;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon ?? Icons.arrow_forward_rounded, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: destructive ? AppColors.error.withValues(alpha: .35) : AppColors.border),
        backgroundColor: destructive ? AppColors.errorSoft.withValues(alpha: .38) : AppColors.surface,
      ),
    );
  }
}

class ProviderMetricStrip extends StatelessWidget {
  const ProviderMetricStrip({required this.items, super.key});
  final List<ProviderMetric> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(items.length, (index) {
        final item = items[index];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == items.length - 1 ? 0 : 10),
            child: AppPanel(
              padding: const EdgeInsets.all(13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProviderIconBox(icon: item.icon, tone: item.tone, size: 36, iconSize: 18),
                  const SizedBox(height: 9),
                  Text(item.value, style: AppTypography.title),
                  const SizedBox(height: 2),
                  Text(item.label, style: AppTypography.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class ProviderMetric {
  const ProviderMetric({required this.label, required this.value, required this.icon, this.tone = ProviderIconTone.primary});
  final String label;
  final String value;
  final IconData icon;
  final ProviderIconTone tone;
}


class ProviderFloatingActionButton extends StatelessWidget {
  const ProviderFloatingActionButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon = Icons.add_rounded,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      elevation: 0,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppDimensions.pillRadius),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            gradient: onPressed == null
                ? null
                : LinearGradient(colors: [AppColors.brandGradientStart, AppColors.brandGradientEnd]),
            color: onPressed == null ? AppColors.softSurface : null,
            borderRadius: BorderRadius.circular(AppDimensions.pillRadius),
            boxShadow: onPressed == null
                ? null
                : [BoxShadow(color: AppColors.primary.withValues(alpha: .24), blurRadius: 18, offset: const Offset(0, 8))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: onPressed == null ? AppColors.textMuted : AppColors.onPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.label.copyWith(
                  color: onPressed == null ? AppColors.textMuted : AppColors.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProviderSectionAction extends StatelessWidget {
  const ProviderSectionAction({required this.label, required this.onPressed, super.key, this.icon = Icons.add_rounded});
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) => TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        label: Text(label),
      );
}
