import '../../../../core/ network/api_client.dart';
import '../../../home/data/models/home_feed_model.dart';
import '../../domain/entities/saved_item.dart';

class FavoritesRemoteDataSource {
  const FavoritesRemoteDataSource(this.api);
  final ApiClient api;
  static const path = '/api/v1/profile/me/favorites';
  Future<List<SavedItem>> list() async {
    final response = await api.get(path, authenticated: true);
    return (response['data']['favorites'] as List)
        .map((f) => SavedItem(
            id: '${f['id']}',
            type: '${f['targetType']}',
            targetId: '${f['targetId']}',
            item: f['item'] is Map
                ? HomeFeedItemModel.fromJson(
                    Map<String, dynamic>.from(f['item'] as Map), api.baseUrl)
                : null))
        .toList();
  }

  Future<String> save(String type, String targetId) async {
    final response = await api.post(path,
        authenticated: true, body: {'targetType': type, 'targetId': targetId});
    return '${response['data']['favorite']['id']}';
  }

  Future<void> remove(String id) async {
    await api.delete('$path/${Uri.encodeComponent(id)}', authenticated: true);
  }
}
