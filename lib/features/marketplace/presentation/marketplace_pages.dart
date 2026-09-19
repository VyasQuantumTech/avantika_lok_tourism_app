import 'package:flutter/material.dart';

import '../../../app/di/injection.dart';
import '../../../app/router/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/widgets/app_ui.dart';
import '../domain/entities/marketplace_entities.dart';
import '../domain/usecases/marketplace_actions.dart';


class CustomerBookingsHubPage extends StatelessWidget {
  const CustomerBookingsHubPage({super.key});

  @override
  Widget build(BuildContext context) => AppPage(
        title: 'My Bookings',
        subtitle: 'All Avantika Lok services in one place',
        child: ListView(
          children: [
            _hubItem(context, 'Pooja bookings', Icons.temple_hindu_outlined, RouteNames.customerPoojaBookings),
            _hubItem(context, 'Accommodation bookings', Icons.hotel_outlined, RouteNames.customerAccommodationBookings),
            _hubItem(context, 'Transport bookings', Icons.directions_car_outlined, RouteNames.customerTransportBookings),
          ],
        ),
      );

  Widget _hubItem(BuildContext context, String label, IconData icon, String route) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AppPanel(
          onTap: () => Navigator.of(context).pushNamed(route),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: AppTypography.label)),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      );
}

class CustomerMarketplaceListPage extends StatefulWidget {
  const CustomerMarketplaceListPage({required this.type, super.key});
  final MarketplaceType type;
  @override State<CustomerMarketplaceListPage> createState() => _CustomerMarketplaceListPageState();
}
class _CustomerMarketplaceListPageState extends State<CustomerMarketplaceListPage> {
  final search = TextEditingController(); late Future<List<MarketplaceItem>> future;
  @override void initState(){super.initState(); reload();} void reload()=>future=getIt<MarketplaceActions>().browse(widget.type,query:search.text);
  @override void dispose(){search.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>AppPage(title:widget.type.plural,subtitle:'Live approved ${widget.type.title.toLowerCase()} services',actions:[IconButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>CustomerMarketplaceBookingsPage(type:widget.type))),icon:const Icon(Icons.receipt_long_outlined))],child:Column(children:[TextField(controller:search,onSubmitted:(_)=>setState(reload),decoration:InputDecoration(hintText:'Search ${widget.type.plural.toLowerCase()}',prefixIcon:const Icon(Icons.search),suffixIcon:IconButton(onPressed:()=>setState(reload),icon:const Icon(Icons.refresh)))),const SizedBox(height:12),Expanded(child:FutureBuilder<List<MarketplaceItem>>(future:future,builder:(context,s){if(s.connectionState==ConnectionState.waiting)return const AppLoadingView(message:'Loading services…');if(s.hasError)return AppErrorState(message:_err(s.error),onRetry:()=>setState(reload));final items=s.data??const[];if(items.isEmpty)return AppEmptyState(title:'No ${widget.type.plural.toLowerCase()} available',message:'Approved provider services will appear here.',icon:widget.type==MarketplaceType.accommodation?Icons.hotel_outlined:Icons.directions_car_outlined);return RefreshIndicator(onRefresh:()async{setState(reload);await future;},child:ListView.separated(physics:const AlwaysScrollableScrollPhysics(),itemCount:items.length,separatorBuilder:(_,__)=>const SizedBox(height:10),itemBuilder:(_,i)=>AppPanel(onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>CustomerMarketplaceDetailPage(type:widget.type,identifier:items[i].slug))),child:Row(children:[Container(width:56,height:56,alignment:Alignment.center,decoration:BoxDecoration(color:AppColors.softSurface,borderRadius:BorderRadius.circular(12)),child:Icon(widget.type==MarketplaceType.accommodation?Icons.hotel_outlined:Icons.directions_car_outlined,color:AppColors.primary)),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(items[i].name,style:AppTypography.label),if(items[i].city.isNotEmpty)Text(items[i].city,style:AppTypography.caption),if(items[i].price>0)Text(_money(items[i].currency,items[i].price),style:AppTypography.caption)])),const Icon(Icons.chevron_right)]))));}))]));
}

