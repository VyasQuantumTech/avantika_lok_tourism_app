import '../../../../core/utils/media_urls.dart';
import '../../../../core/ network/api_collection.dart';
import '../../../bookings/data/models/booking_lifecycle_model.dart';
import 'dart:typed_data';

import '../../../../core/ network/api_client.dart';
import '../../../../core/ network/endpoints.dart';
import '../../domain/entities/marketplace_entities.dart';

abstract class MarketplaceRemoteDataSource {
  Future<List<MarketplaceItem>> publicItems(MarketplaceType type, {String? query});
  Future<MarketplaceItem> publicDetail(MarketplaceType type, String id);
  Future<AccommodationAvailabilityQuote> accommodationAvailability({
    required String identifier,
    required String checkIn,
    required String checkOut,
    required int adults,
    required int children,
    required int units,
  });

  Future<TransportAvailabilityQuote> transportAvailability({required String vehicleId, required String date, required String startTime, required String endTime, required int passengers, String? routeId});
  Future<String> uploadDocument({required Uint8List bytes, required String fileName, required String mimeType});

  Future<List<MarketplaceBooking>> customerBookings(MarketplaceType type);
  Future<MarketplaceBooking> bookingDetail(String id, {bool provider = false});
  Future<MarketplaceBooking> createBooking(MarketplaceType type, Map<String, dynamic> body);
  Future<void> customerBookingAction(String id, String action, {Map<String, dynamic>? body});
  Future<void> createReview({required String bookingId, required int rating, required String comment, String? title});
  Future<String> uploadImage({required Uint8List bytes, required String fileName, required String mimeType});

  Future<List<MarketplaceItem>> providerItems(MarketplaceType type);
  Future<MarketplaceItem> providerItem(MarketplaceType type, String id);
  Future<MarketplaceItem> saveAccommodation(Map<String, dynamic> body, {String? id});
  Future<void> deleteAccommodation(String id);
  Future<Map<String, dynamic>> saveAccommodationUnit(String accommodationId, Map<String, dynamic> body, {String? unitId});
  Future<void> deleteAccommodationUnit(String unitId);
  Future<Map<String, dynamic>> upsertInventory(String unitId, Map<String, dynamic> body);
  Future<Map<String, dynamic>> saveRate(String unitId, Map<String, dynamic> body, {String? rateId});
  Future<void> deleteRate(String rateId);
  Future<void> submitAccommodation(String id, {Map<String, dynamic>? body});
  Future<Map<String, dynamic>> accommodationOperation(String operation, String id, Map<String, dynamic> body);

  Future<Map<String, dynamic>> transportProfile();
  Future<Map<String, dynamic>> saveTransportProfile(Map<String, dynamic> body);
  Future<Map<String, dynamic>> saveVehicle(Map<String, dynamic> body, {String? id});
  Future<void> deleteVehicle(String id);
  Future<Map<String, dynamic>> saveVehicleDocument(String vehicleId, Map<String, dynamic> body, {String? documentId});
  Future<void> deleteVehicleDocument(String vehicleId, String documentId);
  Future<Map<String, dynamic>> upsertVehicleAvailability(String vehicleId, Map<String, dynamic> body);
  Future<Map<String, dynamic>> saveVehiclePricing(String vehicleId, Map<String, dynamic> body, {String? pricingId});
  Future<void> deleteVehiclePricing(String vehicleId, String pricingId);
  Future<Map<String, dynamic>> saveRoute(Map<String, dynamic> body, {String? routeId});
  Future<void> deleteRoute(String routeId);
  Future<void> submitVehicle(String id);

  Future<Map<String, dynamic>> transportOperation(String operation, {String? id, Map<String, dynamic>? body});
  Future<List<MarketplaceBooking>> providerBookings(MarketplaceType type);
  Future<MarketplaceBooking> providerBookingAction(MarketplaceType type, String id, String action, {Map<String, dynamic>? body});
}

