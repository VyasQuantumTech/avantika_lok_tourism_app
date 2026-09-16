import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/pooja_entities.dart';
import '../../domain/usecases/pooja_actions.dart';

class CustomerPoojaListPage extends StatefulWidget {
  const CustomerPoojaListPage({super.key});

  @override
  State<CustomerPoojaListPage> createState() => _CustomerPoojaListPageState();
}

class _CustomerPoojaListPageState extends State<CustomerPoojaListPage> {
  late Future<List<Pooja>> _future;

  @override
  void initState() {
    super.initState();
    _future = getIt<CustomerPoojaActions>().list();
  }

  void _reload() {
    final next = getIt<CustomerPoojaActions>().list();
    setState(() { _future = next; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pooja Services'),
        actions: [
          IconButton(
            tooltip: 'My Pooja Bookings',
            onPressed: () => Navigator.of(context).pushNamed(
              RouteNames.customerPoojaBookings,
            ),
            icon: const Icon(Icons.receipt_long_outlined),
          ),
        ],
      ),
      body: FutureBuilder<List<Pooja>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            final message = error is ApiException
                ? error.message
                : 'Unable to load pooja services.';
            return _MessageState(message: message, onRetry: _reload);
          }
          final items = snapshot.data ?? const <Pooja>[];
          if (items.isEmpty) {
            return const _MessageState(
              message: 'No approved pooja services are available right now.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              _reload();
              await _future;
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final pooja = items[index];
                final lowest = pooja.offerings.isEmpty
                    ? null
                    : pooja.offerings
                        .map((e) => e.priceAmount)
                        .reduce((a, b) => a < b ? a : b);
                return Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.of(context).pushNamed(
                      RouteNames.poojaDetail,
                      arguments: pooja.slug.isNotEmpty ? pooja.slug : pooja.id,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: AppColors.brandSoft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: pooja.coverUrl == null
                                ? Icon(
                                    Icons.temple_hindu_outlined,
                                    color: AppColors.primary,
                                    size: 34,
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      pooja.coverUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Icon(
                                        Icons.temple_hindu_outlined,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pooja.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  pooja.shortDescription ??
                                      'Choose an approved Pandit and book your preferred slot.',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  lowest == null
                                      ? '${pooja.offerings.length} Pandit options'
                                      : 'From ₹${lowest.toStringAsFixed(0)} • ${pooja.offerings.length} Pandit options',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.temple_hindu_outlined, size: 48),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 14),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ],
      ),
    ),
  );
}
