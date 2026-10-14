import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/temple_surface.dart';

/// Shared full-page media surface, using the detail screen's theme and controls.
class MediaViewerShell extends StatelessWidget {
  const MediaViewerShell({
    required this.title,
    required this.child,
    this.footer,
    super.key,
  });

  final String title;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) => TempleScaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        tooltip: 'Close viewer',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: AppColors.onPrimary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.sectionTitle
                              .copyWith(fontSize: 15)),
                    ),
                  ],
                ),
              ),
              Expanded(child: SizedBox.expand(child: child)),
              if (footer != null)
                Padding(padding: const EdgeInsets.all(12), child: footer),
            ],
          ),
        ),
      );
}
