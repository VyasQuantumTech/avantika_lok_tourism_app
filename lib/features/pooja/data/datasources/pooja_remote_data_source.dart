import 'dart:typed_data';

import '../../../../core/ network/api_client.dart';
import '../../../../core/ network/endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/pooja_entities.dart';
import '../models/pooja_models.dart';

abstract class PoojaRemoteDataSource {
  Future<String> uploadPoojaImage({required Uint8List bytes, required String fileName, required String mimeType});
  Future<void> deleteUploadedPoojaImage(String mediaAssetId);
  Future<List<Pooja>> getPublicPoojas({String? query});
  Future<Pooja> getPoojaDetail(String identifier);

  Future<List<PoojaBooking>> getCustomerPoojaBookings();
  Future<PoojaBooking> getCustomerPoojaBooking(String bookingId);
  Future<PoojaBooking> createPoojaBooking({
    required String offeringId,
    required String serviceDate,
    required String startTime,
    required int participants,
    String? notes,
  });
  Future<String> getPoojaStartOtp(String bookingId);
  Future<String> getPoojaEndOtp(String bookingId);
  Future<PoojaPaymentSession> initiatePoojaPayment(String bookingId);
  Future<void> verifyPoojaPayment({
    required String paymentId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  });
  Future<PoojaBooking> cancelCustomerBooking(String bookingId, String reason);
  Future<PoojaBooking> withdrawCustomerBooking(String bookingId);
  Future<void> submitPoojaReview({required String bookingId, required int rating, required String comment, String? title});

  Future<PanditPoojaDashboard> getPanditDashboard();
  Future<PanditOffering> createPanditOffering({
    required String name,
    required String description,
    required double priceAmount,
    required String currency,
    required int durationMinutes,
    required String serviceMode,
    String? shortDescription,
    String? notes,
    List<String> mediaAssetIds = const <String>[],
  });
  Future<PanditOffering> updatePanditOffering({
    required String offeringId,
    String? name,
    String? shortDescription,
    String? description,
    double? priceAmount,
    String? currency,
    int? durationMinutes,
    String? serviceMode,
    String? notes,
    bool? isActive,
    List<String>? mediaAssetIds,
  });
  Future<void> deletePanditOffering(String offeringId);

  Future<PanditAvailability> addAvailability({
    required int weekday,
    required String startTime,
    required String endTime,
  });
  Future<void> deleteAvailability(String availabilityId);

  Future<List<PoojaBooking>> getPanditBookings();
  Future<PoojaBooking> getPanditBooking(String bookingId);
  Future<PoojaBooking> acceptPanditBooking(String bookingId);
  Future<PoojaBooking> rejectPanditBooking(String bookingId, {String? reason});
  Future<PoojaBooking> cancelPanditBooking(String bookingId, String reason);
  Future<PoojaBooking> startPanditBooking(String bookingId, String otp);
  Future<PoojaBooking> endPanditBooking(String bookingId, String otp);
}

class PoojaRemoteDataSourceImpl implements PoojaRemoteDataSource {
  const PoojaRemoteDataSourceImpl(this._apiClient);
  final ApiClient _apiClient;