class CustomerMarketplaceDetailPage extends StatefulWidget{const CustomerMarketplaceDetailPage({required this.type,required this.identifier,super.key});final MarketplaceType type;final String identifier;@override State<CustomerMarketplaceDetailPage> createState()=>_CustomerMarketplaceDetailPageState();}
class _CustomerMarketplaceDetailPageState extends State<CustomerMarketplaceDetailPage>{late Future<MarketplaceItem> future;@override void initState(){super.initState();future=getIt<MarketplaceActions>().detail(widget.type,widget.identifier);}@override Widget build(BuildContext context)=>AppPage(title:widget.type.title,child:FutureBuilder<MarketplaceItem>(future:future,builder:(context,s){if(s.connectionState==ConnectionState.waiting)return const AppLoadingView(message:'Loading details…');if(s.hasError||s.data==null)return AppErrorState(message:_err(s.error), onRetry: () {  },);final item=s.data!;final options=widget.type==MarketplaceType.accommodation?item.units:item.routes;return ListView(children:[Text(item.name,style:AppTypography.titleLarge),if(item.city.isNotEmpty)Text(item.city,style:AppTypography.caption),if(item.description.isNotEmpty)...[const SizedBox(height:12),Text(item.description,style:AppTypography.body)],const SizedBox(height:16),AppPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(widget.type==MarketplaceType.accommodation?'Rooms / units':'Routes',style:AppTypography.sectionTitle),const SizedBox(height:8),if(options.isEmpty)Text('No nested options returned; booking uses the selected service.',style:AppTypography.caption),...options.map((o)=>ListTile(contentPadding:EdgeInsets.zero,title:Text('${o['name']??o['unitName']??o['routeName']??'Option'}'),subtitle:Text('${o['unitType']??o['origin']??''} ${o['destination']??''}'),onTap:()=>_book(item,o))) ])),const SizedBox(height:16),FilledButton.icon(onPressed:()=>_book(item,options.isEmpty?null:options.first),icon:const Icon(Icons.calendar_month_outlined),label:Text('Book ${widget.type.title}'))]);}));void _book(MarketplaceItem i,Map<String,dynamic>? o)=>Navigator.push(context,MaterialPageRoute(builder:(_)=>CustomerMarketplaceBookingPage(type:widget.type,item:i,option:o)));}

class CustomerMarketplaceBookingPage extends StatefulWidget{const CustomerMarketplaceBookingPage({required this.type,required this.item,this.option,super.key});final MarketplaceType type;final MarketplaceItem item;final Map<String,dynamic>? option;@override State<CustomerMarketplaceBookingPage> createState()=>_CustomerMarketplaceBookingPageState();}
class _CustomerMarketplaceBookingPageState extends State<CustomerMarketplaceBookingPage>{final key=GlobalKey<FormState>();final date=TextEditingController(),endDate=TextEditingController(),start=TextEditingController(text:'09:00'),end=TextEditingController(text:'18:00'),units=TextEditingController(text:'1'),adults=TextEditingController(text:'2'),children=TextEditingController(text:'0'),passengers=TextEditingController(text:'1'),name=TextEditingController(),phone=TextEditingController(),email=TextEditingController(),notes=TextEditingController();bool saving=false;@override void initState(){super.initState();final d=DateTime.now().add(const Duration(days:1));date.text=_iso(d);endDate.text=_iso(d.add(const Duration(days:1)));}@override void dispose(){for(final c in [date,endDate,start,end,units,adults,children,passengers,name,phone,email,notes])c.dispose();super.dispose();}
  @override Widget build(BuildContext context){final a=widget.type==MarketplaceType.accommodation;return AppPage(title:'Book ${widget.type.title}',subtitle:widget.item.name,child:Form(key:key,child:ListView(children:[_f(date,'Service date',req:true),if(a)_f(endDate,'Checkout date',req:true),if(!a)...[_f(start,'Start time',req:true),_f(end,'End time')],if(a)...[_f(units,'Units',num:true),_f(adults,'Adults',num:true),_f(children,'Children',num:true)]else _f(passengers,'Passengers',num:true),_f(name,'Customer name'),_f(phone,'Phone'),_f(email,'Email'),_f(notes,'Notes',lines:3),const SizedBox(height:12),FilledButton(onPressed:saving?null:submit,child:Text(saving?'Saving…':'Confirm booking'))])));}
  Future<void> submit()async{if(!key.currentState!.validate())return;setState(()=>saving=true);try{final o=widget.option??{};final body=widget.type==MarketplaceType.accommodation?<String,dynamic>{'accommodationUnitId':'${o['id']??o['unitId']??widget.item.raw['defaultUnitId']??''}','serviceDate':date.text.trim(),'endDate':endDate.text.trim(),'units':int.tryParse(units.text)??1,'adults':int.tryParse(adults.text)??1,'children':int.tryParse(children.text)??0,if(name.text.trim().isNotEmpty)'customerName':name.text.trim(),if(phone.text.trim().isNotEmpty)'customerPhone':phone.text.trim(),if(email.text.trim().isNotEmpty)'customerEmail':email.text.trim(),if(notes.text.trim().isNotEmpty)'notes':notes.text.trim()}:<String,dynamic>{'vehicleId':widget.item.id,if('${o['id']??o['routeId']??''}'.isNotEmpty)'routeId':'${o['id']??o['routeId']}','serviceDate':date.text.trim(),'startTime':start.text.trim(),if(end.text.trim().isNotEmpty)'endTime':end.text.trim(),'passengers':int.tryParse(passengers.text)??1,if(name.text.trim().isNotEmpty)'customerName':name.text.trim(),if(phone.text.trim().isNotEmpty)'customerPhone':phone.text.trim(),if(email.text.trim().isNotEmpty)'customerEmail':email.text.trim(),if(notes.text.trim().isNotEmpty)'notes':notes.text.trim()};if(widget.type==MarketplaceType.accommodation&&'${body['accommodationUnitId']}'.isEmpty)throw const ApiException('No accommodation unit was returned for this property.');final b=await getIt<MarketplaceActions>().book(widget.type,body);if(!mounted)return;AppFeedback.success(context,'Booking ${b.bookingNumber} created.');Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>CustomerMarketplaceBookingDetailPage(type:widget.type,bookingId:b.id)));}catch(e){if(mounted)AppFeedback.error(context,_err(e));}finally{if(mounted)setState(()=>saving=false);}}
}

