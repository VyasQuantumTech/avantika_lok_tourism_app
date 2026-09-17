import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../data/datasources/provider_review_remote_data_source.dart';
import '../../domain/entities/provider_review.dart';

class ProviderReviewsPage extends StatefulWidget {
  const ProviderReviewsPage({super.key});

  @override
  State<ProviderReviewsPage> createState() => _ProviderReviewsPageState();
}

class _ProviderReviewsPageState extends State<ProviderReviewsPage> {
  final _searchController = TextEditingController();
  late Future<List<ProviderReview>> _future;
  String _sort = 'newest';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    _future = getIt<ProviderReviewRemoteDataSource>().list();
  }

  String _message(Object? error) =>
      error is ApiException ? error.message : 'Unable to load your reviews.';

  List<ProviderReview> _filtered(List<ProviderReview> source) {
    final query = _query.trim().toLowerCase();
    final values = source.where((review) {
      if (query.isEmpty) return true;
      return [
        review.title,
        review.comment,
        review.bookingNumber,
        review.serviceName,
        review.customerName,
      ].whereType<String>().any((value) => value.toLowerCase().contains(query));
    }).toList();

    values.sort((a, b) {
      switch (_sort) {
        case 'oldest':
          return (a.createdAt ?? DateTime(1970)).compareTo(b.createdAt ?? DateTime(1970));
        case 'highest':
          return b.rating.compareTo(a.rating);
        case 'lowest':
          return a.rating.compareTo(b.rating);
        default:
          return (b.createdAt ?? DateTime(1970)).compareTo(a.createdAt ?? DateTime(1970));
      }
    });
    return values;
  }

  Future<void> _respond(ProviderReview review) async {
    final text = await AppDialogs.textInput(
      context,
      title: review.hasResponse ? 'Update response' : 'Respond to review',
      label: 'Your response',
      helperText: 'Your response will be associated with this approved review.',
      confirmLabel: review.hasResponse ? 'Update response' : 'Post response',
    );
    if (text == null || text.length < 2) return;
    try {
      await getIt<ProviderReviewRemoteDataSource>().respond(review.id, text);
      if (!mounted) return;
      AppFeedback.success(context, 'Review response saved.');
      setState(_reload);
    } on ApiException catch (error) {
      if (mounted) AppFeedback.error(context, error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Ratings & Reviews',
      subtitle: 'Approved feedback received from customers',
      child: FutureBuilder<List<ProviderReview>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingView(message: 'Loading reviews…');
          }
          if (snapshot.hasError) {
            return AppErrorState(
              message: _message(snapshot.error),
              onRetry: () => setState(_reload),
            );
          }

          final all = snapshot.data ?? const <ProviderReview>[];
          final visible = _filtered(all);
          final average = all.isEmpty
              ? 0.0
              : all.fold<int>(0, (total, item) => total + item.rating) / all.length;

          return RefreshIndicator(
            onRefresh: () async {
              setState(_reload);
              await _future;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppMetricCard(
                        label: 'Average rating',
                        value: all.isEmpty ? '—' : average.toStringAsFixed(1),
                        icon: Icons.star_rounded,
                        footer: '${all.length} approved reviews',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppMetricCard(
                        label: 'Responses',
                        value: '${all.where((e) => e.hasResponse).length}',
                        icon: Icons.forum_outlined,
                        footer: 'Provider responses posted',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                AppSearchSortBar<String>(
                  controller: _searchController,
                  hintText: 'Search customer, service or review',
                  sortValue: _sort,
                  onChanged: (value) => setState(() => _query = value),
                  onSortChanged: (value) => setState(() => _sort = value ?? 'newest'),
                  sortItems: const [
                    DropdownMenuItem(value: 'newest', child: Text('Newest')),
                    DropdownMenuItem(value: 'oldest', child: Text('Oldest')),
                    DropdownMenuItem(value: 'highest', child: Text('Highest rating')),
                    DropdownMenuItem(value: 'lowest', child: Text('Lowest rating')),
                  ],
                ),
                const SizedBox(height: 18),
                if (visible.isEmpty)
                  AppEmptyState(
                    title: all.isEmpty ? 'No reviews yet' : 'No matching reviews',
                    message: all.isEmpty
                        ? 'Approved customer reviews will appear here.'
                        : 'Try a different search or sort option.',
                    icon: Icons.reviews_outlined,
                  )
                else
                  ...visible.map((review) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ReviewCard(review: review, onRespond: () => _respond(review)),
                      )),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review, required this.onRespond});

  final ProviderReview review;
  final VoidCallback onRespond;

  @override
  Widget build(BuildContext context) {
    final date = review.createdAt?.toLocal();
    final dateText = date == null
        ? null
        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primarySoft,
                foregroundColor: AppColors.primary,
                child: const Icon(Icons.person_outline_rounded),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.customerName ?? 'Customer', style: AppTypography.label),
                    if (review.serviceName != null)
                      Text(review.serviceName!, style: AppTypography.caption),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.warningSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star_rounded, color: AppColors.star, size: 16),
                    const SizedBox(width: 3),
                    Text('${review.rating}', style: AppTypography.label),
                  ],
                ),
              ),
            ],
          ),
          if (review.title != null) ...[
            const SizedBox(height: 14),
            Text(review.title!, style: AppTypography.sectionTitle),
          ],
          if (review.comment != null) ...[
            const SizedBox(height: 6),
            Text(review.comment!, style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
          ],
          if (dateText != null || review.bookingNumber != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 5,
              children: [
                if (dateText != null) Text(dateText, style: AppTypography.tiny),
                if (review.bookingNumber != null) Text('#${review.bookingNumber}', style: AppTypography.tiny),
              ],
            ),
          ],
          const SizedBox(height: 14),
          if (review.hasResponse)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.infoSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your response', style: AppTypography.label.copyWith(color: AppColors.info)),
                  const SizedBox(height: 4),
                  Text(review.response!, style: AppTypography.body),
                ],
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onRespond,
              icon: const Icon(Icons.reply_rounded),
              label: Text(review.hasResponse ? 'Update response' : 'Respond to review'),
            ),
          ),
        ],
      ),
    );
  }
}
