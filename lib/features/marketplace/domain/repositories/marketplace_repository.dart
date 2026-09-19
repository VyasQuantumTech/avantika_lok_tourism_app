import 'dart:typed_data';
import '../entities/marketplace_entities.dart';

abstract class MarketplaceRepository {
  Future<List<MarketplaceItem>> publicItems(MarketplaceType type, {String? query});
  Future<MarketplaceItem> publicDetail(MarketplaceType type, String id);
  Future<AccommodationAvailabilityQuote> accommodationAvailability({
    required String identifier,
    required String checkIn,
    required String checkOut,
    required int guests,
    required int units,
  });

  Future<List<MarketplaceBooking>> customerBookings(MarketplaceType type);
  Future<MarketplaceBooking> bookingDetail(String id, {bool provider = false});
  Future<MarketplaceBooking> createBooking(MarketplaceType type, Map<String, dynamic> body);
  Future<void> customerBookingAction(String id, String action, {Map<String, dynamic>? body});
  Future<void> createReview({required String bookingId, required int rating, required String comment, String? title});
  Future<String> uploadImage({required Uint8List bytes, required String fileName, required String mimeType});

  Future<List<MarketplaceItem>> providerItems(MarketplaceType type);
  Future<MarketplaceItem> providerItem(MarketplaceType type, String id);
  Future<dynamic> call(String operation, {String? id, String? parentId, Map<String, dynamic>? body});
  Future<List<MarketplaceBooking>> providerBookings(MarketplaceType type);
  Future<MarketplaceBooking> providerBookingAction(MarketplaceType type, String id, String action, {Map<String, dynamic>? body});
}
