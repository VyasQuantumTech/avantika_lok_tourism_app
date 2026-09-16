import 'dart:typed_data';

import '../entities/pooja_entities.dart';
import '../repositories/pooja_repository.dart';

class CustomerPoojaActions {
  const CustomerPoojaActions(this._repository);
  final PoojaRepository _repository;

  Future<List<Pooja>> list({String? query}) =>
      _repository.getPublicPoojas(query: query);

  Future<Pooja> detail(String identifier) =>
      _repository.getPoojaDetail(identifier);

  Future<List<PoojaBooking>> bookings() =>
      _repository.getCustomerPoojaBookings();

  Future<PoojaBooking> booking(String id) =>
      _repository.getCustomerPoojaBooking(id);

  Future<PoojaBooking> book({
    required String offeringId,
    required String serviceDate,
    required String startTime,
    required int participants,
    String? notes,
  }) =>
      _repository.createPoojaBooking(
        offeringId: offeringId,
        serviceDate: serviceDate,
        startTime: startTime,
        participants: participants,
        notes: notes,
      );

  Future<String> startOtp(String bookingId) =>
      _repository.getPoojaStartOtp(bookingId);

  Future<String> endOtp(String bookingId) =>
      _repository.getPoojaEndOtp(bookingId);

  Future<PoojaPaymentSession> initiatePayment(String bookingId) =>
      _repository.initiatePoojaPayment(bookingId);

  Future<void> verifyPayment({required String paymentId, required String razorpayOrderId, required String razorpayPaymentId, required String razorpaySignature}) =>
      _repository.verifyPoojaPayment(paymentId: paymentId, razorpayOrderId: razorpayOrderId, razorpayPaymentId: razorpayPaymentId, razorpaySignature: razorpaySignature);

  Future<PoojaBooking> cancel(String bookingId, String reason) =>
      _repository.cancelCustomerBooking(bookingId, reason);

  Future<PoojaBooking> withdraw(String bookingId) =>
      _repository.withdrawCustomerBooking(bookingId);

  Future<void> review({required String bookingId, required int rating, required String comment, String? title}) =>
      _repository.submitPoojaReview(bookingId: bookingId, rating: rating, comment: comment, title: title);
}

class PanditPoojaActions {

  const PanditPoojaActions(this._repository);
  final PoojaRepository _repository;

  Future<String> uploadImage({required Uint8List bytes, required String fileName, required String mimeType}) =>
      _repository.uploadPoojaImage(bytes: bytes, fileName: fileName, mimeType: mimeType);

  Future<void> deleteUploadedImage(String mediaAssetId) =>
      _repository.deleteUploadedPoojaImage(mediaAssetId);

  Future<PanditPoojaDashboard> dashboard() =>
      _repository.getPanditDashboard();

  Future<PanditOffering> createOffering({
    required String name,
    required String description,
    required double priceAmount,
    required String currency,
    required int durationMinutes,
    required String serviceMode,
    String? shortDescription,
    String? notes,
    List<String> mediaAssetIds = const <String>[],
  }) =>
      _repository.createPanditOffering(
        name: name,
        description: description,
        priceAmount: priceAmount,
        currency: currency,
        durationMinutes: durationMinutes,
        serviceMode: serviceMode,
        shortDescription: shortDescription,
        notes: notes,
        mediaAssetIds: mediaAssetIds,
      );

  Future<PanditOffering> updateOffering({
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
  }) =>
      _repository.updatePanditOffering(
        offeringId: offeringId,
        name: name,
        shortDescription: shortDescription,
        description: description,
        priceAmount: priceAmount,
        currency: currency,
        durationMinutes: durationMinutes,
        serviceMode: serviceMode,
        notes: notes,
        isActive: isActive,
        mediaAssetIds: mediaAssetIds,
      );

  Future<void> deleteOffering(String id) =>
      _repository.deletePanditOffering(id);

  Future<PanditAvailability> addAvailability({
    required int weekday,
    required String startTime,
    required String endTime,
  }) =>
      _repository.addAvailability(
        weekday: weekday,
        startTime: startTime,
        endTime: endTime,
      );

  Future<void> deleteAvailability(String id) =>
      _repository.deleteAvailability(id);

  Future<List<PoojaBooking>> bookings() =>
      _repository.getPanditBookings();

  Future<PoojaBooking> booking(String id) =>
      _repository.getPanditBooking(id);

  Future<PoojaBooking> accept(String id) =>
      _repository.acceptPanditBooking(id);

  Future<PoojaBooking> reject(String id, {String? reason}) =>
      _repository.rejectPanditBooking(id, reason: reason);

  Future<PoojaBooking> cancel(String id, String reason) =>
      _repository.cancelPanditBooking(id, reason);

  Future<PoojaBooking> start(String id, String otp) =>
      _repository.startPanditBooking(id, otp);

  Future<PoojaBooking> end(String id, String otp) =>
      _repository.endPanditBooking(id, otp);
}
