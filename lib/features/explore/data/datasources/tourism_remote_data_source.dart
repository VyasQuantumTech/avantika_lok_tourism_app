import '../../../../core/ network/api_client.dart';
import '../../../../core/ network/endpoints.dart';
import '../models/tourism_place_model.dart';

abstract class TourismRemoteDataSource {
  Future<List<TourismPlaceModel>> getPlaces();
  Future<TourismPlaceModel> getPlaceDetail({required String id, required String slug});
}

class TourismRemoteDataSourceImpl implements TourismRemoteDataSource {
  const TourismRemoteDataSourceImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<TourismPlaceModel>> getPlaces() async {
    final json = await _apiClient.get('${Endpoints.tourismPlaces}?limit=100');
    final items = _extractList(json);
    return items
        .map((item) => TourismPlaceModel.fromJson(item, baseUrl: _apiClient.baseUrl))
        .toList(growable: false);
  }

  @override
  Future<TourismPlaceModel> getPlaceDetail({required String id, required String slug}) async {
    final candidates = <String>[
      if (slug.trim().isNotEmpty) slug.trim(),
      if (id.trim().isNotEmpty && id.trim() != slug.trim()) id.trim(),
    ];

    Object? lastError;
    for (final value in candidates) {
      try {
        final json = await _apiClient.get('${Endpoints.tourismPlaces}/$value');
        return TourismPlaceModel.fromJson(_extractObject(json), baseUrl: _apiClient.baseUrl);
      } catch (error) {
        lastError = error;
      }
    }

    throw lastError ?? StateError('Unable to load place details.');
  }

  List<Map<String, dynamic>> _extractList(Map<String, dynamic> json) {
    final dynamic data = json['data'];
    if (data is List) return _asMapList(data);
    if (data is Map) {
      final dataMap = _asMap(data);
      for (final key in const ['items', 'places', 'results', 'rows']) {
        if (dataMap[key] is List) return _asMapList(dataMap[key] as List);
      }
    }
    for (final key in const ['items', 'places', 'results', 'rows']) {
      if (json[key] is List) return _asMapList(json[key] as List);
    }
    return const <Map<String, dynamic>>[];
  }

  Map<String, dynamic> _extractObject(Map<String, dynamic> json) {
    final dynamic data = json['data'];
    if (data is Map) {
      final dataMap = _asMap(data);
      if (dataMap['place'] is Map) return _asMap(dataMap['place']);
      return dataMap;
    }
    if (json['place'] is Map) return _asMap(json['place']);
    return json;
  }

  List<Map<String, dynamic>> _asMapList(List<dynamic> items) => items
      .whereType<Map>()
      .map(_asMap)
      .toList(growable: false);

  Map<String, dynamic> _asMap(Map<dynamic, dynamic> value) =>
      value.map((key, item) => MapEntry(key.toString(), item));
}
