import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/entities/tourism_place.dart';
import '../../domain/usecases/get_tourism_place_detail.dart';

class ExploreDetailPage extends StatefulWidget {
  const ExploreDetailPage({required this.initialPlace, super.key});

  final TourismPlace initialPlace;

  @override
  State<ExploreDetailPage> createState() => _ExploreDetailPageState();
}

class _ExploreDetailPageState extends State<ExploreDetailPage> {
  late Future<TourismPlace> _future;
  int _heroIndex = 0;

  @override
  void initState() {
    super.initState();
    _future = getIt<GetTourismPlaceDetail>()(
      id: widget.initialPlace.id,
      slug: widget.initialPlace.slug,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<TourismPlace>(
          future: _future,
          initialData: widget.initialPlace,
          builder: (context, snapshot) {
            final place = snapshot.data ?? widget.initialPlace;
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _TopBar(title: place.name)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.pagePadding,
                    4,
                    AppDimensions.pagePadding,
                    24,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _HeroGallery(
                        place: place,
                        index: _heroIndex,
                        onChanged: (value) => setState(() => _heroIndex = value),
                      ),
                      const SizedBox(height: 14),
                      _AboutCard(place: place),
                      const SizedBox(height: 14),
                      _VisitorInfoCard(place: place),
                      if (place.detailSections.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        ...place.detailSections.map(
                          (section) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _InfoCard(title: section.title, body: section.content),
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      _GalleryCard(place: place),
                      if (snapshot.connectionState == ConnectionState.waiting) ...[
                        const SizedBox(height: 12),
                        const LinearProgressIndicator(minHeight: 2, color: AppColors.primaryDark),
                      ],
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppDimensions.pagePadding, 8, AppDimensions.pagePadding, 8),
      child: SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.sectionTitle.copyWith(fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroGallery extends StatelessWidget {
  const _HeroGallery({required this.place, required this.index, required this.onChanged});
  final TourismPlace place;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final images = place.images;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1.8,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: images.isEmpty
                  ? const _ImagePlaceholder()
                  : PageView.builder(
                      itemCount: images.length,
                      onPageChanged: onChanged,
                      itemBuilder: (_, i) => Image.network(
                        images[i].url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const _ImagePlaceholder(),
                      ),
                    ),
            ),
          ),
          if (images.length > 1) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length.clamp(0, 8).toInt(),
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == index ? 8 : 6,
                  height: i == index ? 8 : 6,
                  decoration: BoxDecoration(
                    color: i == index ? AppColors.primaryDark : AppColors.textMuted,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.place});
  final TourismPlace place;

  @override
  Widget build(BuildContext context) {
    final body = place.description.isNotEmpty ? place.description : place.shortDescription;
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About ${place.name}',
            style: AppTypography.body.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(body.isEmpty ? 'Details will be available soon.' : body, style: AppTypography.body),
          if (place.address.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, color: AppColors.accent, size: 18),
                const SizedBox(width: 6),
                Expanded(child: Text(place.address, style: AppTypography.caption.copyWith(fontSize: 11))),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _VisitorInfoCard extends StatelessWidget {
  const _VisitorInfoCard({required this.place});
  final TourismPlace place;

  @override
  Widget build(BuildContext context) {
    final info = place.visitorInfo;
    if (info.isEmpty) return const SizedBox.shrink();

    final ordered = <MapEntry<String, dynamic>>[];
    const preferred = ['darshanTiming', 'darshan_timing', 'aartiTiming', 'aarti_timing', 'dressCode', 'dress_code', 'photography', 'prasad'];
    final used = <String>{};
    for (final key in preferred) {
      if (info.containsKey(key) && used.add(key)) ordered.add(MapEntry(key, info[key]));
    }
    for (final entry in info.entries) {
      if (used.add(entry.key)) ordered.add(entry);
    }

    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Temple Times And Detail', style: AppTypography.body.copyWith(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...ordered.map((entry) => _VisitorRow(label: _humanize(entry.key), value: _formatValue(entry.value))),
        ],
      ),
    );
  }
}

class _VisitorRow extends StatelessWidget {
  const _VisitorRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(color: Color(0xFFFFE4C7), shape: BoxShape.circle),
            child: Icon(_iconFor(label), color: AppColors.accent, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: AppTypography.caption.copyWith(fontSize: 11, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String label) {
    final text = label.toLowerCase();
    if (text.contains('time')) return Icons.schedule;
    if (text.contains('dress')) return Icons.checkroom_outlined;
    if (text.contains('photo')) return Icons.photo_camera_outlined;
    if (text.contains('prasad')) return Icons.temple_hindu_outlined;
    return Icons.info_outline;
  }
}

class _GalleryCard extends StatelessWidget {
  const _GalleryCard({required this.place});
  final TourismPlace place;

  @override
  Widget build(BuildContext context) {
    final videos = place.externalMedia.where((item) => item.isVideo).toList(growable: false);
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gallery', style: AppTypography.body.copyWith(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _GalleryButton(
                  label: 'Images',
                  active: place.images.isNotEmpty,
                  onTap: place.images.isEmpty
                      ? null
                      : () => Navigator.of(context).pushNamed(RouteNames.imageGallery, arguments: place),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _GalleryButton(
                  label: 'Video',
                  active: videos.isNotEmpty,
                  onTap: videos.isEmpty
                      ? null
                      : () => Navigator.of(context).pushNamed(RouteNames.videoGallery, arguments: place),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _GalleryButton(label: 'Stories', active: place.stories.isNotEmpty, onTap: null),
              ),
            ],
          ),
          if (place.images.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 82,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: place.images.length.clamp(0, 4).toInt(),
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: SizedBox(
                    width: 82,
                    child: Image.network(
                      place.images[index].thumbnailUrl.isNotEmpty
                          ? place.images[index].thumbnailUrl
                          : place.images[index].url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const _ImagePlaceholder(),
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (place.stories.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...place.stories.take(2).map(
              (story) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('${story.title}\n${story.content}', style: AppTypography.caption.copyWith(fontSize: 11, height: 1.4)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GalleryButton extends StatelessWidget {
  const _GalleryButton({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(colors: [AppColors.accent, AppColors.primaryDark])
              : null,
          color: active ? null : AppColors.softSurface,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            fontSize: 10,
            color: active ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) Text(title, style: AppTypography.body.copyWith(fontWeight: FontWeight.w700)),
          if (title.isNotEmpty && body.isNotEmpty) const SizedBox(height: 6),
          if (body.isNotEmpty) Text(body, style: AppTypography.body),
        ],
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: child,
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.softSurface,
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image_outlined, color: AppColors.textMuted, size: 48),
    );
  }
}

String _humanize(String value) {
  final spaced = value
      .replaceAll('_', ' ')
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (match) => '${match.group(1)} ${match.group(2)}')
      .trim();
  if (spaced.isEmpty) return 'Information';
  return spaced.split(RegExp(r'\s+')).map((word) {
    if (word.isEmpty) return word;
    return '${word[0].toUpperCase()}${word.substring(1)}';
  }).join(' ');
}

String _formatValue(dynamic value) {
  if (value == null) return '-';
  if (value is String || value is num || value is bool) return value.toString();
  if (value is List) return value.map(_formatValue).join('\n');
  if (value is Map) {
    return value.entries.map((entry) => '${_humanize(entry.key.toString())}: ${_formatValue(entry.value)}').join('\n');
  }
  return value.toString();
}
