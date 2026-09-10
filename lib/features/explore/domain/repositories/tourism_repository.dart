import '../entities/tourism_place.dart';

abstract class TourismRepository {
  Future<List<TourismPlace>> getPlaces();
  Future<TourismPlace> getPlaceDetail({required String id, required String slug});
}
