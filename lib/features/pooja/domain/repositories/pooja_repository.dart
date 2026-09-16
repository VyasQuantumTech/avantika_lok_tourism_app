import 'dart:typed_data';

import '../entities/pooja_entities.dart';

abstract class PoojaRepository {
  Future<String> uploadPoojaImage({required Uint8List bytes, required String fileName, required String mimeType});
  Future<void> deleteUploadedPoojaImage(String mediaAssetId);
  Future<List<Pooja>> getPublicPoojas({String? query});
  Future<Pooja> getPoojaDetail(String identifier);

  Future<List<PoojaBooking>> getCustomerPoojaBookings();
  Future<PoojaBooking> getCustomerPoojaBooking(String bookingId);
  Future<PoojaBooking> createPoojaBooking({
    required String offeringId,
    required String serviceDate,
    required String startTime,
    required int participants,
    String? notes,
  });
  Future<String> getPoojaStartOtp(String bookingId);
  Future<String> getPoojaEndOtp(String bookingId);
  Future<PoojaPaymentSession> initiatePoojaPayment(String bookingId);
  Future<void> verifyPoojaPayment({required String paymentId, required String razorpayOrderId, required String razorpayPaymentId, required String razorpaySignature});
  Future<PoojaBooking> cancelCustomerBooking(String bookingId, String reason);
  Future<PoojaBooking> withdrawCustomerBooking(String bookingId);
  Future<void> submitPoojaReview({required String bookingId, required int rating, required String comment, String? title});

  Future<PanditPoojaDashboard> getPanditDashboard();
  Future<PanditOffering> createPanditOffering({
    required String name,
    required String description,
    required double priceAmount,
    required String currency,
    required int durationMinutes,
    required String serviceMode,
    String? shortDescription,
    String? notes,
    List<String> mediaAssetIds = const <String>[],
  });
  Future<PanditOffering> updatePanditOffering({
    required String offeringId,
    String? name,
    String? shortDescription,
    String? description,
    double? priceAmount,
    String? currency,
    int? durationMinutes,
    String? serviceMode,
    String? notes,
    bool? isActive,
    List<String>? mediaAssetIds,
  });
  Future<void> deletePanditOffering(String offeringId);

  Future<PanditAvailability> addAvailability({
    required int weekday,
    required String startTime,
    required String endTime,
  });
  Future<void> deleteAvailability(String availabilityId);

  Future<List<PoojaBooking>> getPanditBookings();
  Future<PoojaBooking> getPanditBooking(String bookingId);
  Future<PoojaBooking> acceptPanditBooking(String bookingId);
  Future<PoojaBooking> rejectPanditBooking(String bookingId, {String? reason});
  Future<PoojaBooking> cancelPanditBooking(String bookingId, String reason);
  Future<PoojaBooking> startPanditBooking(String bookingId, String otp);
  Future<PoojaBooking> endPanditBooking(String bookingId, String otp);
}
