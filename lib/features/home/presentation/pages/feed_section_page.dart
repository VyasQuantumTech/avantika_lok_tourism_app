import 'package:flutter/material.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../domain/entities/home_dashboard.dart';
import '../../domain/usecases/get_home_dashboard.dart';
import '../widgets/feed_item_card.dart';

class FeedSectionPage extends StatefulWidget {
  const FeedSectionPage({required this.type, required this.title, super.key});
  final String type, title;
  @override
  State<FeedSectionPage> createState() => _FeedSectionPageState();
}

class _FeedSectionPageState extends State<FeedSectionPage> {
  List<HomeFeedItem> items = [];
  int page = 1;
  bool loading = false, more = true;
  Object? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load({bool reset = false}) async {
    if (loading) return;
    setState(() {
      loading = true;
      error = null;
      if (reset) {
        page = 1;
        items = [];
        more = true;
      }
    });
    try {
      final result = await getIt<GetHomeDashboard>().section(widget.type, page);
      if (!mounted) return;
      setState(() {
        items = [...items, ...result.items];
        more = result.hasNextPage;
        page++;
      });
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: RefreshIndicator(
        onRefresh: () => load(reset: true),
        child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              ...items.map((i) => FeedItemCard(item: i)),
              if (error != null)
                AppErrorState(message: 'Unable to load items.', onRetry: load),
              if (loading) const Center(child: CircularProgressIndicator()),
              if (!loading && error == null && items.isEmpty)
                const Text('No items available yet.'),
              if (!loading && error == null && more && items.isNotEmpty)
                TextButton(onPressed: load, child: const Text('Load more')),
            ]),
      ));
}