class MarketplaceRemoteDataSourceImpl implements MarketplaceRemoteDataSource {
  const MarketplaceRemoteDataSourceImpl(this.api);
  final ApiClient api;

  MarketplaceItem _item(MarketplaceType type, Map<String, dynamic> raw) =>
      MarketplaceItem(type: type, raw: normalizeMediaUrls(raw, api.baseUrl));

  String _public(MarketplaceType type) => type == MarketplaceType.accommodation ? Endpoints.accommodations : Endpoints.transport;
  String _provider(MarketplaceType type) => type == MarketplaceType.accommodation ? Endpoints.providerAccommodations : Endpoints.providerTransport;

  @override
  Future<List<MarketplaceItem>> publicItems(MarketplaceType type, {String? query}) async {
    final clean = query?.trim();
    final params = <String>['page=1', 'limit=100'];
    if (clean != null && clean.isNotEmpty) params.add('q=${Uri.encodeQueryComponent(clean)}');
    final items = await fetchApiCollection(api, '${_public(type)}?${params.join('&')}', sizeParameter: 'limit', keys: ['items', 'results', 'accommodations', 'vehicles']);
    if (type != MarketplaceType.transport) {
      return items.map((e) => _item(type, e)).toList();
    }

    // Public transport returns provider profiles containing approved vehicles.
    // Flatten them for the existing marketplace list instead of introducing a
    // second transport discovery flow.
    final vehicles = <MarketplaceItem>[];
    for (final profile in items) {
      final routes = _maps(profile['routes']);
      final provider = profile['providerProfile'] ?? profile['provider_profile'];
      for (final vehicle in _maps(profile['vehicles'])) {
        final raw = <String, dynamic>{...vehicle};
        raw['routes'] = routes;
        raw['transportProvider'] = profile;
        if (provider is Map) {
          raw['city'] ??= provider['city'];
          raw['state'] ??= provider['state'];
          raw['providerDisplayName'] ??= provider['displayName'] ?? provider['display_name'];
        }
        vehicles.add(_item(type, raw));
      }
    }
    return vehicles;
  }

  @override
  Future<MarketplaceItem> publicDetail(MarketplaceType type, String id) async {
    final path = type == MarketplaceType.transport
        ? '${Endpoints.transport}/vehicles/${Uri.encodeComponent(id)}'
        : '${Endpoints.accommodations}/${Uri.encodeComponent(id)}';
    final response = await api.get(path);
    final raw = _object(response, type == MarketplaceType.transport ? 'vehicle' : 'accommodation');
    if (type == MarketplaceType.transport) {
      final pricing = _maps(raw['pricing']);
      final provider = raw['transportProviderProfile'] ?? raw['transport_provider_profile'];
      final routes = provider is Map ? _maps(provider['routes']) : <Map<String, dynamic>>[];
      for (final price in pricing) {
        final route = price['route'];
        if (route is Map) {
          final normalized = route.map((key, value) => MapEntry('$key', value));
          final id = '${normalized['id'] ?? ''}';
          if (id.isNotEmpty && !routes.any((item) => '${item['id'] ?? ''}' == id)) routes.add(normalized);
        }
      }
      raw['routes'] = routes;
      if (provider is Map) {
        final providerProfile = provider['providerProfile'] ?? provider['provider_profile'];
        if (providerProfile is Map) {
          raw['city'] ??= providerProfile['city'];
          raw['state'] ??= providerProfile['state'];
        }
      }
    }
    return _item(type, raw);
  }

  @override
  Future<AccommodationAvailabilityQuote> accommodationAvailability({required String identifier, required String checkIn, required String checkOut, required int adults, required int children, required int units}) async {
    final path = '${Endpoints.accommodations}/${Uri.encodeComponent(identifier)}/availability'
        '?checkIn=${Uri.encodeQueryComponent(checkIn)}'
        '&checkOut=${Uri.encodeQueryComponent(checkOut)}'
        '&adults=$adults&children=$children&units=$units';
    final response = await api.get(path);
    final data = _data(response);
    final quote = data['availability'] is Map
        ? (data['availability'] as Map).map((k, v) => MapEntry('$k', v))
        : data;
    return AccommodationAvailabilityQuote(quote);
  }

