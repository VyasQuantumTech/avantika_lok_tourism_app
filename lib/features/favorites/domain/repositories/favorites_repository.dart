import '../entities/saved_item.dart';

abstract class FavoritesRepository {
  Future<List<SavedItem>> list();
  Future<String> save(String type, String targetId);
  Future<void> remove(String id);
}
