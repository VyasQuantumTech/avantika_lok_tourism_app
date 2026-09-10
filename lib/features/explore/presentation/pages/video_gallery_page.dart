import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/entities/tourism_place.dart';

class VideoGalleryPage extends StatefulWidget {
  const VideoGalleryPage({required this.place, super.key});
  final TourismPlace place;

  @override
  State<VideoGalleryPage> createState() => _VideoGalleryPageState();
}

class _VideoGalleryPageState extends State<VideoGalleryPage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final videos = widget.place.externalMedia.where((item) => item.isVideo).toList(growable: false);
    final current = videos[_index];
    final thumb = current.thumbnailUrl.isNotEmpty ? current.thumbnailUrl : _youtubeThumbnail(current.url);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppDimensions.pagePadding, 8, AppDimensions.pagePadding, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(onBack: () => Navigator.of(context).pop()),
              const SizedBox(height: 12),
              AspectRatio(
                aspectRatio: 0.72,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (thumb.isNotEmpty)
                        Image.network(
                          thumb,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      Container(color: Colors.black26),
                      Center(
                        child: InkWell(
                          onTap: () => _showVideoLink(context, current.url),
                          child: Container(
                            width: 58,
                            height: 58,
                            decoration: const BoxDecoration(color: Colors.white70, shape: BoxShape.circle),
                            child: Icon(Icons.play_arrow, color: AppColors.primaryDark, size: 36),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (current.title.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(current.title, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: 12),
              SizedBox(
                height: 62,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: videos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 9),
                  itemBuilder: (_, index) {
                    final video = videos[index];
                    final thumbnail = video.thumbnailUrl.isNotEmpty ? video.thumbnailUrl : _youtubeThumbnail(video.url);
                    return InkWell(
                      onTap: () => setState(() => _index = index),
                      child: Container(
                        width: 62,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: index == _index ? AppColors.primaryDark : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (thumbnail.isNotEmpty) Image.network(thumbnail, fit: BoxFit.cover),
                            const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 24)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVideoLink(BuildContext context, String url) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Video URL', style: AppTypography.body.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              SelectableText(url, style: AppTypography.caption.copyWith(fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
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
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 19),
              ),
            ),
          ),
          Text('Video Gallery', style: AppTypography.sectionTitle.copyWith(fontSize: 15)),
          const Align(
            alignment: Alignment.centerRight,
            child: Icon(Icons.share_outlined, color: AppColors.textPrimary, size: 23),
          ),
        ],
      ),
    );
  }
}

String _youtubeThumbnail(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return '';
  String id = '';
  if (uri.host.contains('youtu.be')) {
    id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
  } else if (uri.host.contains('youtube.com')) {
    id = uri.queryParameters['v'] ?? '';
    if (id.isEmpty) {
      final segments = uri.pathSegments;
      final embedIndex = segments.indexOf('embed');
      if (embedIndex >= 0 && embedIndex + 1 < segments.length) id = segments[embedIndex + 1];
    }
  }
  return id.isEmpty ? '' : 'https://img.youtube.com/vi/$id/hqdefault.jpg';
}