class CustomerMarketplaceBookingsPage extends StatefulWidget{const CustomerMarketplaceBookingsPage({required this.type,super.key});final MarketplaceType type;@override State<CustomerMarketplaceBookingsPage> createState()=>_CustomerMarketplaceBookingsPageState();}
class _CustomerMarketplaceBookingsPageState extends State<CustomerMarketplaceBookingsPage>{late Future<List<MarketplaceBooking>> future;@override void initState(){super.initState();reload();}void reload()=>future=getIt<MarketplaceActions>().myBookings(widget.type);@override Widget build(BuildContext context)=>AppPage(title:'My ${widget.type.title} Bookings',child:FutureBuilder<List<MarketplaceBooking>>(future:future,builder:(context,s){if(s.connectionState==ConnectionState.waiting)return const AppLoadingView(message:'Loading bookings…');if(s.hasError)return AppErrorState(message:_err(s.error),onRetry:()=>setState(reload));final x=s.data??const[];if(x.isEmpty)return const AppEmptyState(title:'No bookings yet',message:'Bookings will appear here.',icon:Icons.receipt_long_outlined);return RefreshIndicator(onRefresh:()async{setState(reload);await future;},child:ListView.separated(physics:const AlwaysScrollableScrollPhysics(),itemCount:x.length,separatorBuilder:(_,__)=>const SizedBox(height:10),itemBuilder:(_,i)=>AppPanel(onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>CustomerMarketplaceBookingDetailPage(type:widget.type,bookingId:x[i].id))),child:Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(x[i].displayName,style:AppTypography.label),Text('${x[i].serviceDate} • ${x[i].bookingNumber}',style:AppTypography.caption)])),AppStatusChip(label:x[i].status.isEmpty?'booked':x[i].status)]))));}));}

