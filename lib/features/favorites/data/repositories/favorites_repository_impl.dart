import '../../domain/entities/saved_item.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../datasources/favorites_remote_data_source.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  const FavoritesRepositoryImpl(this.remote);
  final FavoritesRemoteDataSource remote;
  @override
  Future<List<SavedItem>> list() => remote.list();
  @override
  Future<String> save(String type, String id) => remote.save(type, id);
  @override
  Future<void> remove(String id) => remote.remove(id);
}
