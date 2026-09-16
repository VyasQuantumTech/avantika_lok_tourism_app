import 'dart:typed_data';

import '../../domain/entities/pooja_entities.dart';
import '../../domain/repositories/pooja_repository.dart';
import '../datasources/pooja_remote_data_source.dart';

class PoojaRepositoryImpl implements PoojaRepository {
  const PoojaRepositoryImpl(this._remote);
  final PoojaRemoteDataSource _remote;

  @override
  Future<String> uploadPoojaImage({required Uint8List bytes, required String fileName, required String mimeType}) =>
      _remote.uploadPoojaImage(bytes: bytes, fileName: fileName, mimeType: mimeType);

  @override
  Future<void> deleteUploadedPoojaImage(String mediaAssetId) =>
      _remote.deleteUploadedPoojaImage(mediaAssetId);

  @override
  Future<List<Pooja>> getPublicPoojas({String? query}) =>
      _remote.getPublicPoojas(query: query);

  @override
  Future<Pooja> getPoojaDetail(String identifier) =>
      _remote.getPoojaDetail(identifier);

  @override
  Future<List<PoojaBooking>> getCustomerPoojaBookings() =>
      _remote.getCustomerPoojaBookings();

  @override
  Future<PoojaBooking> getCustomerPoojaBooking(String bookingId) =>
      _remote.getCustomerPoojaBooking(bookingId);

  @override
  Future<PoojaBooking> createPoojaBooking({
    required String offeringId,
    required String serviceDate,
    required String startTime,
    required int participants,
    String? notes,
  }) =>
      _remote.createPoojaBooking(
        offeringId: offeringId,
        serviceDate: serviceDate,
        startTime: startTime,
        participants: participants,
        notes: notes,
      );

  @override
  Future<String> getPoojaStartOtp(String bookingId) =>
      _remote.getPoojaStartOtp(bookingId);

  @override
  Future<String> getPoojaEndOtp(String bookingId) =>
      _remote.getPoojaEndOtp(bookingId);

  @override
  Future<PoojaPaymentSession> initiatePoojaPayment(String bookingId) =>
      _remote.initiatePoojaPayment(bookingId);

  @override
  Future<void> verifyPoojaPayment({required String paymentId, required String razorpayOrderId, required String razorpayPaymentId, required String razorpaySignature}) =>
      _remote.verifyPoojaPayment(paymentId: paymentId, razorpayOrderId: razorpayOrderId, razorpayPaymentId: razorpayPaymentId, razorpaySignature: razorpaySignature);

  @override
  Future<PoojaBooking> cancelCustomerBooking(
    String bookingId,
    String reason,
  ) =>
      _remote.cancelCustomerBooking(bookingId, reason);

  @override
  Future<PoojaBooking> withdrawCustomerBooking(String bookingId) =>
      _remote.withdrawCustomerBooking(bookingId);

  @override
  Future<void> submitPoojaReview({required String bookingId, required int rating, required String comment, String? title}) =>
      _remote.submitPoojaReview(bookingId: bookingId, rating: rating, comment: comment, title: title);

  @override
  Future<PanditPoojaDashboard> getPanditDashboard() =>
      _remote.getPanditDashboard();

  @override
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
  }) =>
      _remote.createPanditOffering(
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

  @override
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
  }) =>
      _remote.updatePanditOffering(
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

  @override
  Future<void> deletePanditOffering(String offeringId) =>
      _remote.deletePanditOffering(offeringId);

  @override
  Future<PanditAvailability> addAvailability({
    required int weekday,
    required String startTime,
    required String endTime,
  }) =>
      _remote.addAvailability(
        weekday: weekday,
        startTime: startTime,
        endTime: endTime,
      );

  @override
  Future<void> deleteAvailability(String availabilityId) =>
      _remote.deleteAvailability(availabilityId);

  @override
  Future<List<PoojaBooking>> getPanditBookings() =>
      _remote.getPanditBookings();

  @override
  Future<PoojaBooking> getPanditBooking(String bookingId) =>
      _remote.getPanditBooking(bookingId);

  @override
  Future<PoojaBooking> acceptPanditBooking(String bookingId) =>
      _remote.acceptPanditBooking(bookingId);

  @override
  Future<PoojaBooking> rejectPanditBooking(
    String bookingId, {
    String? reason,
  }) =>
      _remote.rejectPanditBooking(bookingId, reason: reason);

  @override
  Future<PoojaBooking> cancelPanditBooking(
    String bookingId,
    String reason,
  ) =>
      _remote.cancelPanditBooking(bookingId, reason);

  @override
  Future<PoojaBooking> startPanditBooking(String bookingId, String otp) =>
      _remote.startPanditBooking(bookingId, otp);

  @override
  Future<PoojaBooking> endPanditBooking(String bookingId, String otp) =>
      _remote.endPanditBooking(bookingId, otp);
}
