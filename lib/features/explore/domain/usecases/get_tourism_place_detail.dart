import '../entities/tourism_place.dart';
import '../repositories/tourism_repository.dart';

class GetTourismPlaceDetail {
  const GetTourismPlaceDetail(this._repository);

  final TourismRepository _repository;

  Future<TourismPlace> call({required String id, required String slug}) =>
      _repository.getPlaceDetail(id: id, slug: slug);
}
