import '../../domain/entities/tourism_place.dart';
import '../../domain/repositories/tourism_repository.dart';
import '../datasources/tourism_remote_data_source.dart';

class TourismRepositoryImpl implements TourismRepository {
  const TourismRepositoryImpl(this._remoteDataSource);

  final TourismRemoteDataSource _remoteDataSource;

  @override
  Future<List<TourismPlace>> getPlaces() => _remoteDataSource.getPlaces();

  @override
  Future<TourismPlace> getPlaceDetail({required String id, required String slug}) =>
      _remoteDataSource.getPlaceDetail(id: id, slug: slug);
}
