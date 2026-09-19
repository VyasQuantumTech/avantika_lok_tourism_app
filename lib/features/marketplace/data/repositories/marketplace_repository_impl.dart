import 'dart:typed_data';
import '../../domain/entities/marketplace_entities.dart';
import '../../domain/repositories/marketplace_repository.dart';
import '../datasources/marketplace_remote_data_source.dart';

class MarketplaceRepositoryImpl implements MarketplaceRepository {
  const MarketplaceRepositoryImpl(this.remote);
  final MarketplaceRemoteDataSource remote;

  @override
  Future<List<MarketplaceItem>> publicItems(MarketplaceType type, {String? query}) => remote.publicItems(type, query: query);
  @override
  Future<MarketplaceItem> publicDetail(MarketplaceType type, String id) => remote.publicDetail(type, id);
  @override
  Future<AccommodationAvailabilityQuote> accommodationAvailability({required String identifier, required String checkIn, required String checkOut, required int guests, required int units}) => remote.accommodationAvailability(identifier: identifier, checkIn: checkIn, checkOut: checkOut, guests: guests, units: units);
  @override
  Future<List<MarketplaceBooking>> customerBookings(MarketplaceType type) => remote.customerBookings(type);
  @override
  Future<MarketplaceBooking> bookingDetail(String id, {bool provider = false}) => remote.bookingDetail(id, provider: provider);
  @override
  Future<MarketplaceBooking> createBooking(MarketplaceType type, Map<String, dynamic> body) => remote.createBooking(type, body);
  @override
  Future<void> customerBookingAction(String id, String action, {Map<String, dynamic>? body}) => remote.customerBookingAction(id, action, body: body);
  @override
  Future<void> createReview({required String bookingId, required int rating, required String comment, String? title}) => remote.createReview(bookingId: bookingId, rating: rating, comment: comment, title: title);
  @override
  Future<String> uploadImage({required Uint8List bytes, required String fileName, required String mimeType}) => remote.uploadImage(bytes: bytes, fileName: fileName, mimeType: mimeType);
  @override
  Future<List<MarketplaceItem>> providerItems(MarketplaceType type) => remote.providerItems(type);
  @override
  Future<MarketplaceItem> providerItem(MarketplaceType type, String id) => remote.providerItem(type, id);
  @override
  Future<List<MarketplaceBooking>> providerBookings(MarketplaceType type) => remote.providerBookings(type);
  @override
  Future<MarketplaceBooking> providerBookingAction(MarketplaceType type, String id, String action, {Map<String, dynamic>? body}) => remote.providerBookingAction(type, id, action, body: body);

  @override
  Future<dynamic> call(String operation, {String? id, String? parentId, Map<String, dynamic>? body}) {
    final payload = body ?? <String, dynamic>{};
    switch (operation) {
      case 'saveAccommodation': return remote.saveAccommodation(payload, id: id);
      case 'deleteAccommodation': return remote.deleteAccommodation(id!);
      case 'saveUnit': return remote.saveAccommodationUnit(parentId!, payload, unitId: id);
      case 'deleteUnit': return remote.deleteAccommodationUnit(id!);
      case 'inventory': return remote.upsertInventory(parentId!, payload);
      case 'saveRate': return remote.saveRate(parentId!, payload, rateId: id);
      case 'deleteRate': return remote.deleteRate(id!);
      case 'submitAccommodation': return remote.submitAccommodation(id!, body: payload);
      case 'transportProfile': return remote.transportProfile();
      case 'saveTransportProfile': return remote.saveTransportProfile(payload);
      case 'saveVehicle': return remote.saveVehicle(payload, id: id);
      case 'deleteVehicle': return remote.deleteVehicle(id!);
      case 'saveDocument': return remote.saveVehicleDocument(parentId!, payload, documentId: id);
      case 'deleteDocument': return remote.deleteVehicleDocument(parentId!, id!);
      case 'availability': return remote.upsertVehicleAvailability(parentId!, payload);
      case 'savePricing': return remote.saveVehiclePricing(parentId!, payload, pricingId: id);
      case 'deletePricing': return remote.deleteVehiclePricing(parentId!, id!);
      case 'saveRoute': return remote.saveRoute(payload, routeId: id);
      case 'deleteRoute': return remote.deleteRoute(id!);
      case 'submitVehicle': return remote.submitVehicle(id!);
      default: throw ArgumentError('Unknown marketplace operation: $operation');
    }
  }
}
