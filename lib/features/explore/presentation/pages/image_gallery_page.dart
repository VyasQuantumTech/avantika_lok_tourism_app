import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/entities/tourism_place.dart';
import '../widgets/media_viewer_shell.dart';

class ImageGalleryPage extends StatefulWidget {
  const ImageGalleryPage(
      {required this.place, this.initialIndex = 0, super.key});
  final TourismPlace place;
  final int initialIndex;

  @override
  State<ImageGalleryPage> createState() => _ImageGalleryPageState();
}

class _ImageGalleryPageState extends State<ImageGalleryPage> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.place.images.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, widget.place.images.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _move(int offset) => _controller.animateToPage(
        _index + offset,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );

  @override
  Widget build(BuildContext context) {
    final images = widget.place.images;
    return MediaViewerShell(
      title: widget.place.name,
      footer: images.isEmpty
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (images[_index].caption.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(images[_index].caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppTypography.caption),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton.filled(
                      tooltip: 'Previous image',
                      style: IconButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          foregroundColor: AppColors.onPrimary),
                      onPressed: _index > 0 ? () => _move(-1) : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text('${_index + 1} / ${images.length}',
                        style: AppTypography.body),
                    IconButton.filled(
                      tooltip: 'Next image',
                      style: IconButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          foregroundColor: AppColors.onPrimary),
                      onPressed:
                          _index < images.length - 1 ? () => _move(1) : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ],
            ),
      child: images.isEmpty
          ? Center(
              child: Text('No images available.',
                  style: TextStyle(color: AppColors.textPrimary)))
          : PageView.builder(
              controller: _controller,
              itemCount: images.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (_, index) => Image.network(
                images[index].url,
                semanticLabel: images[index].altText,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : Center(
                        child:
                            CircularProgressIndicator(color: AppColors.accent)),
                errorBuilder: (_, __, ___) => Center(
                  child: Icon(Icons.broken_image_outlined,
                      color: AppColors.textPrimary, size: 48),
                ),
              ),
            ),
    );
  }
}