class CustomerMarketplaceBookingDetailPage extends StatefulWidget{const CustomerMarketplaceBookingDetailPage({required this.type,required this.bookingId,super.key});final MarketplaceType type;final String bookingId;@override State<CustomerMarketplaceBookingDetailPage> createState()=>_CustomerMarketplaceBookingDetailPageState();}
class _CustomerMarketplaceBookingDetailPageState extends State<CustomerMarketplaceBookingDetailPage>{late Future<MarketplaceBooking> future;@override void initState(){super.initState();load();}void load()=>future=getIt<MarketplaceActions>().booking(widget.bookingId);@override Widget build(BuildContext context)=>AppPage(title:'Booking details',child:FutureBuilder<MarketplaceBooking>(future:future,builder:(context,s){if(s.connectionState==ConnectionState.waiting)return const AppLoadingView(message:'Loading booking…');if(s.hasError||s.data==null)return AppErrorState(message:_err(s.error), onRetry: () {  },);final b=s.data!;return ListView(children:[AppPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(b.displayName,style:AppTypography.sectionTitle),_r('Booking',b.bookingNumber),_r('Status',b.status),_r('Provider',b.providerDecision),_r('Date',b.serviceDate),if(b.endDate.isNotEmpty)_r('End',b.endDate),_r('Amount',_money(b.currency,b.totalAmount))])),const SizedBox(height:12),if(!b.isCompleted&&b.status!='cancelled')OutlinedButton(onPressed:cancel,child:const Text('Cancel booking')),if(b.isCompleted)FilledButton(onPressed:review,child:const Text('Write review'))]);}));Future<void> cancel()async{final r=await _text(context,'Cancel booking','Reason');if(r==null)return;try{await getIt<MarketplaceActions>().bookingAction(widget.bookingId,'cancel',body:{'reason':r});if(mounted){AppFeedback.success(context,'Booking cancelled.');setState(load);}}catch(e){if(mounted)AppFeedback.error(context,_err(e));}}Future<void> review()async{final c=TextEditingController();int rating=5;final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setD)=>AlertDialog(title:const Text('Review'),content:Column(mainAxisSize:MainAxisSize.min,children:[DropdownButtonFormField<int>(value:rating,items:[1,2,3,4,5].map((e)=>DropdownMenuItem(value:e,child:Text('$e stars'))).toList(),onChanged:(v)=>setD(()=>rating=v??5)),TextField(controller:c,maxLines:3,decoration:const InputDecoration(labelText:'Comment'))]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Submit'))])));if(ok==true){try{await getIt<MarketplaceActions>().review(widget.bookingId,rating,c.text);if(mounted)AppFeedback.success(context,'Review submitted.');}catch(e){if(mounted)AppFeedback.error(context,_err(e));}}c.dispose();}}

class ProviderMarketplaceManagementPage extends StatefulWidget{const ProviderMarketplaceManagementPage({required this.type,super.key});final MarketplaceType type;@override State<ProviderMarketplaceManagementPage> createState()=>_ProviderMarketplaceManagementPageState();}
class _ProviderMarketplaceManagementPageState extends State<ProviderMarketplaceManagementPage>{late Future<List<MarketplaceItem>> future;@override void initState(){super.initState();reload();}void reload()=>future=getIt<MarketplaceActions>().providerItems(widget.type);@override Widget build(BuildContext context)=>AppPage(title:'Manage ${widget.type.plural}',actions:[IconButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>ProviderMarketplaceBookingsPage(type:widget.type))),icon:const Icon(Icons.receipt_long_outlined)),if(widget.type==MarketplaceType.transport)IconButton(onPressed:profile,icon:const Icon(Icons.business_outlined))],floatingActionButton:FloatingActionButton.extended(onPressed:()=>edit(null),icon:const Icon(Icons.add),label:Text(widget.type==MarketplaceType.accommodation?'Add property':'Add vehicle')),child:FutureBuilder<List<MarketplaceItem>>(future:future,builder:(context,s){if(s.connectionState==ConnectionState.waiting)return const AppLoadingView(message:'Loading provider services…');if(s.hasError)return AppErrorState(message:_err(s.error),onRetry:()=>setState(reload));final x=s.data??const[];if(x.isEmpty)return AppEmptyState(title:'No ${widget.type.plural.toLowerCase()} yet',message:'Create your first service.',icon:widget.type==MarketplaceType.accommodation?Icons.apartment_outlined:Icons.directions_car_outlined);return RefreshIndicator(onRefresh:()async{setState(reload);await future;},child:ListView.separated(physics:const AlwaysScrollableScrollPhysics(),padding:const EdgeInsets.only(bottom:90),itemCount:x.length,separatorBuilder:(_,__)=>const SizedBox(height:10),itemBuilder:(_,i)=>AppPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:Text(x[i].name,style:AppTypography.sectionTitle)),AppStatusChip(label:x[i].status)]),const SizedBox(height:10),Wrap(spacing:8,runSpacing:8,children:[OutlinedButton(onPressed:()=>edit(x[i]),child:const Text('Edit')),OutlinedButton(onPressed:()=>manage(x[i]),child:Text(widget.type==MarketplaceType.accommodation?'Units / inventory / rates':'Documents / availability / pricing / routes')),OutlinedButton(onPressed:()=>submit(x[i]),child:const Text('Submit for approval')),IconButton(onPressed:()=>remove(x[i]),icon:const Icon(Icons.delete_outline))])]))));}));
  Future<void> edit(MarketplaceItem? item)async{final b=await _form(context,item==null?'Create ${widget.type.title}':'Edit ${widget.type.title}',widget.type==MarketplaceType.accommodation?_accommodation:_vehicle,item?.raw??{});if(b==null)return;try{await getIt<MarketplaceActions>().providerCall(widget.type==MarketplaceType.accommodation?'saveAccommodation':'saveVehicle',id:item?.id,body:b);if(mounted){AppFeedback.success(context,'Saved.');setState(reload);}}catch(e){if(mounted)AppFeedback.error(context,_err(e));}}
  Future<void> remove(MarketplaceItem item)async{if(!await _confirm(context,'Delete ${item.name}?'))return;try{await getIt<MarketplaceActions>().providerCall(widget.type==MarketplaceType.accommodation?'deleteAccommodation':'deleteVehicle',id:item.id);if(mounted){AppFeedback.success(context,'Deleted.');setState(reload);}}catch(e){if(mounted)AppFeedback.error(context,_err(e));}}
  Future<void> submit(MarketplaceItem item)async{try{await getIt<MarketplaceActions>().providerCall(widget.type==MarketplaceType.accommodation?'submitAccommodation':'submitVehicle',id:item.id);if(mounted)AppFeedback.success(context,'Submitted for approval.');}catch(e){if(mounted)AppFeedback.error(context,_err(e));}}
  Future<void> manage(MarketplaceItem item)async{await Navigator.push(context,MaterialPageRoute(builder:(_)=>ProviderMarketplaceResourcesPage(type:widget.type,item:item)));}
  Future<void> profile()async{try{final x=await getIt<MarketplaceActions>().providerCall('transportProfile') as Map<String,dynamic>;if(!mounted)return;final b=await _form(context,'Transport profile',_transportProfile,x);if(b!=null){await getIt<MarketplaceActions>().providerCall('saveTransportProfile',body:b);if(mounted)AppFeedback.success(context,'Transport profile saved.');}}catch(e){if(mounted)AppFeedback.error(context,_err(e));}}
}

