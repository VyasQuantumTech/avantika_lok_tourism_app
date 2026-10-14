import '../entities/booking_lifecycle.dart';
import '../entities/booking_payment_session.dart';

abstract class BookingRepository {
  Future<BookingLifecycle> lifecycle(String id);
  Future<String> otp(String id, {required bool end});
  Future<BookingPaymentSession> initiatePayment(String id);
  Future<void> verifyPayment(
      {required String paymentId,
      required String orderId,
      required String gatewayPaymentId,
      required String signature});
  Future<Map<String, dynamic>> tracking(String id);
}