  @override
  Future<String> uploadPoojaImage({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    final normalizedMimeType = _normalizeImageMimeType(mimeType, fileName);
    final response = await _apiClient.postBytes(
      Endpoints.media,
      bytes: bytes,
      contentType: normalizedMimeType,
      authenticated: true,
      headers: <String, String>{
        'x-file-name': fileName,
        'x-media-visibility': 'public',
      },
    );
    final data = _data(response);
    final id = data['id']?.toString();
    if (id == null || id.trim().isEmpty) {
      throw const ApiException(
        'Pooja image upload completed without a media id.',
      );
    }
    return id;
  }

  @override
  Future<void> deleteUploadedPoojaImage(String mediaAssetId) async {
    final id = mediaAssetId.trim();
    if (id.isEmpty) return;
    await _apiClient.delete(
      '${Endpoints.media}/$id',
      authenticated: true,
    );
  }

  @override
  Future<List<Pooja>> getPublicPoojas({String? query}) async {
    final q = query?.trim();
    final path = q == null || q.isEmpty
        ? '${Endpoints.poojas}?limit=100'
        : '${Endpoints.poojas}?limit=100&q=${Uri.encodeQueryComponent(q)}';
    final response = await _apiClient.get(path);
    return _items(response)
        .map((item) => PoojaModel.fromJson(item, baseUrl: _apiClient.baseUrl))
        .toList(growable: false);
  }

  @override
  Future<Pooja> getPoojaDetail(String identifier) async {
    final response = await _apiClient.get(
      '${Endpoints.poojas}/${Uri.encodeComponent(identifier)}',
    );
    final data = _data(response);
    final pooja = _map(data['pooja']);
    return PoojaModel.fromJson(
      pooja.isNotEmpty ? pooja : data,
      baseUrl: _apiClient.baseUrl,
    );
  }

  @override
  Future<List<PoojaBooking>> getCustomerPoojaBookings() async {
    final response = await _apiClient.get(
      '${Endpoints.bookings}?bookingType=pooja&pageSize=100',
      authenticated: true,
    );
    return _items(response)
        .map(poojaBookingFromJson)
        .toList(growable: false);
  }

  @override
  Future<PoojaBooking> getCustomerPoojaBooking(String bookingId) async {
    final response = await _apiClient.get(
      '${Endpoints.bookings}/$bookingId',
      authenticated: true,
    );
    return poojaBookingFromJson(_object(response, 'booking'));
  }

  @override
  Future<PoojaBooking> createPoojaBooking({
    required String offeringId,
    required String serviceDate,
    required String startTime,
    required int participants,
    String? notes,
  }) async {
    final response = await _apiClient.post(
      Endpoints.bookings,
      authenticated: true,
      body: <String, dynamic>{
        'bookingType': 'pooja',
        'panditPoojaId': offeringId,
        'serviceDate': serviceDate,
        'startTime': startTime,
        'participants': participants,
        if (notes?.trim().isNotEmpty == true) 'notes': notes!.trim(),
      },
    );
    return poojaBookingFromJson(_object(response, 'booking'));
  }

  @override
  Future<String> getPoojaStartOtp(String bookingId) async {
    final response = await _apiClient.get(
      '${Endpoints.bookings}/$bookingId/pooja/start-otp',
      authenticated: true,
    );
    return '${_data(response)['otp'] ?? ''}';
  }

  @override
  Future<String> getPoojaEndOtp(String bookingId) async {
    final response = await _apiClient.get(
      '${Endpoints.bookings}/$bookingId/pooja/end-otp',
      authenticated: true,
    );
    return '${_data(response)['otp'] ?? ''}';
  }

  @override
  Future<PoojaPaymentSession> initiatePoojaPayment(String bookingId) async {
    final response = await _apiClient.post(
      Endpoints.payments,
      authenticated: true,
      body: <String, dynamic>{'bookingId': bookingId},
    );
    return poojaPaymentSessionFromJson(_object(response, 'payment'));
  }

  @override
  Future<void> verifyPoojaPayment({
    required String paymentId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    await _apiClient.post(
      '${Endpoints.payments}/$paymentId/verify',
      authenticated: true,
      body: <String, dynamic>{
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': razorpayPaymentId,
        'razorpaySignature': razorpaySignature,
      },
    );
  }

  @override
  Future<PoojaBooking> cancelCustomerBooking(
    String bookingId,
    String reason,
  ) async {
    final response = await _apiClient.post(
      '${Endpoints.bookings}/$bookingId/cancel',
      authenticated: true,
      body: <String, dynamic>{'reason': reason},
    );
    return poojaBookingFromJson(_object(response, 'booking'));
  }

  @override
  Future<PoojaBooking> withdrawCustomerBooking(String bookingId) async {
    final response = await _apiClient.post(
      '${Endpoints.bookings}/$bookingId/withdraw',
      authenticated: true,
      body: const <String, dynamic>{},
    );
    return poojaBookingFromJson(_object(response, 'booking'));
  }

  @override
  Future<void> submitPoojaReview({
    required String bookingId,
    required int rating,
    required String comment,
    String? title,
  }) async {
    await _apiClient.post(
      Endpoints.reviews,
      authenticated: true,
      body: <String, dynamic>{
        'bookingId': bookingId,
        'rating': rating,
        if (title?.trim().isNotEmpty == true) 'title': title!.trim(),
        'comment': comment.trim(),
      },
    );
  }

  @override
  Future<PanditPoojaDashboard> getPanditDashboard() async {
    final response = await _apiClient.get(
      Endpoints.providerPandit,
      authenticated: true,
    );
    return PanditPoojaDashboardModel.fromJson(_data(response));
  }

  @override
  Future<PanditOffering> createPanditOffering({
    required String name,
    required String description,
    required double priceAmount,
    required String currency,
    required int durationMinutes,
    required String serviceMode,
    String? shortDescription,
    String? notes,
    List<String> mediaAssetIds = const <String>[],
  }) async {
    final cleanMediaAssetIds = mediaAssetIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);

    final response = await _apiClient.post(
      Endpoints.providerPanditPoojas,
      authenticated: true,
      body: <String, dynamic>{
        'name': name.trim(),
        if (shortDescription?.trim().isNotEmpty == true)
          'shortDescription': shortDescription!.trim(),
        'description': description.trim(),
        'priceAmount': priceAmount,
        'currency': currency,
        'durationMinutes': durationMinutes,
        'serviceMode': serviceMode,
        if (notes?.trim().isNotEmpty == true) 'notes': notes!.trim(),
        if (cleanMediaAssetIds.isNotEmpty)
          'imageMediaAssetIds': cleanMediaAssetIds,
      },
    );

    return panditOfferingFromResponse(_data(response));
  }

  @override
  Future<PanditOffering> updatePanditOffering({
    required String offeringId,
    String? name,
    String? shortDescription,
    String? description,
    double? priceAmount,
    String? currency,
    int? durationMinutes,
    String? serviceMode,
    String? notes,
    bool? isActive,
    List<String>? mediaAssetIds,
  }) async {
    final cleanMediaAssetIds = mediaAssetIds
        ?.map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);

    final body = <String, dynamic>{
      if (name != null) 'name': name.trim(),
      if (shortDescription != null) 'shortDescription': shortDescription.trim(),
      if (description != null) 'description': description.trim(),
      if (priceAmount != null) 'priceAmount': priceAmount,
      if (currency != null) 'currency': currency,
      if (durationMinutes != null) 'durationMinutes': durationMinutes,
      if (serviceMode != null) 'serviceMode': serviceMode,
      if (notes != null) 'notes': notes.trim(),
      if (isActive != null) 'isActive': isActive,
      if (cleanMediaAssetIds != null)
        'imageMediaAssetIds': cleanMediaAssetIds,
    };
    final response = await _apiClient.patch(
      '${Endpoints.providerPanditPoojas}/$offeringId',
      authenticated: true,
      body: body,
    );
    return panditOfferingFromResponse(_data(response));
  }

