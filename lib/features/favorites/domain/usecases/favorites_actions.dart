import '../entities/saved_item.dart';
import '../repositories/favorites_repository.dart';

class FavoritesActions {
  const FavoritesActions(this.repository);
  final FavoritesRepository repository;
  Future<List<SavedItem>> list() => repository.list();
  Future<String> save(String type, String id) => repository.save(type, id);
  Future<void> remove(String id) => repository.remove(id);
}
