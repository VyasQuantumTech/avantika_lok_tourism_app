import '../../domain/entities/pooja_entities.dart';

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const <String, dynamic>{};
}

List<Map<String, dynamic>> _mapList(dynamic value) {
  if (value is! List) return const <Map<String, dynamic>>[];
  return value.whereType<Map>().map(_map).toList(growable: false);
}

double _double(dynamic value) => double.tryParse('$value') ?? 0;
int? _intOrNull(dynamic value) {
  if (value == null) return null;
  return int.tryParse('$value');
}

DateTime? _dateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse('$value');
}

class PoojaModel extends Pooja {
  const PoojaModel({
    required super.id,
    required super.name,
    required super.slug,
    required super.currency,
    required super.offerings,
    super.shortDescription,
    super.description,
    super.defaultDurationMinutes,
    super.defaultPriceAmount,
    super.coverUrl,
    super.status,
    super.isFeatured,
    super.media,
    super.reviewSummary,
  });

  factory PoojaModel.fromJson(
    Map<String, dynamic> json, {
    required String baseUrl,
  }) {
    final pandits = _mapList(json['pandits']);
    final offerings = pandits.map((pandit) {
      final provider = _map(pandit['providerProfile']);
      final offering = _map(pandit['offering']);
      return PoojaOffering(
        id: '${offering['id'] ?? ''}',
        panditId: '${pandit['id'] ?? ''}',
        panditName: '${provider['displayName'] ?? 'Pandit'}',
        priceAmount: _double(offering['priceAmount']),
        currency: '${offering['currency'] ?? json['currency'] ?? 'INR'}',
        durationMinutes: _intOrNull(offering['durationMinutes']),
        serviceMode: '${offering['serviceMode'] ?? 'flexible'}',
        city: provider['city']?.toString(),
        state: provider['state']?.toString(),
        approvalStatus: offering['approvalStatus']?.toString(),
        isActive: offering['isActive'] != false,
      );
    }).where((item) => item.id.isNotEmpty).toList(growable: false);

    final mediaRaw = json['media'] ?? json['mediaAssets'] ?? json['images'];
    final media = _mapList(mediaRaw).map((item) {
      final asset = _map(item['mediaAsset'] ?? item['asset']);
      final source = asset.isNotEmpty ? asset : item;
      final rawUrl = (source['url'] ?? source['publicUrl'] ?? source['storageUrl'] ?? item['url'])?.toString();
      if (rawUrl == null || rawUrl.trim().isEmpty) return null;
      final url = rawUrl.startsWith('http') ? rawUrl : '$baseUrl$rawUrl';
      return PoojaMedia(
        id: '${source['id'] ?? item['mediaAssetId'] ?? item['id'] ?? ''}',
        url: url,
        sortOrder: int.tryParse('${item['sortOrder'] ?? source['sortOrder'] ?? 0}') ?? 0,
      );
    }).whereType<PoojaMedia>().toList(growable: false)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final rawCover = json['coverUrl']?.toString();
    final coverUrl = rawCover == null || rawCover.isEmpty
        ? (media.isEmpty ? null : media.first.url)
        : rawCover.startsWith('http')
            ? rawCover
            : '$baseUrl$rawCover';

    final ratingRaw = _map(json['reviewSummary'] ?? json['ratings'] ?? json['rating']);
    final reviewSummary = PoojaReviewSummary(
      count: int.tryParse('${ratingRaw['count'] ?? ratingRaw['totalReviews'] ?? json['reviewCount'] ?? 0}') ?? 0,
      averageRating: _double(ratingRaw['averageRating'] ?? ratingRaw['average'] ?? json['averageRating']),
    );

    return PoojaModel(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      slug: '${json['slug'] ?? ''}',
      shortDescription: json['shortDescription']?.toString(),
      description: json['description']?.toString(),
      defaultDurationMinutes: _intOrNull(json['defaultDurationMinutes']),
      defaultPriceAmount: json['defaultPriceAmount'] == null
          ? null
          : _double(json['defaultPriceAmount']),
      currency: '${json['currency'] ?? 'INR'}',
      coverUrl: coverUrl,
      status: json['status']?.toString(),
      isFeatured: json['isFeatured'] == true,
      media: media,
      reviewSummary: reviewSummary,
      offerings: offerings,
    );
  }
}

class PanditPoojaDashboardModel extends PanditPoojaDashboard {
  const PanditPoojaDashboardModel({
    required super.panditId,
    required super.isActive,
    required super.offerings,
    required super.availability,
    required super.upcomingBookings,
    required super.pendingActionBookings,
    required super.completedBookings,
    required super.estimatedGross,
    required super.currency,
  });

