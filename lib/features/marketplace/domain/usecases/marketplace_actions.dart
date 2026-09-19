import 'dart:typed_data';
import '../entities/marketplace_entities.dart';
import '../repositories/marketplace_repository.dart';

class MarketplaceActions {
  const MarketplaceActions(this.repository);
  final MarketplaceRepository repository;

  Future<List<MarketplaceItem>> browse(MarketplaceType type, {String? query}) => repository.publicItems(type, query: query);
  Future<MarketplaceItem> detail(MarketplaceType type, String id) => repository.publicDetail(type, id);
  Future<AccommodationAvailabilityQuote> checkAccommodationAvailability({required String identifier, required String checkIn, required String checkOut, required int guests, required int units}) => repository.accommodationAvailability(identifier: identifier, checkIn: checkIn, checkOut: checkOut, guests: guests, units: units);
  Future<List<MarketplaceBooking>> myBookings(MarketplaceType type) => repository.customerBookings(type);
  Future<MarketplaceBooking> booking(String id, {bool provider = false}) => repository.bookingDetail(id, provider: provider);
  Future<MarketplaceBooking> book(MarketplaceType type, Map<String, dynamic> body) => repository.createBooking(type, body);
  Future<void> bookingAction(String id, String action, {Map<String, dynamic>? body}) => repository.customerBookingAction(id, action, body: body);
  Future<void> review(String id, int rating, String comment, {String? title}) => repository.createReview(bookingId: id, rating: rating, comment: comment, title: title);
  Future<String> upload(Uint8List bytes, String name, String mime) => repository.uploadImage(bytes: bytes, fileName: name, mimeType: mime);
  Future<List<MarketplaceItem>> providerItems(MarketplaceType type) => repository.providerItems(type);
  Future<MarketplaceItem> providerItem(MarketplaceType type, String id) => repository.providerItem(type, id);
  Future<dynamic> providerCall(String op, {String? id, String? parentId, Map<String, dynamic>? body}) => repository.call(op, id: id, parentId: parentId, body: body);
  Future<List<MarketplaceBooking>> providerBookings(MarketplaceType type) => repository.providerBookings(type);
  Future<MarketplaceBooking> providerBookingAction(MarketplaceType type, String id, String action, {Map<String, dynamic>? body}) => repository.providerBookingAction(type, id, action, body: body);
}
