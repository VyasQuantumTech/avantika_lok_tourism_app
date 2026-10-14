import '../../domain/entities/home_dashboard.dart';
import '../../../../core/utils/media_urls.dart';

class HomeFeedItemModel extends HomeFeedItem {
  const HomeFeedItemModel(
      {required super.id,
      required super.type,
      required super.title,
      super.slug,
      super.summary,
      super.imageUrl,
      super.location,
      super.prices,
      super.eventAt,
      super.favoriteId});
  factory HomeFeedItemModel.fromJson(
          Map<String, dynamic> json, String baseUrl) =>
      HomeFeedItemModel(
        id: '${json['id']}',
        type: '${json['type']}',
        title: '${json['title'] ?? ''}',
        slug: '${json['slug'] ?? json['id']}',
        summary: '${json['summary'] ?? ''}',
        imageUrl: resolveMediaUrl('${json['imageUrl'] ?? ''}', baseUrl),
        location: '${json['location'] ?? ''}',
        favoriteId: json['favoriteId'] as String?,
        eventAt: DateTime.tryParse('${json['eventAt'] ?? ''}'),
        prices: (json['fromPrices'] as List? ?? [])
            .whereType<Map>()
            .map((p) => '${p['currency']} ${p['amount']}')
            .toList(),
      );
}
