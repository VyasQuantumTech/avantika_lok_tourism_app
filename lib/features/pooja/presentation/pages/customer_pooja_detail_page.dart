import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/widgets/app_ui.dart';
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
    _load();
  }

  void _load() {
    _future = getIt<CustomerPoojaActions>().detail(widget.identifier);
  }

  @override
  void dispose() {
    _galleryController.dispose();
    super.dispose();
  }

  List<String> _gallery(Pooja pooja) {
    final urls = <String>[];
    final cover = pooja.coverUrl?.trim();
    if (cover != null && cover.isNotEmpty) urls.add(cover);
    for (final media in pooja.media) {
      final url = media.url.trim();
      if (url.isNotEmpty && !urls.contains(url)) urls.add(url);
    }
    return urls;
  }

  String _money(double amount, String currency) {
    final code = currency.trim().toUpperCase();
    return '${code == 'INR' ? '₹' : '$code '}${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Pooja>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppPage(
            title: 'Pooja Details',
            child: AppLoadingView(message: 'Loading Pooja details…'),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          final error = snapshot.error;
          return AppPage(
            title: 'Pooja Details',
            child: AppErrorState(
              message: error is ApiException ? error.message : 'Unable to load Pooja details.',
              onRetry: () => setState(_load),
            ),
          );
        }

        final pooja = snapshot.data!;
        final images = _gallery(pooja);
        return AppPage(
          title: pooja.name,
          subtitle: 'Choose your preferred verified Pandit',
          padding: EdgeInsets.zero,
          child: RefreshIndicator(
            onRefresh: () async {
              setState(_load);
              await _future;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
              children: [
                if (images.isNotEmpty) _Gallery(
                  images: images,
                  controller: _galleryController,
                  currentIndex: _galleryIndex,
                  onChanged: (value) => setState(() => _galleryIndex = value),
                ) else
                  Container(
                    height: 190,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.temple_hindu_outlined, size: 64, color: AppColors.primary),
                  ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(pooja.name, style: AppTypography.titleLarge)),
                    if (pooja.isFeatured)
                      const AppStatusChip(label: 'Featured', tone: AppStatusTone.info),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      pooja.reviewSummary.count > 0 ? Icons.star_rounded : Icons.star_border_rounded,
                      color: AppColors.star,
                      size: 20,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      pooja.reviewSummary.count > 0
                          ? '${pooja.reviewSummary.averageRating.toStringAsFixed(1)} • ${pooja.reviewSummary.count} review${pooja.reviewSummary.count == 1 ? '' : 's'}'
                          : 'No reviews yet',
                      style: AppTypography.label,
                    ),
                    const Spacer(),
                    if (pooja.defaultDurationMinutes != null)
                      Text('${pooja.defaultDurationMinutes} min', style: AppTypography.caption),
                  ],
                ),
                if (pooja.shortDescription?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 14),
                  Text(pooja.shortDescription!, style: AppTypography.body),
                ],
                if (pooja.description?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 18),
                  const AppSectionTitle(title: 'About this Pooja'),
                  const SizedBox(height: 8),
                  Text(pooja.description!, style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
                ],
                const SizedBox(height: 22),
                AppSectionTitle(
                  title: 'Available Pandits',
                  subtitle: pooja.offerings.isEmpty
                      ? 'No approved offering is available right now.'
                      : '${pooja.offerings.length} approved option${pooja.offerings.length == 1 ? '' : 's'}',
                ),
                const SizedBox(height: 10),
                if (pooja.offerings.isEmpty)
                  const AppEmptyState(
                    title: 'No Pandit available',
                    message: 'Please check this Pooja again later.',
                    icon: Icons.person_search_outlined,
                  )
                else
                  ...pooja.offerings.map((offering) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppPanel(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppColors.primarySoft,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.person_outline_rounded, color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 11),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(offering.panditName, style: AppTypography.sectionTitle),
                                        const SizedBox(height: 2),
                                        Text(
                                          [
                                            if (offering.city?.trim().isNotEmpty == true) offering.city!,
                                            if (offering.state?.trim().isNotEmpty == true) offering.state!,
                                          ].join(', '),
                                          style: AppTypography.caption,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    _money(offering.priceAmount, offering.currency),
                                    style: AppTypography.title.copyWith(color: AppColors.primary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  AppStatusChip(label: offering.serviceMode),
                                  if (offering.durationMinutes != null)
                                    AppStatusChip(label: '${offering.durationMinutes} min'),
                                  if (offering.approvalStatus?.trim().isNotEmpty == true)
                                    AppStatusChip(label: offering.approvalStatus!),
                                ],
                              ),
                              const SizedBox(height: 13),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: () => Navigator.of(context).pushNamed(
                                    RouteNames.poojaBooking,
                                    arguments: <String, dynamic>{'pooja': pooja, 'offering': offering},
                                  ),
                                  icon: const Icon(Icons.calendar_month_outlined),
                                  label: const Text('Choose Date & Book'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Gallery extends StatelessWidget {
  const _Gallery({
    required this.images,
    required this.controller,
    required this.currentIndex,
    required this.onChanged,
  });

  final List<String> images;
  final PageController controller;
  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 230,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: PageView.builder(
              controller: controller,
              itemCount: images.length,
              onPageChanged: onChanged,
              itemBuilder: (context, index) => Image.network(
                images[index],
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  alignment: Alignment.center,
                  color: AppColors.primarySoft,
                  child: Icon(Icons.broken_image_outlined, size: 42, color: AppColors.primary),
                ),
              ),
            ),
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 9),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              images.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: index == currentIndex ? 20 : 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: index == currentIndex ? AppColors.primary : AppColors.border,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
