import 'profile_snapshot.dart';

class CustomerDashboardSummary {
  const CustomerDashboardSummary({
    required this.totalBookings,
    required this.upcomingBookings,
    required this.completedBookings,
    required this.closedWithoutCompletion,
    required this.reviewsGiven,
    required this.totalFavorites,
    required this.placeFavorites,
    required this.accommodationFavorites,
    required this.transportFavorites,
    required this.poojaFavorites,
    required this.packageFavorites,
  });

  final int totalBookings;
  final int upcomingBookings;
  final int completedBookings;
  final int closedWithoutCompletion;
  final int reviewsGiven;
  final int totalFavorites;
  final int placeFavorites;
  final int accommodationFavorites;
  final int transportFavorites;
  final int poojaFavorites;
  final int packageFavorites;
}

class ProviderFinancialSummary {
  const ProviderFinancialSummary({
    required this.currency,
    required this.grossCaptured,
    required this.processedRefunds,
    required this.netCollected,
    this.payoutBalance,
    this.note,
  });

  final String currency;
  final double grossCaptured;
  final double processedRefunds;
  final double netCollected;
  final double? payoutBalance;
  final String? note;
}

class ProviderRatingSummary {
  const ProviderRatingSummary({required this.count, this.averageRating});
  final int count;
  final double? averageRating;
}

class ProviderDomainSummary {
  const ProviderDomainSummary({
    required this.configured,
    this.active,
    this.status,
    this.offerings = 0,
    this.weeklyAvailabilityRules = 0,
    this.vehicleTotal = 0,
    this.vehicleActive = 0,
    this.routes = 0,
    this.futureAvailabilityRows = 0,
    this.accommodationTotal = 0,
    this.accommodationActive = 0,
    this.units = 0,
    this.packageTotal = 0,
    this.packageActive = 0,
  });

  final bool configured;
  final bool? active;
  final String? status;
  final int offerings;
  final int weeklyAvailabilityRules;
  final int vehicleTotal;
  final int vehicleActive;
  final int routes;
  final int futureAvailabilityRows;
  final int accommodationTotal;
  final int accommodationActive;
  final int units;
  final int packageTotal;
  final int packageActive;
}

class ProviderDashboardSummary {
  const ProviderDashboardSummary({
    required this.providerType,
    required this.capabilities,
    required this.kycStatus,
    this.kycApplicationId,
    required this.totalBookings,
    required this.upcomingBookings,
    required this.pendingActionBookings,
    required this.completedBookings,
    required this.ratings,
    required this.financial,
    required this.domain,
  });

  final String providerType;
  final List<String> capabilities;
  final String kycStatus;
  final String? kycApplicationId;
  final int totalBookings;
  final int upcomingBookings;
  final int pendingActionBookings;
  final int completedBookings;
  final ProviderRatingSummary ratings;
  final ProviderFinancialSummary financial;
  final ProviderDomainSummary domain;
}

class ProfileDashboard {
  const ProfileDashboard({
    required this.identity,
    required this.customer,
    this.provider,
  });

  final ProfileSnapshot identity;
  final CustomerDashboardSummary customer;
  final ProviderDashboardSummary? provider;
}