class ProviderMarketplaceResourcesPage extends StatelessWidget {
  const ProviderMarketplaceResourcesPage({required this.type, required this.item, super.key});
  final MarketplaceType type;
  final MarketplaceItem item;

  @override
  Widget build(BuildContext context) => AppPage(
        title: type == MarketplaceType.accommodation ? 'Accommodation operations' : 'Vehicle operations',
        subtitle: item.name,
        child: ListView(
          children: type == MarketplaceType.accommodation
              ? [
                  _op(context, 'Create unit', Icons.bed_outlined, () => unit(context)),
                  _op(context, 'Update unit', Icons.edit_outlined, () => unit(context, update: true)),
                  _op(context, 'Delete unit', Icons.delete_outline, () => deleteUnit(context)),
                  _op(context, 'Upsert inventory', Icons.inventory_2_outlined, () => inventory(context)),
                  _op(context, 'Create rate', Icons.currency_rupee, () => rate(context)),
                  _op(context, 'Update rate', Icons.edit_note_outlined, () => rate(context, update: true)),
                  _op(context, 'Delete rate', Icons.money_off_outlined, () => deleteRate(context)),
                ]
              : [
                  _op(context, 'Add vehicle document', Icons.description_outlined, () => document(context)),
                  _op(context, 'Update vehicle document', Icons.edit_outlined, () => document(context, update: true)),
                  _op(context, 'Delete vehicle document', Icons.delete_outline, () => deleteDocument(context)),
                  _op(context, 'Upsert vehicle availability', Icons.calendar_month_outlined, () => availability(context)),
                  _op(context, 'Create pricing', Icons.currency_rupee, () => pricing(context)),
                  _op(context, 'Update pricing', Icons.edit_note_outlined, () => pricing(context, update: true)),
                  _op(context, 'Delete pricing', Icons.money_off_outlined, () => deletePricing(context)),
                  _op(context, 'Create route', Icons.route_outlined, () => route(context)),
                  _op(context, 'Update route', Icons.edit_outlined, () => route(context, update: true)),
                  _op(context, 'Delete route', Icons.delete_sweep_outlined, () => deleteRoute(context)),
                ],
        ),
      );