  factory PanditPoojaDashboardModel.fromJson(Map<String, dynamic> json) {
    final pandit = _map(json['pandit']);
    final bookings = _map(json['bookings']);
    final earnings = _map(json['earnings']);

    final offerings = _mapList(pandit['poojas']).map((pooja) {
      final offering = _map(pooja['offering']);
      return PanditOffering(
        id: '${offering['id'] ?? ''}',
        poojaId: '${pooja['id'] ?? ''}',
        name: '${pooja['name'] ?? 'Pooja'}',
        shortDescription: pooja['shortDescription']?.toString(),
        description: pooja['description']?.toString(),
        media: _panditMedia(pooja, offering),
        priceAmount: _double(offering['priceAmount']),
        currency: '${offering['currency'] ?? pooja['currency'] ?? 'INR'}',
        durationMinutes: _intOrNull(offering['durationMinutes']),
        serviceMode: '${offering['serviceMode'] ?? 'flexible'}',
        approvalStatus: '${offering['approvalStatus'] ?? 'pending'}',
        isActive: offering['isActive'] == true,
        moderationNote: offering['moderationNote']?.toString(),
      );
    }).where((item) => item.id.isNotEmpty).toList(growable: false);

    final availability = _mapList(pandit['availability']).map((item) {
      return PanditAvailability(
        id: '${item['id'] ?? ''}',
        weekday: int.tryParse('${item['weekday']}') ?? 0,
        startTime: '${item['startTime'] ?? ''}',
        endTime: '${item['endTime'] ?? ''}',
        timezone: '${item['timezone'] ?? 'Asia/Kolkata'}',
        isActive: item['isActive'] != false,
      );
    }).where((item) => item.id.isNotEmpty).toList(growable: false);

    return PanditPoojaDashboardModel(
      panditId: '${pandit['id'] ?? ''}',
      isActive: pandit['isActive'] == true,
      offerings: offerings,
      availability: availability,
      upcomingBookings: int.tryParse('${bookings['upcoming'] ?? 0}') ?? 0,
      pendingActionBookings:
          int.tryParse('${bookings['pendingAction'] ?? 0}') ?? 0,
      completedBookings: int.tryParse('${bookings['completed'] ?? 0}') ?? 0,
      estimatedGross: _double(earnings['estimatedGross']),
      currency: '${earnings['currency'] ?? 'INR'}',
    );
  }
}

PanditOffering panditOfferingFromResponse(Map<String, dynamic> json) {
  final pooja = _map(json['pooja']);
  final offering = _map(json['offering']);
  final source = offering.isNotEmpty ? offering : json;
  final poojaSource = pooja.isNotEmpty ? pooja : json;
  return PanditOffering(
    id: '${source['id'] ?? ''}',
    poojaId: '${source['poojaId'] ?? poojaSource['id'] ?? ''}',
    name: '${poojaSource['name'] ?? source['name'] ?? 'Pooja'}',
    shortDescription:
        poojaSource['shortDescription']?.toString() ??
        source['shortDescription']?.toString(),
    description:
        poojaSource['description']?.toString() ??
        source['description']?.toString(),
    priceAmount: _double(source['priceAmount']),
    currency: '${source['currency'] ?? poojaSource['currency'] ?? 'INR'}',
    durationMinutes: _intOrNull(source['durationMinutes']),
    serviceMode: '${source['serviceMode'] ?? 'flexible'}',
    approvalStatus: '${source['approvalStatus'] ?? 'pending'}',
    isActive: source['isActive'] == true,
    moderationNote: source['moderationNote']?.toString(),
    media: _panditMedia(poojaSource, source),
  );
}

List<PoojaMedia> _panditMedia(Map<String, dynamic> pooja, Map<String, dynamic> offering) {
  final raw = pooja['media'] ?? pooja['mediaAssets'] ?? pooja['images'] ?? offering['media'];
  return _mapList(raw).map((item) {
    final asset = _map(item['mediaAsset'] ?? item['asset']);
    final source = asset.isNotEmpty ? asset : item;
    final url = (source['url'] ?? source['publicUrl'] ?? source['storageUrl'] ?? item['url'])?.toString();
    if (url == null || url.isEmpty) return null;
    return PoojaMedia(
      id: '${source['id'] ?? item['mediaAssetId'] ?? item['id'] ?? ''}',
      url: url,
      sortOrder: int.tryParse('${item['sortOrder'] ?? 0}') ?? 0,
    );
  }).whereType<PoojaMedia>().toList(growable: false);
}

PoojaBooking poojaBookingFromJson(Map<String, dynamic> json) {
  return PoojaBooking(
    id: '${json['id'] ?? ''}',
    bookingNumber: '${json['bookingNumber'] ?? ''}',
    status: '${json['status'] ?? 'pending'}',
    providerDecision: '${json['providerDecision'] ?? 'pending'}',
    serviceDate: '${json['serviceDate'] ?? ''}',
    startTime: json['startTime']?.toString(),
    endTime: json['endTime']?.toString(),
    panditPoojaId: json['panditPoojaId']?.toString(),
    totalAmount: _double(json['totalAmount']),
    currency: '${json['currency'] ?? 'INR'}',
    notes: json['notes']?.toString(),
    poojaStartOtp: json['poojaStartOtp']?.toString(),
    poojaEndOtp: json['poojaEndOtp']?.toString(),
    serviceStartedAt: _dateTime(json['serviceStartedAt']),
    serviceEndedAt: _dateTime(json['serviceEndedAt']),
    pricingSnapshot: _map(json['pricingSnapshot']),
    customerSnapshot: _map(json['customerSnapshot']),
  );
}


PoojaPaymentSession poojaPaymentSessionFromJson(Map<String, dynamic> json) {
  final checkout = _map(json['checkout']);
  return PoojaPaymentSession(
    id: '${json['id'] ?? ''}',
    bookingId: '${json['bookingId'] ?? ''}',
    keyId: '${checkout['keyId'] ?? ''}',
    orderId: '${checkout['orderId'] ?? json['gatewayOrderId'] ?? ''}',
    amountMinor: int.tryParse('${checkout['amountMinor'] ?? 0}') ?? 0,
    amount: _double(checkout['amount'] ?? json['amount']),
    currency: '${checkout['currency'] ?? json['currency'] ?? 'INR'}',
    status: '${json['status'] ?? 'pending'}',
  );
}
