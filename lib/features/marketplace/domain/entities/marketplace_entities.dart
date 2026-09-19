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
  String get propertyType => _first(['property_type', 'propertyType']);
  String get checkInTime => _first(['check_in_time', 'checkInTime']);
  String get checkOutTime => _first(['check_out_time', 'checkOutTime']);
  String get status => _first(
        ['approval_status', 'approvalStatus', 'status'],
        fallback: raw['is_active'] == false || raw['isActive'] == false ? 'inactive' : 'active',
      );
  bool get isActive => raw['is_active'] != false && raw['isActive'] != false;
  double get price => _number(['price_amount', 'priceAmount', 'base_price', 'basePrice', 'price_per_night', 'pricePerNight', 'price', 'daily_rate', 'dailyRate', 'amount']);
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
        add(value['url']);
        add(value['public_url']);
        add(value['publicUrl']);
        add(value['media_url']);
        add(value['mediaUrl']);
        add(value['content_url']);
        add(value['contentUrl']);
        add(value['thumbnail_url']);
        add(value['thumbnailUrl']);
      }
    }

    for (final key in const ['media', 'images', 'gallery']) {
      final value = raw[key];
      if (value is List) {
        for (final item in value) add(item);
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
    final dynamic value = raw['available_units'] ?? raw['availableUnits'] ?? raw['units'] ?? raw['options'];
    return value is List
        ? value.whereType<Map>().map((e) => e.map((k, v) => MapEntry('$k', v))).toList()
        : const [];
  }

  static double _double(dynamic value) => value is num ? value.toDouble() : double.tryParse('${value ?? ''}') ?? 0;
}

class MarketplaceBooking {
  const MarketplaceBooking(this.raw);

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
  String get displayName => '${pricingSnapshot['name'] ?? pricingSnapshot['property_name'] ?? pricingSnapshot['propertyName'] ?? serviceSnapshot['name'] ?? serviceSnapshot['property_name'] ?? serviceSnapshot['propertyName'] ?? raw['service_name'] ?? raw['serviceName'] ?? bookingType}';
  String get notes => '${raw['notes'] ?? ''}';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isCancelled => const {'cancelled', 'canceled', 'rejected'}.contains(status.toLowerCase());

  static double _double(dynamic value) => value is num ? value.toDouble() : double.tryParse('${value ?? ''}') ?? 0;
  static Map<String, dynamic> _map(dynamic value) => value is Map ? value.map((k, v) => MapEntry('$k', v)) : <String, dynamic>{};
}