  Widget _op(BuildContext c, String t, IconData i, VoidCallback a) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AppPanel(
          onTap: a,
          child: Row(children: [Icon(i, color: AppColors.primary), const SizedBox(width: 12), Expanded(child: Text(t, style: AppTypography.label)), const Icon(Icons.chevron_right)]),
        ),
      );

  Future<void> unit(BuildContext c, {bool update = false}) async {
    final id = update ? await _text(c, 'Update unit', 'Unit ID') : null;
    if (update && (id == null || id.isEmpty)) return;
    final b = await _form(c, update ? 'Update accommodation unit' : 'Create accommodation unit', _unit, const {});
    if (b != null) await _call(c, 'saveUnit', id: id, parentId: item.id, body: b);
  }

  Future<void> deleteUnit(BuildContext c) async {
    final id = await _text(c, 'Delete unit', 'Unit ID');
    if (id == null || id.isEmpty || !await _confirm(c, 'Delete unit $id?')) return;
    await _call(c, 'deleteUnit', id: id, success: 'Unit deleted.');
  }

  Future<void> inventory(BuildContext c) async {
    final id = await _text(c, 'Inventory', 'Unit ID');
    if (id == null || id.isEmpty) return;
    final b = await _form(c, 'Inventory', _inventory, const {});
    if (b != null) await _call(c, 'inventory', parentId: id, body: b);
  }

  Future<void> rate(BuildContext c, {bool update = false}) async {
    final unitId = await _text(c, 'Rate', 'Unit ID');
    if (unitId == null || unitId.isEmpty) return;
    final rateId = update ? await _text(c, 'Update rate', 'Rate ID') : null;
    if (update && (rateId == null || rateId.isEmpty)) return;
    final b = await _form(c, update ? 'Update rate' : 'Create rate', _rate, const {});
    if (b != null) await _call(c, 'saveRate', id: rateId, parentId: unitId, body: b);
  }

  Future<void> deleteRate(BuildContext c) async {
    final unitId = await _text(c, 'Delete rate', 'Unit ID');
    if (unitId == null || unitId.isEmpty) return;
    final rateId = await _text(c, 'Delete rate', 'Rate ID');
    if (rateId == null || rateId.isEmpty || !await _confirm(c, 'Delete rate $rateId?')) return;
    await _call(c, 'deleteRate', id: rateId, parentId: unitId, success: 'Rate deleted.');
  }

  Future<void> document(BuildContext c, {bool update = false}) async {
    final id = update ? await _text(c, 'Update document', 'Document ID') : null;
    if (update && (id == null || id.isEmpty)) return;
    final b = await _form(c, update ? 'Update vehicle document' : 'Add vehicle document', _document, const {});
    if (b != null) await _call(c, 'saveDocument', id: id, parentId: item.id, body: b);
  }

  Future<void> deleteDocument(BuildContext c) async {
    final id = await _text(c, 'Delete document', 'Document ID');
    if (id == null || id.isEmpty || !await _confirm(c, 'Delete document $id?')) return;
    await _call(c, 'deleteDocument', id: id, parentId: item.id, success: 'Document deleted.');
  }

  Future<void> availability(BuildContext c) async {
    final b = await _form(c, 'Vehicle availability', _availability, const {});
    if (b != null) await _call(c, 'availability', parentId: item.id, body: b);
  }

  Future<void> pricing(BuildContext c, {bool update = false}) async {
    final id = update ? await _text(c, 'Update pricing', 'Pricing ID') : null;
    if (update && (id == null || id.isEmpty)) return;
    final b = await _form(c, update ? 'Update pricing' : 'Create pricing', _pricing, const {});
    if (b != null) await _call(c, 'savePricing', id: id, parentId: item.id, body: b);
  }

  Future<void> deletePricing(BuildContext c) async {
    final id = await _text(c, 'Delete pricing', 'Pricing ID');
    if (id == null || id.isEmpty || !await _confirm(c, 'Delete pricing $id?')) return;
    await _call(c, 'deletePricing', id: id, parentId: item.id, success: 'Pricing deleted.');
  }

  Future<void> route(BuildContext c, {bool update = false}) async {
    final id = update ? await _text(c, 'Update route', 'Route ID') : null;
    if (update && (id == null || id.isEmpty)) return;
    final b = await _form(c, update ? 'Update transport route' : 'Create transport route', _route, const {});
    if (b != null) await _call(c, 'saveRoute', id: id, body: {...b, 'vehicleId': item.id});
  }

  Future<void> deleteRoute(BuildContext c) async {
    final id = await _text(c, 'Delete route', 'Route ID');
    if (id == null || id.isEmpty || !await _confirm(c, 'Delete route $id?')) return;
    await _call(c, 'deleteRoute', id: id, success: 'Route deleted.');
  }

  Future<void> _call(BuildContext c, String op, {String? id, String? parentId, Map<String, dynamic>? body, String success = 'Saved.'}) async {
    try {
      await getIt<MarketplaceActions>().providerCall(op, id: id, parentId: parentId, body: body);
      if (c.mounted) AppFeedback.success(c, success);
    } catch (e) {
      if (c.mounted) AppFeedback.error(c, _err(e));
    }
  }
}

