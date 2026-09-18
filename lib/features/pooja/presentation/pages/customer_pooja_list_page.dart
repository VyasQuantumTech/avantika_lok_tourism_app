import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../domain/entities/pooja_entities.dart';
import '../../domain/usecases/pooja_actions.dart';

enum _PoojaSort { featured, priceLow, priceHigh, rating, name }

class CustomerPoojaListPage extends StatefulWidget {
  const CustomerPoojaListPage({super.key});

  @override
  State<CustomerPoojaListPage> createState() => _CustomerPoojaListPageState();
}

class _CustomerPoojaListPageState extends State<CustomerPoojaListPage> {
  final TextEditingController _searchController = TextEditingController();
  late Future<List<Pooja>> _future;
  _PoojaSort _sort = _PoojaSort.featured;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = getIt<CustomerPoojaActions>().list();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() => _future = getIt<CustomerPoojaActions>().list());
  }

  double? _lowestPrice(Pooja pooja) {
    if (pooja.offerings.isEmpty) return null;
    return pooja.offerings
        .map((item) => item.priceAmount)
        .reduce((a, b) => a < b ? a : b);
  }

  List<Pooja> _visible(List<Pooja> source) {
    final query = _query.trim().toLowerCase();
    final items = source.where((pooja) {
      if (query.isEmpty) return true;
      final haystack = <String>[
        pooja.name,
        pooja.shortDescription ?? '',
        pooja.description ?? '',
        ...pooja.offerings.map((offering) => offering.panditName),
        ...pooja.offerings.map((offering) => offering.city ?? ''),
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList(growable: false);

    final sorted = List<Pooja>.of(items);
    switch (_sort) {
      case _PoojaSort.featured:
        sorted.sort((a, b) {
          final featured = (b.isFeatured ? 1 : 0).compareTo(a.isFeatured ? 1 : 0);
          if (featured != 0) return featured;
          return b.reviewSummary.averageRating.compareTo(a.reviewSummary.averageRating);
        });
        break;
      case _PoojaSort.priceLow:
        sorted.sort((a, b) => (_lowestPrice(a) ?? double.infinity)
            .compareTo(_lowestPrice(b) ?? double.infinity));
        break;
      case _PoojaSort.priceHigh:
        sorted.sort((a, b) => (_lowestPrice(b) ?? -1)
            .compareTo(_lowestPrice(a) ?? -1));
        break;
      case _PoojaSort.rating:
        sorted.sort((a, b) => b.reviewSummary.averageRating
            .compareTo(a.reviewSummary.averageRating));
        break;
      case _PoojaSort.name:
        sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
    }
    return sorted;
  }

  String _price(Pooja pooja) {
    final value = _lowestPrice(pooja);
    if (value == null) return 'Price on selection';
    final currency = pooja.currency.trim().toUpperCase();
    final symbol = currency == 'INR' ? '₹' : '$currency ';
    return 'From $symbol${value.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Pooja Services',
      subtitle: 'Approved services from verified Pandits',
      actions: [
        IconButton(
          tooltip: 'My Pooja Bookings',
          onPressed: () => Navigator.of(context).pushNamed(
            RouteNames.customerPoojaBookings,
          ),
          icon: const Icon(Icons.receipt_long_outlined),
        ),
      ],
      padding: EdgeInsets.zero,
      child: FutureBuilder<List<Pooja>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingView(message: 'Finding available Poojas…');
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            return AppErrorState(
              message: error is ApiException
                  ? error.message
                  : 'Unable to load Pooja services.',
              onRetry: _reload,
            );
          }

          final allItems = snapshot.data ?? const <Pooja>[];
          if (allItems.isEmpty) {
            return AppEmptyState(
              title: 'No Poojas available',
              message: 'Approved Pooja services will appear here as soon as they are published.',
              icon: Icons.temple_hindu_outlined,
              actionLabel: 'Refresh',
              onAction: _reload,
            );
          }

          final items = _visible(allItems);
          return RefreshIndicator(
            onRefresh: () async {
              _reload();
              await _future;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              children: [
                AppSearchSortBar<_PoojaSort>(
                  controller: _searchController,
                  hintText: 'Search Pooja, Pandit or city',
                  sortValue: _sort,
                  onChanged: (value) => setState(() => _query = value),
                  onSortChanged: (value) {
                    if (value != null) setState(() => _sort = value);
                  },
                  sortItems: const [
                    DropdownMenuItem(value: _PoojaSort.featured, child: Text('Featured')),
                    DropdownMenuItem(value: _PoojaSort.priceLow, child: Text('Price ↑')),
                    DropdownMenuItem(value: _PoojaSort.priceHigh, child: Text('Price ↓')),
                    DropdownMenuItem(value: _PoojaSort.rating, child: Text('Rating')),
                    DropdownMenuItem(value: _PoojaSort.name, child: Text('Name')),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${items.length} service${items.length == 1 ? '' : 's'}',
                        style: AppTypography.caption,
                      ),
                    ),
                    if (_query.trim().isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: const Text('Clear'),
                      ),
                  ],
                ),
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 64),
                    child: AppEmptyState(
                      title: 'No matching Pooja',
                      message: 'Try another Pooja name, Pandit name or city.',
                      icon: Icons.search_off_rounded,
                    ),
                  )
                else
                  ...items.map((pooja) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _PoojaCard(
                          pooja: pooja,
                          priceLabel: _price(pooja),
                          onTap: () => Navigator.of(context).pushNamed(
                            RouteNames.poojaDetail,
                            arguments: pooja.slug.isNotEmpty ? pooja.slug : pooja.id,
                          ),
                        ),
                      )),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PoojaCard extends StatelessWidget {
  const _PoojaCard({
    required this.pooja,
    required this.priceLabel,
    required this.onTap,
  });

  final Pooja pooja;
  final String priceLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 92,
              height: 104,
              child: pooja.coverUrl?.trim().isNotEmpty == true
                  ? Image.network(
                      pooja.coverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallback(),
                    )
                  : _fallback(),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(pooja.name, style: AppTypography.sectionTitle)),
                    if (pooja.isFeatured)
                      const AppStatusChip(label: 'Featured', tone: AppStatusTone.info),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  pooja.shortDescription?.trim().isNotEmpty == true
                      ? pooja.shortDescription!
                      : 'Choose a verified Pandit and a convenient slot.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption,
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Icon(Icons.star_rounded, size: 17, color: AppColors.star),
                    const SizedBox(width: 4),
                    Text(
                      pooja.reviewSummary.count == 0
                          ? 'New'
                          : '${pooja.reviewSummary.averageRating.toStringAsFixed(1)} (${pooja.reviewSummary.count})',
                      style: AppTypography.label,
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.person_outline_rounded, size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        '${pooja.offerings.length} Pandit${pooja.offerings.length == 1 ? '' : 's'}',
                        style: AppTypography.caption,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        priceLabel,
                        style: AppTypography.label.copyWith(color: AppColors.primary),
                      ),
                    ),
                    Icon(Icons.arrow_forward_rounded, size: 19, color: AppColors.primary),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback() => Container(
        color: AppColors.primarySoft,
        alignment: Alignment.center,
        child: Icon(Icons.temple_hindu_outlined, color: AppColors.primary, size: 38),
      );
}
