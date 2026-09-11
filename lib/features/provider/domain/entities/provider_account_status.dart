class ProviderAccountStatus {
  const ProviderAccountStatus({
    required this.isProvider,
    this.providerType,
  });

  final bool isProvider;
  final String? providerType;

  bool get isPandit => providerType == 'pandit';
  bool get isAccommodation => providerType == 'hotel_manager';
  bool get isTransport => providerType == 'vehicle_owner';
}
