import '../../../bookings/domain/entities/booking_lifecycle.dart';

enum MarketplaceType { accommodation, transport }

extension MarketplaceTypeX on MarketplaceType {
  String get apiValue => this == MarketplaceType.accommodation ? 'accommodation' : 'transport';
  String get title => this == MarketplaceType.accommodation ? 'Accommodation' : 'Transport';
  String get plural => this == MarketplaceType.accommodation ? 'Stays' : 'Transport';
}

class MarketplaceItem {
  const MarketplaceItem({required this.type, required this.raw});

  final MarketplaceType type;
  final Map<String, dynamic> raw;

  String get id => _first(['id', 'accommodation_id', 'accommodationId', 'vehicle_id', 'vehicleId']);
  String get slug => _first(['slug', 'identifier', 'id']);
  String get name => _first(
        ['name', 'display_name', 'displayName', 'property_name', 'propertyName', 'title', 'vehicle_name', 'vehicleName', 'registration_number', 'registrationNumber'],
        fallback: type.title,
      );
  String get description => _first(['short_description', 'shortDescription', 'description', 'summary', 'notes']);
  String get city => _first(['city', 'location_name', 'locationName', 'pickup_city', 'pickupCity']);
  String get state => _first(['state']);
  String get address => _first(['address', 'address_line_1', 'addressLine1']);
  String get propertyType => _first(['accommodation_type', 'accommodationType', 'property_type', 'propertyType']);
  String get checkInTime => _first(['check_in_time', 'checkInTime']);
  String get checkOutTime => _first(['check_out_time', 'checkOutTime']);
  String get status => _first(
        ['approval_status', 'approvalStatus', 'status'],
        fallback: raw['is_active'] == false || raw['isActive'] == false ? 'inactive' : 'active',
      );
  static const vehicleDocumentLabels = <String, String>{
    'registration_certificate': 'Registration certificate (RC)',
    'insurance': 'Insurance',
    'permit': 'Permit',
    'puc': 'Pollution certificate (PUC)',
  };
  String get _todayIndia => DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30)).toIso8601String().substring(0, 10);
  List<String> get missingVehicleDocuments {
    final documents = raw['documents'] is List ? (raw['documents'] as List).whereType<Map>() : const <Map>[];
    return vehicleDocumentLabels.keys.where((type) => !documents.any((doc) =>
      doc['documentType'] == type && const {'pending', 'verified'}.contains(doc['status']) &&
      (doc['metadata'] is! Map || (doc['metadata'] as Map)['archivedAt'] == null) &&
      (doc['expiresAt'] == null || '${doc['expiresAt']}'.compareTo(_todayIndia) >= 0)
    )).toList();
  }
  bool get hasCurrentVehiclePricing {
    final prices = raw['pricing'] is List ? (raw['pricing'] as List).whereType<Map>() : const <Map>[];
    return prices.any((price) => price['isActive'] == true &&
      (price['validFrom'] == null || '${price['validFrom']}'.compareTo(_todayIndia) <= 0) &&
      (price['validTo'] == null || '${price['validTo']}'.compareTo(_todayIndia) >= 0) &&
      (price['routeId'] == null || (price['route'] is Map && (price['route'] as Map)['status'] == 'active')));
  }
  bool get readyToSubmitVehicle => missingVehicleDocuments.isEmpty && hasCurrentVehiclePricing;
  String get operationalStatus => _first(['status'], fallback: 'draft');
  String get reviewNote => _first(['rejectionReason', 'moderationNote', 'rejection_reason']);
  bool get isActive => raw['is_active'] != false && raw['isActive'] != false;
  double get price {
    if (type == MarketplaceType.accommodation && units.isNotEmpty) {
      final prices = units
          .map((unit) => _valueNumber(unit['basePriceAmount'] ?? unit['base_price_amount']))
          .where((value) => value > 0)
          .toList();
      if (prices.isNotEmpty) {
        prices.sort();
        return prices.first;
      }
    }
    return _number(['price_amount', 'priceAmount', 'base_price_amount', 'basePriceAmount', 'base_price', 'basePrice', 'price_per_night', 'pricePerNight', 'price', 'daily_rate', 'dailyRate', 'amount']);
  }
  String get currency => _first(['currency'], fallback: 'INR');
  List<Map<String, dynamic>> get units => _maps(raw['units']);
  List<Map<String, dynamic>> get vehicles => _maps(raw['vehicles']);
  List<Map<String, dynamic>> get routes => _maps(raw['routes']);
  List<String> get amenities => _strings(raw['amenities']);

  List<String> get imageUrls {
    final out = <String>[];
    void add(dynamic value) {
      if (value is String && value.trim().isNotEmpty) out.add(value.trim());
      if (value is Map) {
        if (value['type'] != null && value['type'] != 'image') return;
        if (value['visibility'] == 'private' || value['status'] == 'deleted') return;
        // One gallery entry per asset; thumbnails are a fallback, not another photo.
        for (final key in const ['url', 'public_url', 'publicUrl', 'media_url',
          'mediaUrl', 'content_url', 'contentUrl', 'thumbnail_url', 'thumbnailUrl']) {
          final url = value[key];
          if (url is String && url.trim().isNotEmpty) {
            add(url);
            break;
          }
        }
      }
    }

    for (final key in const ['mediaAssets', 'media', 'images', 'gallery']) {
      final value = raw[key];
      if (value is List) {
        for (final item in value) {
          add(item);
        }
      }
    }
    add(raw['image_url']);
    add(raw['imageUrl']);
    add(raw['cover_image_url']);
    add(raw['coverImageUrl']);
    return out.toSet().toList();
  }

  String _first(List<String> keys, {String fallback = ''}) {
    for (final key in keys) {
      final value = raw[key];
      if (value != null && '$value'.trim().isNotEmpty) return '$value'.trim();
    }
    return fallback;
  }

  double _number(List<String> keys) {
    for (final key in keys) {
      final value = raw[key];
      if (value is num) return value.toDouble();
      final parsed = double.tryParse('${value ?? ''}');
      if (parsed != null) return parsed;
    }
    return 0;
  }

  static List<Map<String, dynamic>> _maps(dynamic value) => value is List
      ? value.whereType<Map>().map((e) => e.map((k, v) => MapEntry('$k', v))).toList()
      : const [];

  static List<String> _strings(dynamic value) => value is List
      ? value.map((e) => '$e'.trim()).where((e) => e.isNotEmpty).toList()
      : const [];

  static double _valueNumber(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('${value ?? ''}') ?? 0;
}

