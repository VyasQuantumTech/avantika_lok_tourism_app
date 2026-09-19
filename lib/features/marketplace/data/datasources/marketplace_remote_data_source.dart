import 'dart:typed_data';
import '../../../../core/ network/api_client.dart';
import '../../../../core/ network/endpoints.dart';
import '../../domain/entities/marketplace_entities.dart';

abstract class MarketplaceRemoteDataSource {
  Future<List<MarketplaceItem>> publicItems(MarketplaceType type,{String? query});
  Future<MarketplaceItem> publicDetail(MarketplaceType type,String id);
  Future<List<MarketplaceBooking>> customerBookings(MarketplaceType type);
  Future<MarketplaceBooking> bookingDetail(String id,{bool provider=false});
  Future<MarketplaceBooking> createBooking(MarketplaceType type,Map<String,dynamic> body);
  Future<void> customerBookingAction(String id,String action,{Map<String,dynamic>? body});
  Future<void> createReview({required String bookingId,required int rating,required String comment,String? title});
  Future<String> uploadImage({required Uint8List bytes,required String fileName,required String mimeType});

  Future<List<MarketplaceItem>> providerItems(MarketplaceType type);
  Future<MarketplaceItem> saveAccommodation(Map<String,dynamic> body,{String? id});
  Future<void> deleteAccommodation(String id);
  Future<Map<String,dynamic>> saveAccommodationUnit(String accommodationId,Map<String,dynamic> body,{String? unitId});
  Future<void> deleteAccommodationUnit(String unitId);
  Future<Map<String,dynamic>> upsertInventory(String unitId,Map<String,dynamic> body);
  Future<Map<String,dynamic>> saveRate(String unitId,Map<String,dynamic> body,{String? rateId});
  Future<void> deleteRate(String unitId,String rateId);
  Future<void> submitAccommodation(String id);

  Future<Map<String,dynamic>> transportProfile();
  Future<Map<String,dynamic>> saveTransportProfile(Map<String,dynamic> body);
  Future<Map<String,dynamic>> saveVehicle(Map<String,dynamic> body,{String? id});
  Future<void> deleteVehicle(String id);
  Future<Map<String,dynamic>> saveVehicleDocument(String vehicleId,Map<String,dynamic> body,{String? documentId});
  Future<void> deleteVehicleDocument(String vehicleId,String documentId);
  Future<Map<String,dynamic>> upsertVehicleAvailability(String vehicleId,Map<String,dynamic> body);
  Future<Map<String,dynamic>> saveVehiclePricing(String vehicleId,Map<String,dynamic> body,{String? pricingId});
  Future<void> deleteVehiclePricing(String vehicleId,String pricingId);
  Future<Map<String,dynamic>> saveRoute(Map<String,dynamic> body,{String? routeId});
  Future<void> deleteRoute(String routeId);
  Future<void> submitVehicle(String id);

  Future<List<MarketplaceBooking>> providerBookings(MarketplaceType type);
  Future<MarketplaceBooking> providerBookingAction(MarketplaceType type,String id,String action,{Map<String,dynamic>? body});
}

class MarketplaceRemoteDataSourceImpl implements MarketplaceRemoteDataSource {
  const MarketplaceRemoteDataSourceImpl(this.api);
  final ApiClient api;

  String _public(MarketplaceType t)=> t==MarketplaceType.accommodation?Endpoints.accommodations:Endpoints.transport;
  String _provider(MarketplaceType t)=> t==MarketplaceType.accommodation?Endpoints.providerAccommodations:Endpoints.providerTransport;

