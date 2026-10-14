import '../../../../core/errors/exceptions.dart';
import '../models/booking_payment_session_model.dart';
import '../../domain/entities/booking_payment_session.dart';
import '../../domain/entities/booking_lifecycle.dart';
import '../../domain/repositories/booking_repository.dart';
import '../datasources/booking_remote_data_source.dart';
import '../models/booking_lifecycle_model.dart';

class BookingRepositoryImpl implements BookingRepository {
  const BookingRepositoryImpl(this.remote);
  final BookingRemoteDataSource remote;

  @override
  Future<BookingLifecycle> lifecycle(String id) async {
    final data = await remote.detail(id);
    return bookingLifecycleFromJson(data['booking'] is Map
        ? Map<String, dynamic>.from(data['booking'] as Map)
        : data);
  }

  @override
  Future<String> otp(String id, {required bool end}) async {
    final current = await lifecycle(id);
    if (end ? !current.canFetchEndOtp : !current.canFetchStartOtp) {
      throw ApiException(end
          ? 'Completion code is available after verified service start.'
          : 'Start code is available after booking confirmation.');
    }
    return '${(await remote.otp(id, end: end))['otp'] ?? ''}';
  }

  @override
  Future<BookingPaymentSession> initiatePayment(String id) async {
    if (!(await lifecycle(id)).canPay) {
      throw const ApiException(
          'Online payment is not available for this booking. Refresh the booking status.');
    }
    final data = await remote.initiatePayment(id);
    return bookingPaymentSessionFromJson(data['payment'] is Map
        ? Map<String, dynamic>.from(data['payment'] as Map)
        : data);
  }

  @override
  Future<void> verifyPayment(
          {required String paymentId,
          required String orderId,
          required String gatewayPaymentId,
          required String signature}) =>
      remote.verifyPayment(
          paymentId: paymentId,
          orderId: orderId,
          gatewayPaymentId: gatewayPaymentId,
          signature: signature);
  @override
  Future<Map<String, dynamic>> tracking(String id) => remote.tracking(id);
}
