import '../repositories/booking_repository.dart';
import '../entities/booking_lifecycle.dart';
import '../entities/booking_payment_session.dart';

class BookingActions {
  const BookingActions(this.repository);
  final BookingRepository repository;
  Future<BookingLifecycle> lifecycle(String id) => repository.lifecycle(id);
  Future<String> otp(String id, {required bool end}) =>
      repository.otp(id, end: end);
  Future<BookingPaymentSession> initiatePayment(String id) =>
      repository.initiatePayment(id);
  Future<void> verifyPayment(
          {required String paymentId,
          required String orderId,
          required String gatewayPaymentId,
          required String signature}) =>
      repository.verifyPayment(
          paymentId: paymentId,
          orderId: orderId,
          gatewayPaymentId: gatewayPaymentId,
          signature: signature);
  Future<Map<String, dynamic>> tracking(String id) => repository.tracking(id);
}
