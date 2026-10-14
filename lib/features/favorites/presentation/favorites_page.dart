import '../../../core/widgets/temple_surface.dart';
import 'package:flutter/material.dart';
import '../../../app/di/injection.dart';
import '../../../core/widgets/app_ui.dart';
import '../../home/presentation/widgets/feed_item_card.dart';
import 'favorites_controller.dart';
import 'favorite_button.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});
  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  static const types = [
    'pooja',
    'accommodation',
    'transport',
    'package',
    'place'
  ];
  @override
  void initState() {
    super.initState();
    getIt<FavoritesController>().load();
  }

  @override
  Widget build(BuildContext context) {
    final c = getIt<FavoritesController>();
    return DefaultTabController(
        length: types.length,
        child: TempleScaffold(
          appBar: AppBar(flexibleSpace: const TempleAppBarBackground(),
              title: const Text('Favourites'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => c.load(force: true))
              ],
              bottom: const TabBar(isScrollable: true, tabs: [
                Tab(text: 'Pooja'),
                Tab(text: 'Accommodation'),
                Tab(text: 'Transport'),
                Tab(text: 'Packages'),
                Tab(text: 'Places')
              ])),
          body: ListenableBuilder(
              listenable: c,
              builder: (_, __) {
                if (c.error != null) {
                  return AppErrorState(
                      message: 'Unable to load favourites.',
                      onRetry: () => c.load(force: true));
                }
                if (!c.loaded) return const AppLoadingView();
                return TabBarView(
                    children: types.map((type) {
                  final rows = c.items.where((f) => f.type == type).toList();
                  return RefreshIndicator(
                      onRefresh: () => c.load(force: true),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (rows.isEmpty)
                            const Padding(
                                padding: EdgeInsets.all(30),
                                child: Text(
                                    'No favourites saved in this category yet.')),
                          for (final f in rows)
                            if (f.item != null)
                              FeedItemCard(item: f.item!)
                            else
                              Card(
                                  child: ListTile(
                                      title: const Text(
                                          'Item currently unavailable'),
                                      subtitle: const Text(
                                          'You can remove it from your favourites.'),
                                      trailing: FavoriteButton(
                                          type: f.type, targetId: f.targetId))),
                        ],
                      ));
                }).toList());
              }),
        ));
  }
}