  MarketplaceBooking _booking(Map<String, dynamic> json) => MarketplaceBooking(normalizeMediaUrls(json, api.baseUrl), lifecycle: bookingLifecycleFromJson(json));

  @override
  Future<TransportAvailabilityQuote> transportAvailability({required String vehicleId, required String date, required String startTime, required String endTime, required int passengers, String? routeId}) async {
    final query = Uri(queryParameters: {'date': date, 'startTime': startTime, 'endTime': endTime,
      'passengers': '$passengers', if (routeId?.isNotEmpty == true) 'routeId': routeId!}).query;
    return TransportAvailabilityQuote(_data(await api.get('${Endpoints.transport}/vehicles/${Uri.encodeComponent(vehicleId)}/availability?$query')));
  }

  @override
  Future<String> uploadDocument({required Uint8List bytes, required String fileName, required String mimeType}) async {
    final response = await api.postBytes(Endpoints.media, bytes: bytes, contentType: _mime(mimeType, fileName),
      authenticated: true, headers: {'x-file-name': fileName, 'x-media-visibility': 'private'});
    final data = _data(response);
    final asset = data['media'] ?? data['asset'] ?? data;
    final mediaAssetId = asset is Map ? asset['id'] : null;
    if (mediaAssetId == null || '$mediaAssetId'.isEmpty) throw const FormatException('Private upload returned no media id.');
    return '$mediaAssetId';
  }

  @override
  Future<List<MarketplaceBooking>> customerBookings(MarketplaceType type) async {
    final items = await fetchApiCollection(api, '${Endpoints.bookings}?bookingType=${type.apiValue}', authenticated: true, keys: ['items', 'results', 'bookings']);
    return items
        .map(_booking)
        .where((booking) => _matchesType(booking, type))
        .toList();
  }

  @override
  Future<MarketplaceBooking> bookingDetail(String id, {bool provider = false}) async {
    final response = await api.get('${provider ? Endpoints.providerBookings : Endpoints.bookings}/$id', authenticated: true);
    return _booking(_object(response, 'booking'));
  }

  @override
  Future<MarketplaceBooking> createBooking(MarketplaceType type, Map<String, dynamic> body) async {
    final response = await api.post(
      Endpoints.bookings,
      authenticated: true,
      body: <String, dynamic>{'bookingType': type.apiValue, ...body},
    );
    return _booking(_object(response, 'booking'));
  }

  @override
  Future<void> customerBookingAction(String id, String action, {Map<String, dynamic>? body}) async {
    await api.post('${Endpoints.bookings}/$id/$action', authenticated: true, body: body);
  }

  @override
  Future<void> createReview({required String bookingId, required int rating, required String comment, String? title}) async {
    await api.post(
      Endpoints.reviews,
      authenticated: true,
      body: <String, dynamic>{
        'bookingId': bookingId,
        'rating': rating,
        'comment': comment.trim(),
        if (title?.trim().isNotEmpty == true) 'title': title!.trim(),
      },
    );
  }

  @override
  Future<String> uploadImage({required Uint8List bytes, required String fileName, required String mimeType}) async {
    final response = await api.postBytes(
      Endpoints.media,
      bytes: bytes,
      contentType: _mime(mimeType, fileName),
      authenticated: true,
      headers: <String, String>{
        'x-file-name': fileName,
        'x-media-visibility': 'public',
      },
    );
    final data = _data(response);
    final nested = data['media'] ?? data['asset'];
    final id = nested is Map ? nested['id'] : data['id'] ?? data['media_id'] ?? data['mediaId'];
    if (id == null || '$id'.trim().isEmpty) {
      throw const FormatException('Media upload succeeded but no media id was returned.');
    }
    return '$id';
  }

