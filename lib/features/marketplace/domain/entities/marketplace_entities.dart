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

  String get id => _first(['id','accommodationId','vehicleId']);
  String get slug => _first(['slug','identifier','id']);
  String get name => _first(['name','displayName','propertyName','title','vehicleName','registrationNumber'], fallback: type.title);
  String get description => _first(['shortDescription','description','summary','notes']);
  String get city => _first(['city','locationName','pickupCity']);
  String get status => _first(['approvalStatus','status'], fallback: raw['isActive'] == false ? 'inactive' : 'active');
  bool get isActive => raw['isActive'] != false;
  double get price => _number(['priceAmount','basePrice','pricePerNight','price','dailyRate','amount']);
  String get currency => _first(['currency'], fallback: 'INR');
  List<Map<String,dynamic>> get units => _maps(raw['units']);
  List<Map<String,dynamic>> get vehicles => _maps(raw['vehicles']);
  List<Map<String,dynamic>> get routes => _maps(raw['routes']);
  List<String> get imageUrls {
    final out=<String>[];
    void add(dynamic v){
      if(v is String && v.trim().isNotEmpty) out.add(v.trim());
      if(v is Map){ add(v['url']); add(v['publicUrl']); add(v['mediaUrl']); }
    }
    final media=raw['media'] ?? raw['images'] ?? raw['gallery'];
    if(media is List) for(final x in media) add(x);
    add(raw['imageUrl']); add(raw['coverImageUrl']);
    return out.toSet().toList();
  }

  String _first(List<String> keys,{String fallback=''}){
    for(final k in keys){ final v=raw[k]; if(v!=null && '$v'.trim().isNotEmpty) return '$v'.trim(); }
    return fallback;
  }
  double _number(List<String> keys){ for(final k in keys){ final v=raw[k]; if(v is num) return v.toDouble(); final p=double.tryParse('${v??''}'); if(p!=null) return p; } return 0; }
  static List<Map<String,dynamic>> _maps(dynamic v)=> v is List ? v.whereType<Map>().map((e)=>e.map((k,v)=>MapEntry('$k',v))).toList() : const [];
}

class MarketplaceBooking {
  const MarketplaceBooking(this.raw);
  final Map<String,dynamic> raw;
  String get id => '${raw['id'] ?? raw['bookingId'] ?? ''}';
  String get bookingNumber => '${raw['bookingNumber'] ?? raw['reference'] ?? id}';
  String get bookingType => '${raw['bookingType'] ?? raw['type'] ?? ''}';
  String get status => '${raw['status'] ?? ''}';
  String get providerDecision => '${raw['providerDecision'] ?? ''}';
  String get serviceDate => '${raw['serviceDate'] ?? raw['startDate'] ?? ''}';
  String get endDate => '${raw['endDate'] ?? ''}';
  double get totalAmount => _d(raw['totalAmount'] ?? raw['amount']);
  String get currency => '${raw['currency'] ?? 'INR'}';
  Map<String,dynamic> get pricingSnapshot => _map(raw['pricingSnapshot']);
  String get displayName => '${pricingSnapshot['name'] ?? pricingSnapshot['propertyName'] ?? pricingSnapshot['vehicleName'] ?? pricingSnapshot['serviceName'] ?? bookingType}';
  bool get isCompleted => status.toLowerCase() == 'completed';
  static double _d(dynamic v)=>v is num?v.toDouble():double.tryParse('${v??''}')??0;
  static Map<String,dynamic> _map(dynamic v)=>v is Map?v.map((k,v)=>MapEntry('$k',v)):<String,dynamic>{};
}