  @override Future<List<MarketplaceItem>> publicItems(MarketplaceType t,{String? query}) async {
    final q=query?.trim(); final path='${_public(t)}?limit=100${q==null||q.isEmpty?'':'&q=${Uri.encodeQueryComponent(q)}'}';
    final r=await api.get(path); return _items(r).map((e)=>MarketplaceItem(type:t,raw:e)).toList();
  }
  @override Future<MarketplaceItem> publicDetail(MarketplaceType t,String id) async {
    final path=t==MarketplaceType.transport?'${Endpoints.transport}/vehicles/${Uri.encodeComponent(id)}':'${Endpoints.accommodations}/${Uri.encodeComponent(id)}';
    final r=await api.get(path); return MarketplaceItem(type:t,raw:_object(r,t==MarketplaceType.transport?'vehicle':'accommodation'));
  }
  @override Future<List<MarketplaceBooking>> customerBookings(MarketplaceType t) async => _items(await api.get('${Endpoints.bookings}?bookingType=${t.apiValue}&pageSize=100',authenticated:true)).map(MarketplaceBooking.new).toList();
  @override Future<MarketplaceBooking> bookingDetail(String id,{bool provider=false}) async => MarketplaceBooking(_object(await api.get('${provider?Endpoints.providerBookings:Endpoints.bookings}/$id',authenticated:true),'booking'));
  @override Future<MarketplaceBooking> createBooking(MarketplaceType t,Map<String,dynamic> body) async => MarketplaceBooking(_object(await api.post(Endpoints.bookings,authenticated:true,body:{'bookingType':t.apiValue,...body}),'booking'));
  @override Future<void> customerBookingAction(String id,String action,{Map<String,dynamic>? body}) async { await api.post('${Endpoints.bookings}/$id/$action',authenticated:true,body:body); }
  @override Future<void> createReview({required String bookingId,required int rating,required String comment,String? title}) async { await api.post(Endpoints.reviews,authenticated:true,body:{'bookingId':bookingId,'rating':rating,'comment':comment.trim(),if(title?.trim().isNotEmpty==true)'title':title!.trim()}); }
  @override Future<String> uploadImage({required Uint8List bytes,required String fileName,required String mimeType}) async { final r=await api.postBytes(Endpoints.media,bytes:bytes,contentType:_mime(mimeType,fileName),authenticated:true,headers:{'x-file-name':fileName,'x-media-visibility':'public'}); final d=_data(r); return '${d['id']??''}'; }

  @override Future<List<MarketplaceItem>> providerItems(MarketplaceType t) async { final r=await api.get('${_provider(t)}?limit=100',authenticated:true); if(t==MarketplaceType.transport){ final d=_data(r); final vehicles=_maps(d['vehicles']); return vehicles.map((e)=>MarketplaceItem(type:t,raw:e)).toList(); } return _items(r).map((e)=>MarketplaceItem(type:t,raw:e)).toList(); }
  @override Future<MarketplaceItem> saveAccommodation(Map<String,dynamic> b,{String? id}) async { final r=id==null?await api.post(Endpoints.providerAccommodations,authenticated:true,body:b):await api.patch('${Endpoints.providerAccommodations}/$id',authenticated:true,body:b); return MarketplaceItem(type:MarketplaceType.accommodation,raw:_object(r,'accommodation')); }
  @override Future<void> deleteAccommodation(String id) async { await api.delete('${Endpoints.providerAccommodations}/$id',authenticated:true); }
  @override Future<Map<String,dynamic>> saveAccommodationUnit(String aid,Map<String,dynamic> b,{String? unitId}) async { final r=unitId==null?await api.post('${Endpoints.providerAccommodations}/$aid/units',authenticated:true,body:b):await api.patch('${Endpoints.providerAccommodations}/units/$unitId',authenticated:true,body:b); return _data(r); }
  @override Future<void> deleteAccommodationUnit(String id) async { await api.delete('${Endpoints.providerAccommodations}/units/$id',authenticated:true); }
  @override Future<Map<String,dynamic>> upsertInventory(String id,Map<String,dynamic> b) async => _data(await api.put('${Endpoints.providerAccommodations}/units/$id/inventory',authenticated:true,body:b));
  @override Future<Map<String,dynamic>> saveRate(String id,Map<String,dynamic> b,{String? rateId}) async { final p='${Endpoints.providerAccommodations}/units/$id/rates'; return _data(rateId==null?await api.post(p,authenticated:true,body:b):await api.patch('$p/$rateId',authenticated:true,body:b)); }
  @override Future<void> deleteRate(String uid,String rid) async { await api.delete('${Endpoints.providerAccommodations}/units/$uid/rates/$rid',authenticated:true); }
  @override Future<void> submitAccommodation(String id) async { await api.post('${Endpoints.providerAccommodations}/$id/submit',authenticated:true); }

