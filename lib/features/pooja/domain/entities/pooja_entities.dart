class PoojaMedia {
  const PoojaMedia({required this.id, required this.url, this.sortOrder = 0});

  final String id;
  final String url;
  final int sortOrder;
}

class PoojaReviewSummary {
  const PoojaReviewSummary({required this.count, required this.averageRating});

  final int count;
  final double averageRating;
}

class PoojaOffering {
  const PoojaOffering({
    required this.id,
    required this.panditId,
    required this.panditName,
    required this.priceAmount,
    required this.currency,
    required this.serviceMode,
    this.durationMinutes,
    this.city,
    this.state,
    this.approvalStatus,
    this.isActive = true,
  });

  final String id;
  final String panditId;
  final String panditName;
  final double priceAmount;
  final String currency;
  final String serviceMode;
  final int? durationMinutes;
  final String? city;
  final String? state;
  final String? approvalStatus;
  final bool isActive;
}

class Pooja {
  const Pooja({
    required this.id,
    required this.name,
    required this.slug,
    required this.currency,
    required this.offerings,
    this.shortDescription,
    this.description,
    this.defaultDurationMinutes,
    this.defaultPriceAmount,
    this.coverUrl,
    this.status,
    this.isFeatured = false,
    this.media = const <PoojaMedia>[],
    this.reviewSummary = const PoojaReviewSummary(count: 0, averageRating: 0),
  });

  final String id;
  final String name;
  final String slug;
  final String currency;
  final String? shortDescription;
  final String? description;
  final int? defaultDurationMinutes;
  final double? defaultPriceAmount;
  final String? coverUrl;
  final String? status;
  final bool isFeatured;
  final List<PoojaMedia> media;
  final PoojaReviewSummary reviewSummary;
  final List<PoojaOffering> offerings;
}

class PanditAvailability {
  const PanditAvailability({
    required this.id,
    required this.weekday,
    required this.startTime,
    required this.endTime,
    required this.timezone,
    required this.isActive,
  });

  final String id;
  final int weekday;
  final String startTime;
  final String endTime;
  final String timezone;
  final bool isActive;
}

class PanditOffering {
  const PanditOffering({
    required this.id,
    required this.poojaId,
    required this.name,
    required this.priceAmount,
    required this.currency,
    required this.serviceMode,
    required this.approvalStatus,
    required this.isActive,
    this.durationMinutes,
    this.shortDescription,
    this.description,
    this.moderationNote,
    this.media = const <PoojaMedia>[],
  });

  final String id;
  final String poojaId;
  final String name;
  final double priceAmount;
  final String currency;
  final String serviceMode;
  final String approvalStatus;
  final bool isActive;
  final int? durationMinutes;
  final String? shortDescription;
  final String? description;
  final String? moderationNote;
  final List<PoojaMedia> media;
}

class PanditPoojaDashboard {
  const PanditPoojaDashboard({
    required this.panditId,
    required this.isActive,
    required this.offerings,
    required this.availability,
    required this.upcomingBookings,
    required this.pendingActionBookings,
    required this.completedBookings,
    required this.estimatedGross,
    required this.currency,
  });

  final String panditId;
  final bool isActive;
  final List<PanditOffering> offerings;
  final List<PanditAvailability> availability;
  final int upcomingBookings;
  final int pendingActionBookings;
  final int completedBookings;
  final double estimatedGross;
  final String currency;
}

class PoojaBooking {
  const PoojaBooking({
    required this.id,
    required this.bookingNumber,
    required this.status,
    required this.providerDecision,
    required this.serviceDate,
    required this.totalAmount,
    required this.currency,
    this.startTime,
    this.endTime,
    this.panditPoojaId,
    this.notes,
    this.poojaStartOtp,
    this.poojaEndOtp,
    this.serviceStartedAt,
    this.serviceEndedAt,
    this.pricingSnapshot = const <String, dynamic>{},
    this.customerSnapshot = const <String, dynamic>{},
  });

  final String id;
  final String bookingNumber;
  final String status;
  final String providerDecision;
  final String serviceDate;
  final String? startTime;
  final String? endTime;
  final String? panditPoojaId;
  final double totalAmount;
  final String currency;
  final String? notes;
  final String? poojaStartOtp;
  final String? poojaEndOtp;
  final DateTime? serviceStartedAt;
  final DateTime? serviceEndedAt;
  final Map<String, dynamic> pricingSnapshot;
  final Map<String, dynamic> customerSnapshot;

  bool get isAwaitingPandit =>
      status == 'pending' && providerDecision == 'pending';

  bool get hasCustomerOtpAccess =>
      (status == 'pending' || status == 'confirmed') &&
      providerDecision != 'rejected' &&
      serviceEndedAt == null;

  bool get canShowStartOtp =>
      hasCustomerOtpAccess && poojaStartOtp?.trim().isNotEmpty == true;

  // Backward-compatible alias used by existing UI.
  bool get canShowOtp => canShowStartOtp;

  bool get isInProgress =>
      serviceStartedAt != null && serviceEndedAt == null;

  bool get isCompleted =>
      serviceEndedAt != null || status == 'completed';

  bool get canShowEndOtp =>
      hasCustomerOtpAccess && poojaEndOtp?.trim().isNotEmpty == true;

  bool get canCustomerCancel => status == 'pending' || status == 'confirmed';

  bool get canPanditAccept =>
      status == 'pending' && providerDecision == 'pending';

  bool get canPanditStart =>
      (status == 'pending' || status == 'confirmed') &&
      providerDecision == 'accepted' &&
      serviceStartedAt == null &&
      serviceEndedAt == null;

  bool get canPanditEnd =>
      providerDecision == 'accepted' &&
      serviceStartedAt != null &&
      serviceEndedAt == null &&
      status != 'cancelled' &&
      status != 'completed';

  bool get showPanditPoojaControls =>
      providerDecision == 'accepted' &&
      status != 'cancelled' &&
      status != 'completed' &&
      serviceEndedAt == null;
}


class PoojaPaymentSession {
  const PoojaPaymentSession({
    required this.id, required this.bookingId, required this.keyId,
    required this.orderId, required this.amountMinor, required this.amount,
    required this.currency, required this.status,
  });
  final String id;
  final String bookingId;
  final String keyId;
  final String orderId;
  final int amountMinor;
  final double amount;
  final String currency;
  final String status;
}
