import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/entities/tourism_place.dart';

class TourismPlaceCard extends StatelessWidget {
  const TourismPlaceCard({required this.place, required this.onTap, super.key});

  final TourismPlace place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: const Color(0xFFE8E8E8)),
            boxShadow: const [
              BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 2)),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 2.08,
                child: _NetworkImage(url: place.coverImage),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(9, 8, 9, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      place.locationLabel.isNotEmpty ? place.locationLabel : place.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NetworkImage extends StatelessWidget {
  const _NetworkImage({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Container(
        color: AppColors.softSurface,
        child: const Icon(Icons.temple_hindu_outlined, size: 54, color: AppColors.textMuted),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.softSurface,
        child: const Icon(Icons.broken_image_outlined, size: 44, color: AppColors.textMuted),
      ),
    );
  }
}
