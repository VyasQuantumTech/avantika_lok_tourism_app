import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/entities/tourism_place.dart';
import '../widgets/media_viewer_shell.dart';
import '../widgets/youtube_media.dart';

/// The player is created only after opening this full-page route.
class VideoGalleryPage extends StatefulWidget {
  const VideoGalleryPage(
      {required this.place, this.initialIndex = 0, super.key});
  final TourismPlace place;
  final int initialIndex;

  @override
  State<VideoGalleryPage> createState() => _VideoGalleryPageState();
}

class _VideoGalleryPageState extends State<VideoGalleryPage> {
  @override
  Widget build(BuildContext context) {
    final videos = widget.place.externalMedia
        .where((item) => item.isVideo)
        .toList(growable: false);
    final video = videos.isEmpty
        ? null
        : videos[widget.initialIndex.clamp(0, videos.length - 1)];
    return MediaViewerShell(
      title: video == null || video.title.isEmpty ? 'Videos' : video.title,
      child: video == null
          ? Center(
              child: Text('No videos available.',
                  style: TextStyle(color: AppColors.textPrimary)))
          : _FullscreenVideo(url: video.url),
    );
  }
}

class _FullscreenVideo extends StatefulWidget {
  const _FullscreenVideo({required this.url});
  final String url;

  @override
  State<_FullscreenVideo> createState() => _FullscreenVideoState();
}

class _FullscreenVideoState extends State<_FullscreenVideo>
    with WidgetsBindingObserver {
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final id = youtubeVideoId(widget.url);
    if (id != null) {
      _controller = YoutubePlayerController(
        initialVideoId: id,
        flags: const YoutubePlayerFlags(autoPlay: true, enableCaption: true),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _controller?.pause();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.pause();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('This video does not have a valid YouTube URL.',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: AppColors.textPrimary)),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => Center(
        child: YoutubePlayer(
          width:
              constraints.maxWidth.clamp(0.0, constraints.maxHeight * 16 / 9),
          controller: controller,
          showVideoProgressIndicator: true,
          progressIndicatorColor: AppColors.accent,
          progressColors: ProgressBarColors(
              playedColor: AppColors.primaryDark,
              handleColor: AppColors.accent),
          // Already in the fullscreen viewer: keep playback controls here.
          bottomActions: [
            const CurrentPosition(),
            ProgressBar(isExpanded: true),
            const RemainingDuration(),
            const PlaybackSpeedButton(),
          ],
        ),
      ),
    );
  }
}
