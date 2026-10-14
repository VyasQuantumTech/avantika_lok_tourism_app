import '../../../../core/ network/api_client.dart';
import '../../../../core/ network/endpoints.dart';

class BookingRemoteDataSource {
  const BookingRemoteDataSource(this.api);
  final ApiClient api;

  Future<Map<String, dynamic>> detail(String id) async =>
      _data(await api.get('${Endpoints.bookings}/${Uri.encodeComponent(id)}',
          authenticated: true));
  Future<Map<String, dynamic>> otp(String id, {required bool end}) async =>
      _data(await api.get(
          '${Endpoints.bookings}/${Uri.encodeComponent(id)}/${end ? 'end' : 'start'}-otp',
          authenticated: true));
  Future<Map<String, dynamic>> initiatePayment(String id) async =>
      _data(await api.post(Endpoints.payments,
          authenticated: true, body: {'bookingId': id}));
  Future<void> verifyPayment(
      {required String paymentId,
      required String orderId,
      required String gatewayPaymentId,
      required String signature}) async {
    await api.post(
        '${Endpoints.payments}/${Uri.encodeComponent(paymentId)}/verify',
        authenticated: true,
        body: {
          'razorpayOrderId': orderId,
          'razorpayPaymentId': gatewayPaymentId,
          'razorpaySignature': signature
        });
  }

  Future<Map<String, dynamic>> tracking(String id) async => _data(await api.get(
      '${Endpoints.bookings}/${Uri.encodeComponent(id)}/transport/tracking',
      authenticated: true));

  Map<String, dynamic> _data(Map<String, dynamic> response) =>
      response['data'] is Map
          ? Map<String, dynamic>.from(response['data'] as Map)
          : response;
}