  @override Future<Map<String,dynamic>> transportProfile() async => _data(await api.get(Endpoints.providerTransport,authenticated:true));
  @override Future<Map<String,dynamic>> saveTransportProfile(Map<String,dynamic> b) async => _data(await api.put(Endpoints.providerTransport,authenticated:true,body:b));
  @override Future<Map<String,dynamic>> saveVehicle(Map<String,dynamic> b,{String? id}) async => _data(id==null?await api.post('${Endpoints.providerTransport}/vehicles',authenticated:true,body:b):await api.patch('${Endpoints.providerTransport}/vehicles/$id',authenticated:true,body:b));
  @override Future<void> deleteVehicle(String id) async { await api.delete('${Endpoints.providerTransport}/vehicles/$id',authenticated:true); }
  @override Future<Map<String,dynamic>> saveVehicleDocument(String vid,Map<String,dynamic> b,{String? documentId}) async { final p='${Endpoints.providerTransport}/vehicles/$vid/documents'; return _data(documentId==null?await api.post(p,authenticated:true,body:b):await api.patch('$p/$documentId',authenticated:true,body:b)); }
  @override Future<void> deleteVehicleDocument(String vid,String did) async { await api.delete('${Endpoints.providerTransport}/vehicles/$vid/documents/$did',authenticated:true); }
  @override Future<Map<String,dynamic>> upsertVehicleAvailability(String vid,Map<String,dynamic> b) async => _data(await api.put('${Endpoints.providerTransport}/vehicles/$vid/availability',authenticated:true,body:b));
  @override Future<Map<String,dynamic>> saveVehiclePricing(String vid,Map<String,dynamic> b,{String? pricingId}) async { final p='${Endpoints.providerTransport}/vehicles/$vid/pricing'; return _data(pricingId==null?await api.post(p,authenticated:true,body:b):await api.patch('$p/$pricingId',authenticated:true,body:b)); }
  @override Future<void> deleteVehiclePricing(String vid,String pid) async { await api.delete('${Endpoints.providerTransport}/vehicles/$vid/pricing/$pid',authenticated:true); }
  @override Future<Map<String,dynamic>> saveRoute(Map<String,dynamic> b,{String? routeId}) async { final p='${Endpoints.providerTransport}/routes'; return _data(routeId==null?await api.post(p,authenticated:true,body:b):await api.patch('$p/$routeId',authenticated:true,body:b)); }
  @override Future<void> deleteRoute(String id) async { await api.delete('${Endpoints.providerTransport}/routes/$id',authenticated:true); }
  @override Future<void> submitVehicle(String id) async { await api.post('${Endpoints.providerTransport}/vehicles/$id/submit',authenticated:true); }

  @override Future<List<MarketplaceBooking>> providerBookings(MarketplaceType t) async => _items(await api.get('${Endpoints.providerBookings}?bookingType=${t.apiValue}&pageSize=100',authenticated:true)).map(MarketplaceBooking.new).toList();
  @override Future<MarketplaceBooking> providerBookingAction(MarketplaceType t,String id,String action,{Map<String,dynamic>? body}) async { final r=await api.post('${Endpoints.providerBookings}/$id/${t.apiValue}/$action',authenticated:true,body:body); return MarketplaceBooking(_object(r,'booking')); }

  Map<String,dynamic> _data(Map<String,dynamic> r){ final d=r['data']; return d is Map?d.map((k,v)=>MapEntry('$k',v)):r; }
  List<Map<String,dynamic>> _items(Map<String,dynamic> r){ final d=_data(r); dynamic v=d['items']??d['results']??d['accommodations']??d['vehicles']??d['bookings']; return _maps(v); }
  Map<String,dynamic> _object(Map<String,dynamic> r,String key){ final d=_data(r); final o=d[key]; return o is Map?o.map((k,v)=>MapEntry('$k',v)):d; }
  List<Map<String,dynamic>> _maps(dynamic v)=>v is List?v.whereType<Map>().map((e)=>e.map((k,v)=>MapEntry('$k',v))).toList():<Map<String,dynamic>>[];
  String _mime(String m,String n){ final x=m.toLowerCase(); if(x.startsWith('image/')) return x=='image/jpg'?'image/jpeg':x; final l=n.toLowerCase(); if(l.endsWith('.png')) return 'image/png'; if(l.endsWith('.webp')) return 'image/webp'; return 'image/jpeg'; }
}
