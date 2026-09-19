import 'dart:typed_data';
import '../entities/marketplace_entities.dart';
import '../repositories/marketplace_repository.dart';
class MarketplaceActions { const MarketplaceActions(this.r); final MarketplaceRepository r;
  Future<List<MarketplaceItem>> browse(MarketplaceType t,{String? query})=>r.publicItems(t,query:query);
  Future<MarketplaceItem> detail(MarketplaceType t,String id)=>r.publicDetail(t,id);
  Future<List<MarketplaceBooking>> myBookings(MarketplaceType t)=>r.customerBookings(t);
  Future<MarketplaceBooking> booking(String id,{bool provider=false})=>r.bookingDetail(id,provider:provider);
  Future<MarketplaceBooking> book(MarketplaceType t,Map<String,dynamic>b)=>r.createBooking(t,b);
  Future<void> bookingAction(String id,String a,{Map<String,dynamic>? body})=>r.customerBookingAction(id,a,body:body);
  Future<void> review(String id,int rating,String comment,{String? title})=>r.createReview(bookingId:id,rating:rating,comment:comment,title:title);
  Future<String> upload(Uint8List bytes,String name,String mime)=>r.uploadImage(bytes:bytes,fileName:name,mimeType:mime);
  Future<List<MarketplaceItem>> providerItems(MarketplaceType t)=>r.providerItems(t);
  Future<dynamic> providerCall(String op,{String? id,String? parentId,Map<String,dynamic>? body})=>r.call(op,id:id,parentId:parentId,body:body);
  Future<List<MarketplaceBooking>> providerBookings(MarketplaceType t)=>r.providerBookings(t);
  Future<MarketplaceBooking> providerBookingAction(MarketplaceType t,String id,String a,{Map<String,dynamic>? body})=>r.providerBookingAction(t,id,a,body:body);
}