class ProviderMarketplaceBookingsPage extends StatefulWidget{const ProviderMarketplaceBookingsPage({required this.type,super.key});final MarketplaceType type;@override State<ProviderMarketplaceBookingsPage> createState()=>_ProviderMarketplaceBookingsPageState();}
class _ProviderMarketplaceBookingsPageState extends State<ProviderMarketplaceBookingsPage>{late Future<List<MarketplaceBooking>> future;@override void initState(){super.initState();load();}void load()=>future=getIt<MarketplaceActions>().providerBookings(widget.type);@override Widget build(BuildContext context)=>AppPage(title:'${widget.type.title} Orders',child:FutureBuilder<List<MarketplaceBooking>>(future:future,builder:(context,s){if(s.connectionState==ConnectionState.waiting)return const AppLoadingView(message:'Loading orders…');if(s.hasError)return AppErrorState(message:_err(s.error),onRetry:()=>setState(load));final x=s.data??const[];if(x.isEmpty)return const AppEmptyState(title:'No orders',message:'Customer bookings will appear here.',icon:Icons.receipt_long_outlined);return RefreshIndicator(onRefresh:()async{setState(load);await future;},child:ListView.separated(physics:const AlwaysScrollableScrollPhysics(),itemCount:x.length,separatorBuilder:(_,__)=>const SizedBox(height:10),itemBuilder:(_,i){final b=x[i];return AppPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(b.displayName,style:AppTypography.label),Text('${b.serviceDate} • ${b.bookingNumber}',style:AppTypography.caption),const SizedBox(height:8),Wrap(spacing:8,runSpacing:8,children:[FilledButton(onPressed:()=>act(b,'accept'),child:const Text('Accept')),OutlinedButton(onPressed:()=>reason(b,'reject'),child:const Text('Reject')),OutlinedButton(onPressed:()=>act(b,'start'),child:const Text('Start')),OutlinedButton(onPressed:()=>act(b,'complete'),child:const Text('Complete')),TextButton(onPressed:()=>reason(b,'cancel'),child:const Text('Cancel'))]) ]));}));}));Future<void> act(MarketplaceBooking b,String a)async{try{await getIt<MarketplaceActions>().providerBookingAction(widget.type,b.id,a);if(mounted){AppFeedback.success(context,'Updated.');setState(load);}}catch(e){if(mounted)AppFeedback.error(context,_err(e));}}Future<void> reason(MarketplaceBooking b,String a)async{final r=await _text(context,a,'Reason');if(r!=null){try{await getIt<MarketplaceActions>().providerBookingAction(widget.type,b.id,a,body:{'reason':r});if(mounted){AppFeedback.success(context,'Updated.');setState(load);}}catch(e){if(mounted)AppFeedback.error(context,_err(e));}}}}

Widget _f(
    TextEditingController c,
    String l, {
      bool req = false,
      bool num = false,
      int lines = 1,
    }) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: c,
        maxLines: lines,
        keyboardType: num ? TextInputType.number : null,
        validator: req
            ? (v) => (v ?? '').trim().isEmpty ? 'Required' : null
            : null,
        decoration: InputDecoration(labelText: l),
      ),
    );
