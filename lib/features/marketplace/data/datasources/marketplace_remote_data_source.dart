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
    required int guests,
    required int units,
  });

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

  Future<List<MarketplaceBooking>> providerBookings(MarketplaceType type);
  Future<MarketplaceBooking> providerBookingAction(MarketplaceType type, String id, String action, {Map<String, dynamic>? body});
}

class MarketplaceRemoteDataSourceImpl implements MarketplaceRemoteDataSource {
  const MarketplaceRemoteDataSourceImpl(this.api);
  final ApiClient api;

  String _public(MarketplaceType type) => type == MarketplaceType.accommodation ? Endpoints.accommodations : Endpoints.transport;
  String _provider(MarketplaceType type) => type == MarketplaceType.accommodation ? Endpoints.providerAccommodations : Endpoints.providerTransport;

  @override
  Future<List<MarketplaceItem>> publicItems(MarketplaceType type, {String? query}) async {
    final clean = query?.trim();
    final params = <String>['page=1', 'limit=100'];
    if (clean != null && clean.isNotEmpty) params.add('q=${Uri.encodeQueryComponent(clean)}');
    final response = await api.get('${_public(type)}?${params.join('&')}');
    return _items(response).map((e) => MarketplaceItem(type: type, raw: e)).toList();
  }

  @override
  Future<MarketplaceItem> publicDetail(MarketplaceType type, String id) async {
    final path = type == MarketplaceType.transport
        ? '${Endpoints.transport}/vehicles/${Uri.encodeComponent(id)}'
        : '${Endpoints.accommodations}/${Uri.encodeComponent(id)}';
    final response = await api.get(path);
    return MarketplaceItem(type: type, raw: _object(response, type == MarketplaceType.transport ? 'vehicle' : 'accommodation'));
  }

  @override
  Future<AccommodationAvailabilityQuote> accommodationAvailability({required String identifier, required String checkIn, required String checkOut, required int guests, required int units}) async {
    final path = '${Endpoints.accommodations}/${Uri.encodeComponent(identifier)}/availability'
        '?check_in=${Uri.encodeQueryComponent(checkIn)}'
        '&check_out=${Uri.encodeQueryComponent(checkOut)}'
        '&guests=$guests&units=$units';
    final response = await api.get(path);
    final data = _data(response);
    final quote = data['availability'] is Map
        ? (data['availability'] as Map).map((k, v) => MapEntry('$k', v))
        : data;
    return AccommodationAvailabilityQuote(quote);
  }

  @override
  Future<List<MarketplaceBooking>> customerBookings(MarketplaceType type) async {
    final response = await api.get('${Endpoints.bookings}?page=1&limit=100', authenticated: true);
    return _items(response)
        .map(MarketplaceBooking.new)
        .where((booking) => _matchesType(booking, type))
        .toList();
  }

  @override
  Future<MarketplaceBooking> bookingDetail(String id, {bool provider = false}) async {
    final response = await api.get('${provider ? Endpoints.providerBookings : Endpoints.bookings}/$id', authenticated: true);
    return MarketplaceBooking(_object(response, 'booking'));
  }

  @override
  Future<MarketplaceBooking> createBooking(MarketplaceType type, Map<String, dynamic> body) async {
    final response = await api.post(
      Endpoints.bookings,
      authenticated: true,
      body: <String, dynamic>{'bookingType': type.apiValue, ...body},
    );
    return MarketplaceBooking(_object(response, 'booking'));
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
        'booking_id': bookingId,
        'rating': rating,
        'comment': comment.trim(),
        if (title?.trim().isNotEmpty == true) 'title': title!.trim(),
      },
    );
  }

  @override
  Future<String> uploadImage({required Uint8List bytes, required String fileName, required String mimeType}) async {
    final response = await api.postMultipart(
      Endpoints.media,
      bytes: bytes,
      fileName: fileName,
      fieldName: 'file',
      contentType: _mime(mimeType, fileName),
      fields: const {'purpose': 'general'},
      authenticated: true,
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
    final response = await api.get('${_provider(type)}?page=1&limit=100', authenticated: true);
    if (type == MarketplaceType.transport) {
      final data = _data(response);
      final vehicles = _maps(data['vehicles']);
      return vehicles.map((e) => MarketplaceItem(type: type, raw: e)).toList();
    }
    return _items(response).map((e) => MarketplaceItem(type: type, raw: e)).toList();
  }

  @override
  Future<MarketplaceItem> providerItem(MarketplaceType type, String id) async {
    final response = await api.get('${_provider(type)}/${Uri.encodeComponent(id)}', authenticated: true);
    return MarketplaceItem(type: type, raw: _object(response, type == MarketplaceType.accommodation ? 'accommodation' : 'vehicle'));
  }

  @override
  Future<MarketplaceItem> saveAccommodation(Map<String, dynamic> body, {String? id}) async {
    final response = id == null
        ? await api.post(Endpoints.providerAccommodations, authenticated: true, body: body)
        : await api.patch('${Endpoints.providerAccommodations}/$id', authenticated: true, body: body);
    return MarketplaceItem(type: MarketplaceType.accommodation, raw: _object(response, 'accommodation'));
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
    await api.post('${Endpoints.providerAccommodations}/$id/submit', authenticated: true, body: body?.isEmpty == true ? null : body);
  }

  @override
  Future<Map<String, dynamic>> transportProfile() async => _data(await api.get(Endpoints.providerTransport, authenticated: true));
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
    final response = await api.get('${Endpoints.providerBookings}?page=1&limit=100', authenticated: true);
    return _items(response)
        .map(MarketplaceBooking.new)
        .where((booking) => _matchesType(booking, type))
        .toList();
  }

  @override
  Future<MarketplaceBooking> providerBookingAction(MarketplaceType type, String id, String action, {Map<String, dynamic>? body}) async {
    final path = type == MarketplaceType.accommodation
        ? '${Endpoints.providerBookings}/$id/accommodation/$action'
        : '${Endpoints.providerBookings}/$id/${type.apiValue}/$action';
    final response = await api.post(path, authenticated: true, body: body);
    final data = _data(response);
    return MarketplaceBooking(data['booking'] is Map
        ? (data['booking'] as Map).map((k, v) => MapEntry('$k', v))
        : data);
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
