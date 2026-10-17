class BookingPaymentSession {
  const BookingPaymentSession({
    required this.id,
    required this.bookingId,
    required this.keyId,
    required this.orderId,
    required this.amountMinor,
    required this.amount,
    required this.currency,
    required this.status,
    this.checkoutConfig = const {},
  });
  final String id;
  final String bookingId;
  final String keyId;
  final String orderId;
  final int amountMinor;
  final double amount;
  final String currency;
  final String status;
  final Map<String, dynamic> checkoutConfig;
}