  @override
  Future<void> deletePanditOffering(String offeringId) async {
    await _apiClient.delete(
      '${Endpoints.providerPanditPoojas}/$offeringId',
      authenticated: true,
    );
  }

  @override
  Future<PanditAvailability> addAvailability({
    required int weekday,
    required String startTime,
    required String endTime,
  }) async {
    final response = await _apiClient.post(
      Endpoints.providerPanditAvailability,
      authenticated: true,
      body: <String, dynamic>{
        'weekday': weekday,
        'startTime': startTime,
        'endTime': endTime,
        'timezone': 'Asia/Kolkata',
        'isActive': true,
      },
    );
    final item = _object(response, 'availability');
    return PanditAvailability(
      id: '${item['id'] ?? ''}',
      weekday: int.tryParse('${item['weekday']}') ?? weekday,
      startTime: '${item['startTime'] ?? startTime}',
      endTime: '${item['endTime'] ?? endTime}',
      timezone: '${item['timezone'] ?? 'Asia/Kolkata'}',
      isActive: item['isActive'] != false,
    );
  }

  @override
  Future<void> deleteAvailability(String availabilityId) async {
    await _apiClient.delete(
      '${Endpoints.providerPanditAvailability}/$availabilityId',
      authenticated: true,
    );
  }

