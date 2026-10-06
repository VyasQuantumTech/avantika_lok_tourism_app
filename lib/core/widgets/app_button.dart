import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimensions.dart';
import '../../app/theme/app_typography.dart';

/// System-wide primary action. The gradient comes only from flavor theme JSON.
class AppGradientButton extends StatelessWidget {
  const AppGradientButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.expand = true,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final button = Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(AppDimensions.smallRadius),
        child: Ink(
          height: 50,
          decoration: BoxDecoration(
            gradient: enabled
                ? LinearGradient(colors: [AppColors.brandGradientStart, AppColors.brandGradientEnd])
                : null,
            color: enabled ? null : AppColors.softSurface,
            borderRadius: BorderRadius.circular(AppDimensions.smallRadius),
            boxShadow: enabled
                ? [BoxShadow(color: AppColors.primary.withValues(alpha: .20), blurRadius: 16, offset: const Offset(0, 7))]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading)
                  SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary))
                else if (icon != null)
                  Icon(icon, size: 20, color: AppColors.onPrimary),
                if (loading || icon != null) const SizedBox(width: 9),
                Text(label, style: AppTypography.label.copyWith(color: enabled ? AppColors.onPrimary : AppColors.textMuted, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
