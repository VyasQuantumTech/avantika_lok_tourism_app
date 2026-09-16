class ProviderAccountStatus {
  const ProviderAccountStatus({
    required this.isProvider,
    this.providerType,
    this.kycApplicationId,
    this.kycStatus,
  });

  final bool isProvider;
  final String? providerType;
  final String? kycApplicationId;
  final String? kycStatus;

  bool get isPandit => providerType == 'pandit';
  bool get isAccommodation => providerType == 'hotel_manager';
  bool get isTransport => providerType == 'vehicle_owner';
}