  @override
  Future<List<MarketplaceItem>> providerItems(MarketplaceType type) async {
    if (type == MarketplaceType.accommodation) {
      final rows = await fetchApiCollection(api, _provider(type), authenticated: true, sizeParameter: 'limit', keys: ['items', 'accommodations', 'results']);
      return rows.map((row) => _item(type, row)).toList();
    }
    final response = await api.get(_provider(type), authenticated: true);
    if (type == MarketplaceType.transport) {
      final data = _data(response);
      final profile = data['transportProviderProfile'];
      if (profile is! Map) return const <MarketplaceItem>[];
      final normalizedProfile = profile.map((key, value) => MapEntry('$key', value));
      final routes = _maps(normalizedProfile['routes']);
      final vehicles = _maps(normalizedProfile['vehicles']);
      return vehicles.map((vehicle) {
        final raw = <String, dynamic>{...vehicle};
        raw['routes'] = routes;
        return _item(type, raw);
      }).toList();
    }
    return _items(response).map((e) => _item(type, e)).toList();
  }

  @override
  Future<MarketplaceItem> providerItem(MarketplaceType type, String id) async {
    if (type == MarketplaceType.transport) {
      final profile = await transportProfile();
      for (final vehicle in _maps(profile['vehicles'])) {
        if ('${vehicle['id'] ?? ''}' == id) {
          return _item(type, vehicle);
        }
      }
      throw StateError('Vehicle was not found in the provider transport profile.');
    }
    final response = await api.get(
      '${Endpoints.providerAccommodations}/${Uri.encodeComponent(id)}',
      authenticated: true,
    );
    return _item(type, _object(response, 'accommodation'));
  }

  @override
  Future<MarketplaceItem> saveAccommodation(Map<String, dynamic> body, {String? id}) async {
    final response = id == null
        ? await api.post(Endpoints.providerAccommodations, authenticated: true, body: body)
        : await api.patch('${Endpoints.providerAccommodations}/$id', authenticated: true, body: body);
    return _item(MarketplaceType.accommodation, _object(response, 'accommodation'));
  }

  @override
  Future<void> deleteAccommodation(String id) async {
    await api.delete('${Endpoints.providerAccommodations}/$id', authenticated: true);
  }

  @override
  Future<Map<String, dynamic>> saveAccommodationUnit(String accommodationId, Map<String, dynamic> body, {String? unitId}) async {
    final response = unitId == null
        ? await api.post('${Endpoints.providerAccommodations}/$accommodationId/units', authenticated: true, body: body)
        : await api.patch('${Endpoints.providerAccommodations}/units/$unitId', authenticated: true, body: body);
    return _data(response);
  }

  @override
  Future<void> deleteAccommodationUnit(String unitId) async {
    await api.delete('${Endpoints.providerAccommodations}/units/$unitId', authenticated: true);
  }

  @override
  Future<Map<String, dynamic>> upsertInventory(String unitId, Map<String, dynamic> body) async =>
      _data(await api.put('${Endpoints.providerAccommodations}/units/$unitId/inventory', authenticated: true, body: body));

  @override
  Future<Map<String, dynamic>> saveRate(String unitId, Map<String, dynamic> body, {String? rateId}) async {
    final response = rateId == null
        ? await api.post('${Endpoints.providerAccommodations}/units/$unitId/rates', authenticated: true, body: body)
        : await api.patch('${Endpoints.providerAccommodations}/rates/$rateId', authenticated: true, body: body);
    return _data(response);
  }

  @override
  Future<void> deleteRate(String rateId) async {
    await api.delete('${Endpoints.providerAccommodations}/rates/$rateId', authenticated: true);
  }

