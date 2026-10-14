import 'api_client.dart';

/// Reads the server's pagination without truncating bookings/catalogues at page 1.
/// Resource-specific collection envelopes remain supported for older deployments.
Future<List<Map<String, dynamic>>> fetchApiCollection(
    ApiClient api, String path,
    {bool authenticated = false,
    List<String> keys = const ['items', 'results'],
    String sizeParameter = 'pageSize'}) async {
  final uri = Uri.parse(path);
  final result = <Map<String, dynamic>>[];
  final seen = <String>{};
  var page = 1;
  while (true) {
    final query = {
      ...uri.queryParameters,
      'page': '$page',
      sizeParameter: '100'
    };
    final response = await api.get(
        '${uri.path}?${Uri(queryParameters: query).query}',
        authenticated: authenticated);
    final data = response['data'] is Map
        ? Map<String, dynamic>.from(response['data'] as Map)
        : response;
    dynamic collection;
    for (final key in keys) {
      if (data[key] is List) {
        collection = data[key];
        break;
      }
    }
    final rows = collection is List
        ? collection
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList()
        : <Map<String, dynamic>>[];
    for (final row in rows) {
      final id = row['id']?.toString();
      if (id == null || seen.add(id)) result.add(row);
    }
    final pagination =
        data['pagination'] is Map ? data['pagination'] as Map : const {};
    final totalPages = int.tryParse('${pagination['totalPages'] ?? 1}') ?? 1;
    if (page >= totalPages || rows.isEmpty) break;
    page++;
  }
  return result;
}
