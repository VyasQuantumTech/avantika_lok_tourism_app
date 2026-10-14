import '../../../bookings/domain/entities/booking_payment_session.dart';
import '../../../bookings/domain/entities/booking_lifecycle.dart';

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
    this.serviceValues = const [],
  });

  final String panditId;
  final bool isActive;
  final List<PanditOffering> offerings;
  final List<PanditAvailability> availability;
  final int upcomingBookings;
  final int pendingActionBookings;
  final int completedBookings;
  final double? estimatedGross;
  final String? currency;
  final List<PoojaServiceValue> serviceValues;
}

class PoojaServiceValue {
  const PoojaServiceValue({required this.currency, required this.amount});
  final String currency;
  final double amount;
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
    this.lifecycle,
    this.poojaStartOtp,
    this.poojaEndOtp,
    this.serviceStartedAt,
    this.serviceEndedAt,
    this.serviceImageUrl,
    this.pricingSnapshot = const <String, dynamic>{},
    this.customerSnapshot = const <String, dynamic>{},
  });

  final String? serviceImageUrl;
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
  final BookingLifecycle? lifecycle;
  BookingLifecycle get state =>
      lifecycle ??
      BookingLifecycle(
          status: status,
          providerDecision: providerDecision,
          startedAt: serviceStartedAt,
          endedAt: serviceEndedAt);
  final String? poojaStartOtp;
  final String? poojaEndOtp;
  final DateTime? serviceStartedAt;
  final DateTime? serviceEndedAt;
  final Map<String, dynamic> pricingSnapshot;
  final Map<String, dynamic> customerSnapshot;

  bool get isAwaitingPandit => state.awaitingProvider;
  bool get hasCustomerOtpAccess =>
      state.canFetchStartOtp || state.canFetchEndOtp;
  bool get canShowStartOtp =>
      state.canFetchStartOtp && poojaStartOtp?.isNotEmpty == true;
  bool get canShowOtp => canShowStartOtp;
  bool get isInProgress => state.active && serviceStartedAt != null;
  bool get isCompleted => state.completed;
  bool get canShowEndOtp =>
      state.canFetchEndOtp && poojaEndOtp?.isNotEmpty == true;
  bool get canCustomerCancel => state.canCancel;
  bool get canPanditAccept => state.awaitingProvider;
  bool get canPanditStart => state.canStart;
  bool get canPanditEnd => state.canComplete;
  bool get showPanditPoojaControls => state.canStart || state.canComplete;
}

// Compatibility name for the existing pooja repository and route contracts.
typedef PoojaPaymentSession = BookingPaymentSession;