  @override
  Future<void> submitAccommodation(String id, {Map<String, dynamic>? body}) async {
    await api.post(
      '${Endpoints.providerAccommodations}/$id/submit',
      authenticated: true,
    );
  }

  @override
  Future<Map<String, dynamic>> accommodationOperation(String operation, String id, Map<String, dynamic> body) async {
    final encoded = Uri.encodeComponent(id);
    if (operation == 'inventoryCalendar') {
      final query = Uri(queryParameters: {'startDate': '${body['startDate']}', 'endDate': '${body['endDate']}'}).query;
      return _data(await api.get('${Endpoints.providerAccommodations}/units/$encoded/inventory?$query', authenticated: true));
    }
    if (operation == 'pauseAccommodation') {
      return _data(await api.patch('${Endpoints.providerAccommodations}/$encoded/pause', body: body, authenticated: true));
    }
    throw ArgumentError('Unknown accommodation operation: $operation');
  }

  @override
  Future<Map<String, dynamic>> transportProfile() async {
    final data = _data(await api.get(Endpoints.providerTransport, authenticated: true));
    final profile = data['transportProviderProfile'];
    return profile is Map
        ? profile.map((key, value) => MapEntry('$key', value))
        : <String, dynamic>{};
  }
  @override
  Future<Map<String, dynamic>> saveTransportProfile(Map<String, dynamic> body) async => _data(await api.put(Endpoints.providerTransport, authenticated: true, body: body));
  @override
  Future<Map<String, dynamic>> saveVehicle(Map<String, dynamic> body, {String? id}) async => _data(id == null
      ? await api.post('${Endpoints.providerTransport}/vehicles', authenticated: true, body: body)
      : await api.patch('${Endpoints.providerTransport}/vehicles/$id', authenticated: true, body: body));
  @override
  Future<void> deleteVehicle(String id) async {
    await api.delete('${Endpoints.providerTransport}/vehicles/$id', authenticated: true);
  }
  @override
  Future<Map<String, dynamic>> saveVehicleDocument(String vehicleId, Map<String, dynamic> body, {String? documentId}) async {
    final path = '${Endpoints.providerTransport}/vehicles/$vehicleId/documents';
    return _data(documentId == null
        ? await api.post(path, authenticated: true, body: body)
        : await api.patch('$path/$documentId', authenticated: true, body: body));
  }
  @override
  Future<void> deleteVehicleDocument(String vehicleId, String documentId) async {
    await api.delete('${Endpoints.providerTransport}/vehicles/$vehicleId/documents/$documentId', authenticated: true);
  }
  @override
  Future<Map<String, dynamic>> upsertVehicleAvailability(String vehicleId, Map<String, dynamic> body) async => _data(await api.put('${Endpoints.providerTransport}/vehicles/$vehicleId/availability', authenticated: true, body: body));
  @override
  Future<Map<String, dynamic>> saveVehiclePricing(String vehicleId, Map<String, dynamic> body, {String? pricingId}) async {
    final path = '${Endpoints.providerTransport}/vehicles/$vehicleId/pricing';
    return _data(pricingId == null
        ? await api.post(path, authenticated: true, body: body)
        : await api.patch('$path/$pricingId', authenticated: true, body: body));
  }
  @override
  Future<void> deleteVehiclePricing(String vehicleId, String pricingId) async {
    await api.delete('${Endpoints.providerTransport}/vehicles/$vehicleId/pricing/$pricingId', authenticated: true);
  }
  @override
  Future<Map<String, dynamic>> saveRoute(Map<String, dynamic> body, {String? routeId}) async {
    final path = '${Endpoints.providerTransport}/routes';
    return _data(routeId == null
        ? await api.post(path, authenticated: true, body: body)
        : await api.patch('$path/$routeId', authenticated: true, body: body));
  }
  @override
  Future<void> deleteRoute(String routeId) async {
    await api.delete('${Endpoints.providerTransport}/routes/$routeId', authenticated: true);
  }
  @override
  Future<void> submitVehicle(String id) async {
    await api.post('${Endpoints.providerTransport}/vehicles/$id/submit', authenticated: true);
  }