class AccommodationAvailabilityQuote {
  const AccommodationAvailabilityQuote(this.raw);

  final Map<String, dynamic> raw;

  bool get available {
    final value = raw['available'] ?? raw['is_available'] ?? raw['isAvailable'];
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    final options = availableUnits;
    return options.isNotEmpty;
  }

  double get totalAmount => _double(raw['total_amount'] ?? raw['totalAmount'] ?? raw['amount'] ?? raw['total']);
  String get currency => '${raw['currency'] ?? 'INR'}';
  String get message => '${raw['message'] ?? raw['reason'] ?? ''}';
  List<Map<String, dynamic>> get availableUnits {
    final dynamic value = raw['unitsAvailability'] ?? raw['units_availability'] ?? raw['available_units'] ?? raw['availableUnits'] ?? raw['units'] ?? raw['options'];
    return value is List
        ? value.whereType<Map>().map((e) => e.map((k, v) => MapEntry('$k', v))).toList()
        : const [];
  }

  Map<String, dynamic>? unitAvailability(String unitId) {
    for (final unit in availableUnits) {
      final id = '${unit['unitId'] ?? unit['unit_id'] ?? unit['id'] ?? ''}';
      if (id == unitId) return unit;
    }
    return null;
  }

  bool isUnitAvailable(String unitId) {
    final unit = unitAvailability(unitId);
    if (unit == null) return false;
    final value = unit['available'] ?? unit['isAvailable'] ?? unit['is_available'];
    return value == true || value == 1 || '$value'.toLowerCase() == 'true';
  }

  String unitCurrency(String unitId) => '${unitAvailability(unitId)?['currency'] ?? currency}';

  double unitTotalAmount(String unitId) => _double(unitAvailability(unitId)?['totalAmount'] ?? unitAvailability(unitId)?['total_amount']);

  static double _double(dynamic value) => value is num ? value.toDouble() : double.tryParse('${value ?? ''}') ?? 0;
}