  @override
  Future<List<PoojaBooking>> getPanditBookings() async {
    final response = await _apiClient.get(
      '${Endpoints.providerBookings}?bookingType=pooja&pageSize=100',
      authenticated: true,
    );
    return _items(response)
        .map(poojaBookingFromJson)
        .toList(growable: false);
  }

  @override
  Future<PoojaBooking> getPanditBooking(String bookingId) async {
    final response = await _apiClient.get(
      '${Endpoints.providerBookings}/$bookingId',
      authenticated: true,
    );
    return poojaBookingFromJson(_object(response, 'booking'));
  }

  @override
  Future<PoojaBooking> acceptPanditBooking(String bookingId) async {
    final response = await _apiClient.post(
      '${Endpoints.providerBookings}/$bookingId/pooja/accept',
      authenticated: true,
    );
    return poojaBookingFromJson(_object(response, 'booking'));
  }

  @override
  Future<PoojaBooking> rejectPanditBooking(
    String bookingId, {
    String? reason,
  }) async {
    final response = await _apiClient.post(
      '${Endpoints.providerBookings}/$bookingId/pooja/reject',
      authenticated: true,
      body: <String, dynamic>{
        if (reason?.trim().isNotEmpty == true) 'reason': reason!.trim(),
      },
    );
    return poojaBookingFromJson(_object(response, 'booking'));
  }

  @override
  Future<PoojaBooking> cancelPanditBooking(
    String bookingId,
    String reason,
  ) async {
    final response = await _apiClient.post(
      '${Endpoints.providerBookings}/$bookingId/pooja/cancel',
      authenticated: true,
      body: <String, dynamic>{'reason': reason.trim()},
    );
    return poojaBookingFromJson(_object(response, 'booking'));
  }

  @override
  Future<PoojaBooking> startPanditBooking(
    String bookingId,
    String otp,
  ) async {
    final response = await _apiClient.post(
      '${Endpoints.providerBookings}/$bookingId/pooja/start',
      authenticated: true,
      body: <String, dynamic>{'otp': otp.trim()},
    );
    return poojaBookingFromJson(_object(response, 'booking'));
  }

  @override
  Future<PoojaBooking> endPanditBooking(String bookingId, String otp) async {
    final response = await _apiClient.post(
      '${Endpoints.providerBookings}/$bookingId/pooja/end',
      authenticated: true,
      body: <String, dynamic>{'otp': otp.trim()},
    );
    return poojaBookingFromJson(_object(response, 'booking'));
  }

  String _normalizeImageMimeType(String mimeType, String fileName) {
    final raw = mimeType.trim().toLowerCase();
    if (raw == 'image/jpg' || raw == 'image/pjpeg') return 'image/jpeg';
    if (raw == 'image/x-png') return 'image/png';
    if (raw == 'image/jpeg' ||
        raw == 'image/png' ||
        raw == 'image/webp' ||
        raw == 'image/heic' ||
        raw == 'image/heif') {
      return raw;
    }

    final lowerName = fileName.toLowerCase();
    if (lowerName.endsWith('.png')) return 'image/png';
    if (lowerName.endsWith('.webp')) return 'image/webp';
    if (lowerName.endsWith('.heic')) return 'image/heic';
    if (lowerName.endsWith('.heif')) return 'image/heif';
    return 'image/jpeg';
  }

  Map<String, dynamic> _data(Map<String, dynamic> response) {
    final value = response['data'];
    return value is Map ? _map(value) : response;
  }

  List<Map<String, dynamic>> _items(Map<String, dynamic> response) {
    final data = _data(response);

    // Different list endpoints in the backend may expose their collection
    // under a resource-specific key instead of the generic `items` key.
    // Keep the mobile layer tolerant so public Poojas and customer/provider
    // bookings do not render as an empty list simply because of the envelope.
    dynamic value = data['items'];
    value ??= data['poojas'];
    value ??= data['bookings'];
    value ??= data['results'];

    if (value is! List) return const <Map<String, dynamic>>[];
    return value.whereType<Map>().map(_map).toList(growable: false);
  }

  Map<String, dynamic> _object(
    Map<String, dynamic> response,
    String key,
  ) {
    final data = _data(response);
    final nested = _map(data[key]);
    return nested.isNotEmpty ? nested : data;
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return const <String, dynamic>{};
  }
}
