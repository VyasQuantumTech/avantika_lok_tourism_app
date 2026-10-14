class BookingLifecycle {
  const BookingLifecycle({
    required this.status,
    required this.providerDecision,
    this.paymentPolicy = 'disabled',
    this.paymentStatus = 'not_started',
    this.startedAt,
    this.endedAt,
    this.holdExpiresAt,
    this.serviceName,
    this.providerName,
    this.unitName,
  });

  final String status;
  final String providerDecision;
  final String paymentPolicy;
  final String paymentStatus;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime? holdExpiresAt;
  final String? serviceName;
  final String? providerName;
  final String? unitName;

  bool get active =>
      const {'pending', 'confirmed'}.contains(status) &&
      providerDecision != 'rejected' &&
      endedAt == null;
  bool get completed => status == 'completed' || endedAt != null;
  bool get awaitingProvider =>
      status == 'pending' && providerDecision == 'pending';
  bool get canCancel => active && startedAt == null;
  bool get canStart =>
      status == 'confirmed' &&
      providerDecision == 'accepted' &&
      startedAt == null &&
      endedAt == null;
  bool get canComplete =>
      active && providerDecision == 'accepted' && startedAt != null;
  bool get canFetchStartOtp => canStart;
  bool get canFetchEndOtp => canComplete;
  bool get paymentSettled => const {
        'captured',
        'partially_refunded',
        'refunded'
      }.contains(paymentStatus);
  bool get canPay =>
      active &&
      startedAt == null &&
      paymentPolicy == 'online_required' &&
      !paymentSettled;

  String get paymentMessage => switch (paymentPolicy) {
        'online_required' => paymentSettled
            ? 'Payment received. Confirmation also requires provider acceptance.'
            : 'Online payment and provider acceptance are required to confirm this booking.',
        'pay_on_arrival' =>
          'Pay the provider on arrival. Online payment is not required.',
        _ => 'Online payment is disabled for this booking.',
      };

  String get statusLabel {
    if (completed) return 'Completed';
    if (!active) return status.replaceAll('_', ' ');
    if (startedAt != null) return 'Service in progress';
    if (status == 'confirmed') return 'Confirmed';
    if (awaitingProvider) return 'Waiting for provider';
    if (providerDecision == 'accepted' && canPay) return 'Waiting for payment';
    return 'Pending confirmation';
  }
}