class MarketplaceBooking {
  const MarketplaceBooking(this.raw, {this.lifecycle});

  final BookingLifecycle? lifecycle;
  BookingLifecycle get state => lifecycle ?? BookingLifecycle(status: status, providerDecision: providerDecision, startedAt: DateTime.tryParse(serviceStartedAt), endedAt: DateTime.tryParse(serviceEndedAt));

  final Map<String, dynamic> raw;

  String get id => '${raw['id'] ?? raw['booking_id'] ?? raw['bookingId'] ?? ''}';
  String get bookingNumber => '${raw['booking_number'] ?? raw['bookingNumber'] ?? raw['reference'] ?? id}';
  String get bookingType => '${raw['booking_type'] ?? raw['bookingType'] ?? raw['service_type'] ?? raw['serviceType'] ?? raw['type'] ?? ''}';
  String get status => '${raw['status'] ?? ''}';
  String get providerDecision => '${raw['provider_decision'] ?? raw['providerDecision'] ?? ''}';
  String get serviceDate => '${raw['service_date'] ?? raw['serviceDate'] ?? raw['start_date'] ?? raw['startDate'] ?? raw['scheduled_at'] ?? raw['scheduledAt'] ?? ''}';
  String get endDate => '${raw['end_date'] ?? raw['endDate'] ?? raw['check_out'] ?? raw['checkOut'] ?? ''}';
  double get totalAmount => _double(raw['total_amount'] ?? raw['totalAmount'] ?? raw['amount']);
  String get currency => '${raw['currency'] ?? 'INR'}';
  Map<String, dynamic> get pricingSnapshot => _map(raw['pricing_snapshot'] ?? raw['pricingSnapshot']);
  Map<String, dynamic> get serviceSnapshot => _map(raw['service_snapshot'] ?? raw['serviceSnapshot']);
  String get displayName => state.serviceName ?? '${pricingSnapshot['name'] ?? pricingSnapshot['property_name'] ?? pricingSnapshot['propertyName'] ?? serviceSnapshot['name'] ?? serviceSnapshot['property_name'] ?? serviceSnapshot['propertyName'] ?? raw['service_name'] ?? raw['serviceName'] ?? bookingType}';
  String? get imageUrl {
    final summary = _map(raw['serviceSummary'] ?? pricingSnapshot['serviceSummary']);
    final value = summary['coverImageUrl'] ?? summary['thumbnailUrl'];
    return value is String && value.trim().isNotEmpty ? value : null;
  }
  String get notes => '${raw['notes'] ?? ''}';
  String get startOtp => '${raw['startOtp'] ?? raw['start_otp'] ?? ''}';
  String get endOtp => '${raw['endOtp'] ?? raw['end_otp'] ?? ''}';
  String get serviceStartedAt => '${raw['service_started_at'] ?? raw['serviceStartedAt'] ?? ''}';
  String get serviceEndedAt => '${raw['service_ended_at'] ?? raw['serviceEndedAt'] ?? ''}';
  bool get hasStarted => serviceStartedAt.trim().isNotEmpty;
  bool get hasEnded => serviceEndedAt.trim().isNotEmpty;
  bool get isCompleted => state.completed;
  bool get isCancelled => const {'cancelled', 'canceled', 'rejected', 'withdrawn', 'expired'}.contains(status.toLowerCase());

  static double _double(dynamic value) => value is num ? value.toDouble() : double.tryParse('${value ?? ''}') ?? 0;
  static Map<String, dynamic> _map(dynamic value) => value is Map ? value.map((k, v) => MapEntry('$k', v)) : <String, dynamic>{};
}

class TransportAvailabilityQuote {
  const TransportAvailabilityQuote(this.raw);
  final Map<String, dynamic> raw;
  Map<String, dynamic> get quote => raw['quote'] is Map ? Map<String, dynamic>.from(raw['quote'] as Map) : {};
  List<Map<String, dynamic>> get intervals => raw['intervals'] is List
      ? (raw['intervals'] as List).whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList() : [];
  double get totalAmount => double.tryParse('${quote['totalAmount'] ?? ''}') ?? 0;
  String get currency => '${quote['currency'] ?? 'INR'}';
}
