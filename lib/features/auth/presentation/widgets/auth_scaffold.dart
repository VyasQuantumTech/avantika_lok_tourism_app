import 'dart:math' as math;
import '../../../../core/widgets/temple_surface.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TempleScaffold(
      backgroundColor: AppColors.surface,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 205),
                        padding: const EdgeInsets.fromLTRB(24, 54, 24, 34),
                        decoration: BoxDecoration(
                          image: TempleArt.headerImage(strong: true),
                          gradient: TempleArt.brandGradient,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              title,
                              style: AppTypography.body.copyWith(
                                color: AppColors.onPrimary,
                                fontSize: 24,
                                height: 1.08,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              subtitle,
                              style: AppTypography.caption.copyWith(
                                color:
                                    AppColors.onPrimary.withValues(alpha: .95),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(0, -18),
                        child: Container(
                          width: double.infinity,
                          constraints: BoxConstraints(
                            minHeight: math.max(0, constraints.maxHeight - 187),
                          ),
                          padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: .96),
                            border: Border.all(color: AppColors.brandBorder),
                            boxShadow: [
                              BoxShadow(
                                  color: AppColors.shadow,
                                  blurRadius: 24,
                                  offset: const Offset(0, -4))
                            ],
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(26)),
                          ),
                          child: child,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) => AppGradientButton(
        label: label,
        onPressed: onPressed,
        loading: loading,
      );
}

class AuthSwitchLink extends StatelessWidget {
  const AuthSwitchLink({
    required this.prefix,
    required this.action,
    required this.onTap,
    super.key,
  });

  final String prefix;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(prefix, style: AppTypography.body.copyWith(fontSize: 12)),
        TextButton(
          onPressed: onTap,
          child: Text(
            action,
            style: AppTypography.body.copyWith(
              color: AppColors.headingPink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
