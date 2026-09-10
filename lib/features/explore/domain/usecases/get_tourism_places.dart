import '../entities/tourism_place.dart';
import '../repositories/tourism_repository.dart';

class GetTourismPlaces {
  const GetTourismPlaces(this._repository);

  final TourismRepository _repository;

  Future<List<TourismPlace>> call() => _repository.getPlaces();
}
