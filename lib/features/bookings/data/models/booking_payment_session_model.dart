import '../../domain/entities/booking_payment_session.dart';

BookingPaymentSession bookingPaymentSessionFromJson(Map<String, dynamic> json) {
  final checkout = json['checkout'] is Map ? json['checkout'] as Map : const {};
  return BookingPaymentSession(
    id: '${json['id'] ?? ''}',
    bookingId: '${json['bookingId'] ?? ''}',
    keyId: '${checkout['keyId'] ?? ''}',
    orderId: '${checkout['orderId'] ?? json['gatewayOrderId'] ?? ''}',
    amountMinor: int.tryParse('${checkout['amountMinor'] ?? 0}') ?? 0,
    amount:
        double.tryParse('${checkout['amount'] ?? json['amount'] ?? 0}') ?? 0,
    currency: '${checkout['currency'] ?? json['currency'] ?? 'INR'}',
    status: '${json['status'] ?? 'pending'}',
  );
}
