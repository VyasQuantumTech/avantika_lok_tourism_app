import '../../../../core/widgets/temple_surface.dart';
import 'package:flutter/material.dart';
import '../../../../app/di/injection.dart';
import '../../domain/usecases/get_home_dashboard.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../favorites/presentation/favorite_button.dart';
import '../../../marketplace/presentation/marketplace_pages.dart';
import '../../../marketplace/domain/entities/marketplace_entities.dart';
import '../../../pooja/presentation/pages/customer_pooja_detail_page.dart';
import '../../../explore/domain/usecases/get_tourism_place_detail.dart';
import '../../../explore/presentation/pages/explore_detail_page.dart';
import '../../domain/entities/home_dashboard.dart';

Future<void> openFeedItem(BuildContext context, HomeFeedItem item) async {
  try {
    Widget page;
    if (item.type == 'pooja') {
      page = CustomerPoojaDetailPage(identifier: item.id);
    } else if (item.type == 'accommodation' || item.type == 'transport') {
      page = CustomerMarketplaceDetailPage(
          type: item.type == 'accommodation'
              ? MarketplaceType.accommodation
              : MarketplaceType.transport,
          identifier: item.id);
    } else if (item.type == 'place') {
      final place =
          await getIt<GetTourismPlaceDetail>()(id: item.id, slug: item.slug);
      page = ExploreDetailPage(initialPlace: place);
    } else if (item.type == 'package') {
      page = CustomerPackagePage(id: item.id);
    } else {
      page = TempleScaffold(
          appBar: AppBar(flexibleSpace: const TempleAppBarBackground(),title: Text(item.title)),
          body: SingleChildScrollView(
              padding: const EdgeInsets.all(20), child: Text(item.summary)));
    }
    if (context.mounted) {
      await Navigator.push(
          context, MaterialPageRoute<void>(builder: (_) => page));
    }
  } catch (_) {
    if (context.mounted) {
      AppFeedback.error(context, 'This item is currently unavailable.');
    }
  }
}

class FeedItemCard extends StatelessWidget {
  const FeedItemCard({required this.item, super.key});
  final HomeFeedItem item;
  @override
  Widget build(BuildContext context) => Card(
          child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: SizedBox(
            width: 64,
            height: 64,
            child: item.imageUrl.isEmpty
                ? const Icon(Icons.image_outlined)
                : Image.network(item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.image_not_supported_outlined))),
        title: Text(item.title),
        subtitle:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (item.location.isNotEmpty) Text(item.location),
          if (item.summary.isNotEmpty)
            Text(item.summary, maxLines: 2, overflow: TextOverflow.ellipsis),
          if (item.prices.isNotEmpty) Text('From ${item.prices.join(' / ')}'),
          if (item.eventAt != null) Text(item.eventAt!.toLocal().toString()),
        ]),
        trailing: item.canSave
            ? FavoriteButton(type: item.type, targetId: item.id)
            : const Icon(Icons.chevron_right),
        onTap: () => openFeedItem(context, item),
      ));
}

class CustomerPackagePage extends StatefulWidget {
  const CustomerPackagePage({required this.id, super.key});
  final String id;
  @override
  State<CustomerPackagePage> createState() => _CustomerPackagePageState();
}

class _CustomerPackagePageState extends State<CustomerPackagePage> {
  late Future<HomePackageDetail> future;
  @override
  void initState() {
    super.initState();
    load();
  }

  void load() {
    future = getIt<GetHomeDashboard>().package(widget.id);
  }

  @override
  Widget build(BuildContext context) => TempleScaffold(
      appBar: AppBar(flexibleSpace: const TempleAppBarBackground(),
          title: const Text('Package'),
          actions: [FavoriteButton(type: 'package', targetId: widget.id)]),
      body: FutureBuilder<HomePackageDetail>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return AppErrorState(
                  message: 'Package unavailable.',
                  onRetry: () => setState(load));
            }
            if (!snapshot.hasData) return const AppLoadingView();
            final p = snapshot.data!;
            return ListView(padding: const EdgeInsets.all(20), children: [
              Text(p.title, style: Theme.of(context).textTheme.headlineSmall),
              Text('${p.durationDays} days • ${p.durationNights} nights'),
              Text(p.description),
              if (p.inclusions.isNotEmpty)
                Text('Included: ${p.inclusions.join(', ')}'),
              if (p.exclusions.isNotEmpty)
                Text('Excluded: ${p.exclusions.join(', ')}'),
              ...p.itinerary.map((day) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(day))),
              ...p.prices.map((price) => Text(price)),
            ]);
          }));
}