Widget _r(String a,String b)=>Padding(padding:const EdgeInsets.symmetric(vertical:4),child:Row(children:[SizedBox(width:120,child:Text(a,style:AppTypography.caption)),Expanded(child:Text(b.isEmpty?'—':b))]));
String _iso(DateTime d)=>'${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';String _money(String c,double v)=>c.toUpperCase()=='INR'?'₹${v.toStringAsFixed(0)}':'${c.toUpperCase()} ${v.toStringAsFixed(0)}';String _err(Object? e)=>e is ApiException?e.message:'${e??'Request failed'}';
Future<String?> _text(BuildContext c,String title,String label)async{final x=TextEditingController();final r=await showDialog<String>(context:c,builder:(d)=>AlertDialog(title:Text(title),content:TextField(controller:x,decoration:InputDecoration(labelText:label)),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(d,x.text.trim()),child:const Text('Continue'))]));x.dispose();return r;}
Future<bool> _confirm(BuildContext c,String q)async=>await showDialog<bool>(context:c,builder:(d)=>AlertDialog(title:const Text('Confirm'),content:Text(q),actions:[TextButton(onPressed:()=>Navigator.pop(d,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(d,true),child:const Text('Confirm'))]))??false;
class _Def{const _Def(this.k,this.l,{this.n=false,this.b=false,this.lines=1});final String k,l;final bool n,b;final int lines;}
Future<Map<String,dynamic>?> _form(BuildContext c,String title,List<_Def> defs,Map<String,dynamic> initial)async{final cs=<String,TextEditingController>{};final bs=<String,bool>{};for(final d in defs){if(d.b){bs[d.k]=initial[d.k]==true;}else{cs[d.k]=TextEditingController(text:'${initial[d.k]??''}');}}final out=await showDialog<Map<String,dynamic>>(context:c,builder:(ctx)=>StatefulBuilder(builder:(ctx,setD)=>AlertDialog(title:Text(title),content:SizedBox(width:520,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:defs.map((d)=>d.b?SwitchListTile(contentPadding:EdgeInsets.zero,title:Text(d.l),value:bs[d.k]??false,onChanged:(v)=>setD(()=>bs[d.k]=v)):Padding(padding:const EdgeInsets.only(bottom:8),child:TextField(controller:cs[d.k],maxLines:d.lines,keyboardType:d.n?TextInputType.number:null,decoration:InputDecoration(labelText:d.l)))).toList()))),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancel')),FilledButton(onPressed:(){final b=<String,dynamic>{};for(final d in defs){if(d.b){b[d.k]=bs[d.k]??false;}else{final s=cs[d.k]!.text.trim();if(s.isEmpty)continue;if(d.n)b[d.k]=num.tryParse(s)??s;else if(d.k.endsWith('Ids')||d.k=='amenities')b[d.k]=s.split(',').map((e)=>e.trim()).where((e)=>e.isNotEmpty).toList();else b[d.k]=s;}}Navigator.pop(ctx,b);},child:const Text('Save'))])));for(final x in cs.values)x.dispose();return out;}
const _accommodation=[_Def('name','Property name'),_Def('propertyType','Property type'),_Def('description','Description',lines:3),_Def('addressLine1','Address'),_Def('city','City'),_Def('state','State'),_Def('postalCode','Postal code'),_Def('countryCode','Country code'),_Def('checkInTime','Check-in time'),_Def('checkOutTime','Check-out time'),_Def('amenities','Amenities (comma separated)'),_Def('imageMediaAssetIds','Image media IDs (comma separated)'),_Def('isActive','Active',b:true)];
const _unit=[_Def('name','Unit name'),_Def('unitType','Unit type'),_Def('description','Description',lines:3),_Def('maxAdults','Max adults',n:true),_Def('maxChildren','Max children',n:true),_Def('totalUnits','Total units',n:true),_Def('bedType','Bed type'),_Def('amenities','Amenities (comma separated)'),_Def('imageMediaAssetIds','Image media IDs (comma separated)'),_Def('isActive','Active',b:true)];
const _inventory=[_Def('date','Date'),_Def('availableUnits','Available units',n:true),_Def('stopSell','Stop sell',b:true),_Def('minStay','Min stay',n:true),_Def('maxStay','Max stay',n:true)];
const _rate=[_Def('name','Rate name'),_Def('rateType','Rate type'),_Def('amount','Amount',n:true),_Def('currency','Currency'),_Def('startDate','Start date'),_Def('endDate','End date'),_Def('isRefundable','Refundable',b:true),_Def('isActive','Active',b:true)];
const _transportProfile=[_Def('businessName','Business name'),_Def('description','Description',lines:3),_Def('serviceArea','Service area'),_Def('contactPhone','Contact phone'),_Def('isActive','Active',b:true)];
const _vehicle=[_Def('name','Vehicle name'),_Def('vehicleType','Vehicle type'),_Def('make','Make'),_Def('model','Model'),_Def('year','Year',n:true),_Def('registrationNumber','Registration no.'),_Def('seatingCapacity','Seating',n:true),_Def('luggageCapacity','Luggage capacity',n:true),_Def('airConditioned','Air conditioned',b:true),_Def('description','Description',lines:3),_Def('imageMediaAssetIds','Image media IDs (comma separated)'),_Def('isActive','Active',b:true)];
const _document=[_Def('documentType','Document type'),_Def('documentNumber','Document number'),_Def('issuedAt','Issued date'),_Def('expiresAt','Expiry date'),_Def('mediaAssetId','Media asset ID')];
const _availability=[_Def('date','Date'),_Def('startTime','Start time'),_Def('endTime','End time'),_Def('isAvailable','Available',b:true),_Def('notes','Notes')];
const _pricing=[_Def('pricingType','Pricing type'),_Def('amount','Amount',n:true),_Def('currency','Currency'),_Def('unit','Unit'),_Def('startDate','Start date'),_Def('endDate','End date'),_Def('isActive','Active',b:true)];
const _route=[_Def('name','Route name'),_Def('origin','Origin'),_Def('destination','Destination'),_Def('distanceKm','Distance km',n:true),_Def('estimatedDurationMinutes','Duration minutes',n:true),_Def('basePrice','Base price',n:true),_Def('currency','Currency'),_Def('isActive','Active',b:true)];
