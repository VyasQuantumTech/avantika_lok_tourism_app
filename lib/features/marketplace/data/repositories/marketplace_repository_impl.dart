import 'dart:typed_data';
import '../../domain/entities/marketplace_entities.dart';
import '../../domain/repositories/marketplace_repository.dart';
import '../datasources/marketplace_remote_data_source.dart';
class MarketplaceRepositoryImpl implements MarketplaceRepository {
  const MarketplaceRepositoryImpl(this.r); final MarketplaceRemoteDataSource r;
  @override Future<List<MarketplaceItem>> publicItems(MarketplaceType t,{String? query})=>r.publicItems(t,query:query);
  @override Future<MarketplaceItem> publicDetail(MarketplaceType t,String id)=>r.publicDetail(t,id);
  @override Future<List<MarketplaceBooking>> customerBookings(MarketplaceType t)=>r.customerBookings(t);
  @override Future<MarketplaceBooking> bookingDetail(String id,{bool provider=false})=>r.bookingDetail(id,provider:provider);
  @override Future<MarketplaceBooking> createBooking(MarketplaceType t,Map<String,dynamic>b)=>r.createBooking(t,b);
  @override Future<void> customerBookingAction(String id,String a,{Map<String,dynamic>? body})=>r.customerBookingAction(id,a,body:body);
  @override Future<void> createReview({required String bookingId,required int rating,required String comment,String? title})=>r.createReview(bookingId:bookingId,rating:rating,comment:comment,title:title);
  @override Future<String> uploadImage({required Uint8List bytes,required String fileName,required String mimeType})=>r.uploadImage(bytes:bytes,fileName:fileName,mimeType:mimeType);
  @override Future<List<MarketplaceItem>> providerItems(MarketplaceType t)=>r.providerItems(t);
  @override Future<List<MarketplaceBooking>> providerBookings(MarketplaceType t)=>r.providerBookings(t);
  @override Future<MarketplaceBooking> providerBookingAction(MarketplaceType t,String id,String a,{Map<String,dynamic>? body})=>r.providerBookingAction(t,id,a,body:body);
  @override Future<dynamic> call(String op,{String? id,String? parentId,Map<String,dynamic>? body}) { final b=body??<String,dynamic>{}; switch(op){
    case 'saveAccommodation': return r.saveAccommodation(b,id:id); case 'deleteAccommodation': return r.deleteAccommodation(id!); case 'saveUnit': return r.saveAccommodationUnit(parentId!,b,unitId:id); case 'deleteUnit': return r.deleteAccommodationUnit(id!); case 'inventory': return r.upsertInventory(parentId!,b); case 'saveRate': return r.saveRate(parentId!,b,rateId:id); case 'deleteRate': return r.deleteRate(parentId!,id!); case 'submitAccommodation': return r.submitAccommodation(id!);
    case 'transportProfile': return r.transportProfile(); case 'saveTransportProfile': return r.saveTransportProfile(b); case 'saveVehicle': return r.saveVehicle(b,id:id); case 'deleteVehicle': return r.deleteVehicle(id!); case 'saveDocument': return r.saveVehicleDocument(parentId!,b,documentId:id); case 'deleteDocument': return r.deleteVehicleDocument(parentId!,id!); case 'availability': return r.upsertVehicleAvailability(parentId!,b); case 'savePricing': return r.saveVehiclePricing(parentId!,b,pricingId:id); case 'deletePricing': return r.deleteVehiclePricing(parentId!,id!); case 'saveRoute': return r.saveRoute(b,routeId:id); case 'deleteRoute': return r.deleteRoute(id!); case 'submitVehicle': return r.submitVehicle(id!); default: throw ArgumentError('Unknown marketplace operation: $op'); }
  }
}
