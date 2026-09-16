import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/pooja_entities.dart';
import '../../domain/usecases/pooja_actions.dart';

class CustomerPoojaDetailPage extends StatefulWidget {
  const CustomerPoojaDetailPage({required this.identifier, super.key});
  final String identifier;

  @override
  State<CustomerPoojaDetailPage> createState() => _CustomerPoojaDetailPageState();
}

class _CustomerPoojaDetailPageState extends State<CustomerPoojaDetailPage> {
  late Future<Pooja> _future;
  final PageController _galleryController = PageController();
  int _galleryIndex = 0;

  @override
  void initState() {
    super.initState();
    _future = getIt<CustomerPoojaActions>().detail(widget.identifier);
  }

  @override
  void dispose() {
    _galleryController.dispose();
    super.dispose();
  }

  List<String> _gallery(Pooja pooja) {
    final urls = <String>[];
    for (final media in pooja.media) {
      final url = media.url.trim();
      if (url.isNotEmpty && !urls.contains(url)) urls.add(url);
    }
    final cover = pooja.coverUrl?.trim();
    if (cover != null && cover.isNotEmpty && !urls.contains(cover)) {
      urls.insert(0, cover);
    }
    return urls;
  }

  Widget _buildGallery(Pooja pooja) {
    final images = _gallery(pooja);
    if (images.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: PageView.builder(
              controller: _galleryController,
              itemCount: images.length,
              onPageChanged: (value) => setState(() => _galleryIndex = value),
              itemBuilder: (context, index) => Image.network(
                images[index],
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  alignment: Alignment.center,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.broken_image_outlined, size: 42),
                ),
              ),
            ),
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              images.length,
              (index) => Container(
                width: index == _galleryIndex ? 18 : 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  color: index == _galleryIndex
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReviewSummary(Pooja pooja) {
    final summary = pooja.reviewSummary;
    if (summary.count <= 0) {
      return const Row(
        children: [
          Icon(Icons.star_border_rounded, size: 20),
          SizedBox(width: 6),
          Text('No reviews yet'),
        ],
      );
    }
    return Row(
      children: [
        const Icon(Icons.star_rounded, color: Colors.amber, size: 22),
        const SizedBox(width: 5),
        Text(
          summary.averageRating.toStringAsFixed(1),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 5),
        Text('(${summary.count} ${summary.count == 1 ? 'review' : 'reviews'})'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Pooja>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          final error = snapshot.error;
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  error is ApiException
                      ? error.message
                      : 'Unable to load pooja details.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final pooja = snapshot.data!;
        return Scaffold(
          appBar: AppBar(title: Text(pooja.name)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildGallery(pooja),
              if (_gallery(pooja).isNotEmpty) const SizedBox(height: 14),
              Text(
                pooja.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              _buildReviewSummary(pooja),
              if (pooja.description?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Text(pooja.description!),
              ],
              const SizedBox(height: 20),
              const Text(
                'Available Pandits',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (pooja.offerings.isEmpty)
                const Text('No approved Pandit offering is currently available.')
              else
                ...pooja.offerings.map(
                  (offering) => Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.brandSoft,
                        child: Icon(Icons.person, color: AppColors.primary),
                      ),
                      title: Text(offering.panditName),
                      subtitle: Text(
                        [
                          if (offering.city?.isNotEmpty == true) offering.city!,
                          if (offering.state?.isNotEmpty == true) offering.state!,
                          offering.serviceMode,
                          if (offering.durationMinutes != null)
                            '${offering.durationMinutes} min',
                        ].join(' • '),
                      ),
                      trailing: Text(
                        '₹${offering.priceAmount.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      onTap: () => Navigator.of(context).pushNamed(
                        RouteNames.poojaBooking,
                        arguments: <String, dynamic>{
                          'pooja': pooja,
                          'offering': offering,
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