  @override
  Future<List<MarketplaceBooking>> providerBookings(MarketplaceType type) async {
    final items = await fetchApiCollection(api, '${Endpoints.providerBookings}?bookingType=${type.apiValue}', authenticated: true, keys: ['items', 'results', 'bookings']);
    return items.map(_booking).where((booking) => _matchesType(booking, type)).toList();
  }

  @override
  Future<MarketplaceBooking> providerBookingAction(
    MarketplaceType type,
    String id,
    String action, {
    Map<String, dynamic>? body,
  }) async {
    const allowed = <String>{'accept', 'reject', 'cancel', 'start', 'complete'};
    if (!allowed.contains(action)) {
      throw ArgumentError('Unsupported ${type.apiValue} booking action: $action');
    }
    final response = await api.post(
      '${Endpoints.providerBookings}/$id/${type.apiValue}/$action',
      authenticated: true,
      body: body,
    );
    return _booking(_object(response, 'booking'));
  }

  @override
  Future<Map<String, dynamic>> transportOperation(String operation, {String? id, Map<String, dynamic>? body}) async {
    final base = Endpoints.providerTransport;
    final encoded = Uri.encodeComponent(id ?? '');
    switch (operation) {
      case 'drivers': return _data(await api.get('$base/drivers', authenticated: true));
      case 'devices': return _data(await api.get('$base/devices', authenticated: true));
      case 'saveDriver': return _data(id == null
          ? await api.post('$base/drivers', authenticated: true, body: body)
          : await api.patch('$base/drivers/$encoded', authenticated: true, body: body));
      case 'saveDevice': return _data(id == null
          ? await api.post('$base/devices', authenticated: true, body: body)
          : await api.patch('$base/devices/$encoded', authenticated: true, body: body));
      case 'assignRide': return _data(await api.put('$base/rides/$encoded/assignment', authenticated: true, body: body));
      case 'arrived': return _data(await api.post('$base/rides/$encoded/arrived', authenticated: true));
      case 'vehicleStatus': return _data(await api.patch('$base/vehicles/$encoded/status', authenticated: true, body: body));
      default: throw ArgumentError('Unknown transport operation: $operation');
    }
  }

  bool _matchesType(MarketplaceBooking booking, MarketplaceType type) {
    final value = booking.bookingType.toLowerCase();
    if (value.isEmpty) return true;
    if (type == MarketplaceType.accommodation) {
      return value.contains('accommodation') || value.contains('hotel') || value.contains('stay');
    }
    return value.contains('transport') || value.contains('vehicle') || value.contains('cab');
  }

  Map<String, dynamic> _data(Map<String, dynamic> response) {
    final data = response['data'];
    return data is Map ? data.map((k, v) => MapEntry('$k', v)) : response;
  }

  List<Map<String, dynamic>> _items(Map<String, dynamic> response) {
    final data = _data(response);
    final dynamic value = data['items'] ?? data['results'] ?? data['accommodations'] ?? data['vehicles'] ?? data['bookings'];
    return _maps(value);
  }

  Map<String, dynamic> _object(Map<String, dynamic> response, String key) {
    final data = _data(response);
    final value = data[key];
    return value is Map ? value.map((k, v) => MapEntry('$k', v)) : data;
  }

  List<Map<String, dynamic>> _maps(dynamic value) => value is List
      ? value.whereType<Map>().map((e) => e.map((k, v) => MapEntry('$k', v))).toList()
      : <Map<String, dynamic>>[];

  String _mime(String mime, String name) {
    final clean = mime.toLowerCase();
    if (clean.startsWith('image/')) return clean == 'image/jpg' ? 'image/jpeg' : clean;
    final lowerName = name.toLowerCase();
    if (lowerName.endsWith('.png')) return 'image/png';
    if (lowerName.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
