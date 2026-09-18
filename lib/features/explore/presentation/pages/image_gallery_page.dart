import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/entities/tourism_place.dart';

class ImageGalleryPage extends StatefulWidget {
  const ImageGalleryPage({required this.place, super.key});
  final TourismPlace place;

  @override
  State<ImageGalleryPage> createState() => _ImageGalleryPageState();
}

class _ImageGalleryPageState extends State<ImageGalleryPage> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.place.images;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(AppDimensions.pagePadding, 8, AppDimensions.pagePadding, 16),
          child: Column(
            children: [
              _GalleryHeader(title: 'Image Gallery', onBack: () => Navigator.of(context).pop()),
              const SizedBox(height: 12),
              AspectRatio(
                aspectRatio: 0.92,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: images.length,
                    onPageChanged: (value) => setState(() => _index = value),
                    itemBuilder: (_, index) => Image.network(
                      images[index].url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_outlined, size: 48)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 62,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 9),
                  itemBuilder: (_, index) => InkWell(
                    onTap: () => _controller.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                    ),
                    child: Container(
                      width: 62,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: index == _index ? AppColors.primaryDark : AppColors.transparent,
                          width: 2,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.network(
                        images[index].thumbnailUrl.isNotEmpty ? images[index].thumbnailUrl : images[index].url,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GalleryHeader extends StatelessWidget {
  const _GalleryHeader({required this.title, required this.onBack});
  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                child: Icon(Icons.arrow_back, color: AppColors.onPrimary, size: 19),
              ),
            ),
          ),
          Text(title, style: AppTypography.sectionTitle.copyWith(fontSize: 15)),
          Align(
            alignment: Alignment.centerRight,
            child: Icon(Icons.share_outlined, color: AppColors.textPrimary, size: 23),
          ),
        ],
      ),
    );
  }
}
