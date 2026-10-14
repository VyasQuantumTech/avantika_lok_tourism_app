import 'package:avantika_lok_tourism_app/core/widgets/provider_ui.dart';
import 'dart:convert';
import 'package:avantika_lok_tourism_app/features/pooja/data/datasources/pooja_remote_data_source.dart';
import 'package:avantika_lok_tourism_app/features/pooja/data/repositories/pooja_repository_impl.dart';
import 'package:avantika_lok_tourism_app/features/pooja/domain/usecases/pooja_actions.dart';
import 'package:avantika_lok_tourism_app/features/pooja/presentation/pages/customer_pooja_booking_detail_page.dart';
import 'package:avantika_lok_tourism_app/features/marketplace/presentation/accommodation_calendar_page.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:avantika_lok_tourism_app/app/config/app_flavor.dart';
import 'package:avantika_lok_tourism_app/app/theme/app_theme_config.dart';
// ignore: implementation_imports
import 'package:google_fonts/src/google_fonts_base.dart' as font_testing;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avantika_lok_tourism_app/app/di/injection.dart';
import 'package:avantika_lok_tourism_app/features/bookings/domain/entities/booking_lifecycle.dart';
import 'package:avantika_lok_tourism_app/features/bookings/domain/repositories/booking_repository.dart';
import 'package:avantika_lok_tourism_app/features/bookings/domain/usecases/booking_actions.dart';
import 'package:avantika_lok_tourism_app/features/bookings/presentation/widgets/booking_lifecycle_panel.dart';
import 'package:avantika_lok_tourism_app/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:avantika_lok_tourism_app/features/bookings/data/repositories/booking_repository_impl.dart';
import 'package:avantika_lok_tourism_app/features/marketplace/domain/usecases/marketplace_actions.dart';
import 'package:avantika_lok_tourism_app/features/marketplace/domain/entities/marketplace_entities.dart';
import 'package:avantika_lok_tourism_app/features/marketplace/data/datasources/marketplace_remote_data_source.dart';
import 'package:avantika_lok_tourism_app/features/marketplace/data/repositories/marketplace_repository_impl.dart';
import 'package:avantika_lok_tourism_app/features/marketplace/presentation/marketplace_pages.dart';
import 'booking_contract_test.dart' as fixtures;

class FakeBookingRepository implements BookingRepository {
  int codeRequests = 0;
  bool? end;
  @override
  Future<String> otp(String id, {required bool end}) async {
    codeRequests++;
    this.end = end;
    return '123456';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FontAssets implements AssetManifest {
  @override
  List<String> listAssets() => [
        for (final family in ['DancingScript', 'Karma'])
          for (final variant in ['Regular', 'Medium', 'SemiBold', 'Bold'])
            '$family-$variant.ttf'
      ];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    await getIt.reset();
    font_testing.assetManifest = _FontAssets();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
      final key = const StringCodec().decodeMessage(message);
      if (key?.endsWith('.ttf') == true) return ByteData(0);
      if (key == null) return null;
      final file = File(key);
      return file.existsSync()
          ? ByteData.sublistView(file.readAsBytesSync())
          : null;
    });
    await AppThemeConfig.load(AppFlavor.user);
  });
  tearDown(() async => getIt.reset());

  testWidgets('listing Book now loads current detail and opens the selected route without creating a booking', (tester) async {
    var detailRequests = 0;
    var writes = 0;
    final client = fixtures.api((request) async {
      if (request.method != 'GET') writes++;
      final route = {'id': 'route-1', 'name': 'Darshan', 'origin': 'Mahakaleshwar', 'destination': 'Ram ghat'};
      if (request.url.path.endsWith('/vehicles/vehicle-1')) {
        detailRequests++;
        return fixtures.response({'vehicle': {'id': 'vehicle-1', 'registrationNumber': 'MP13AM2343',
          'transportProviderProfile': {'routes': [route]}}});
      }
      return fixtures.response({'items': [{'vehicles': [{'id': 'vehicle-1', 'registrationNumber': 'MP13AM2343'}]}], 'pagination': {'totalPages': 1}});
    });
    getIt.registerSingleton(MarketplaceActions(MarketplaceRepositoryImpl(MarketplaceRemoteDataSourceImpl(client))));
    await tester.pumpWidget(const MaterialApp(home: CustomerMarketplaceListPage(type: MarketplaceType.transport)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Book now'));
    await tester.pumpAndSettle();
    expect(detailRequests, 1);
    expect(writes, 0);
    expect(find.text('Book Transport'), findsOneWidget);
    expect(find.text('Darshan'), findsOneWidget);
    expect(find.text('Check availability & fare'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('transport detail has visible route and persistent booking buttons; route is included in fare and booking requests', (tester) async {
    Map<String, dynamic>? submitted;
    final client = fixtures.api((request) async {
      if (request.method == 'POST') {
        submitted = jsonDecode(request.body) as Map<String, dynamic>;
        return fixtures.response({'booking': fixtures.booking('transport')});
      }
      if (request.url.path.endsWith('/availability')) {
        expect(request.url.queryParameters['routeId'], 'route-1');
        return fixtures.response({'quote': {'totalAmount': 250, 'currency': 'INR'}, 'intervals': []});
      }
      if (request.url.path.endsWith('/tracking')) return fixtures.response({'assignment': null});
      if (request.url.path.contains('/bookings/')) return fixtures.response({'booking': fixtures.booking('transport')});
      return fixtures.response({'vehicle': {'id': 'vehicle-1', 'registrationNumber': 'MP13AM2343',
        'transportProviderProfile': {'routes': [{'id': 'route-1', 'name': 'Darshan', 'origin': 'Mahakaleshwar', 'destination': 'Ram ghat'}]}}});
    });
    getIt.registerSingleton(MarketplaceActions(MarketplaceRepositoryImpl(MarketplaceRemoteDataSourceImpl(client))));
    getIt.registerSingleton(BookingActions(BookingRepositoryImpl(BookingRemoteDataSource(client))));
    await tester.pumpWidget(const MaterialApp(home: CustomerMarketplaceDetailPage(type: MarketplaceType.transport, identifier: 'vehicle-1')));
    await tester.pumpAndSettle();
    expect(find.text('Book now'), findsOneWidget);
    expect(find.text('Book this route'), findsOneWidget);
    await tester.tap(find.text('Book this route'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Passenger / customer name'), 'Fixture passenger');
    await tester.enterText(find.widgetWithText(TextFormField, 'Contact phone'), '9999999999');
    await tester.scrollUntilVisible(find.text('Request booking'), 350, scrollable: find.descendant(of: find.byType(ListView).last, matching: find.byType(Scrollable)).first);
    await tester.drag(find.byType(ListView).last, const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Request booking'));
    await tester.pumpAndSettle();
    expect(submitted?['vehicleId'], 'vehicle-1');
    expect(submitted?['routeId'], 'route-1');
    expect(submitted?['passengers'], 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('persistent Book now asks for a route and cancellation creates no booking', (tester) async {
    var writes = 0;
    final client = fixtures.api((request) async {
      if (request.method != 'GET') writes++;
      return fixtures.response({'vehicle': {'id': 'vehicle-1', 'transportProviderProfile': {'routes': [
        {'id': 'route-1', 'name': 'Darshan'}, {'id': 'route-2', 'name': 'Airport'},
      ]}}});
    });
    getIt.registerSingleton(MarketplaceActions(MarketplaceRepositoryImpl(MarketplaceRemoteDataSourceImpl(client))));
    await tester.pumpWidget(const MaterialApp(home: CustomerMarketplaceDetailPage(type: MarketplaceType.transport, identifier: 'vehicle-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Book now'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a route'), findsOneWidget);
    Navigator.of(tester.element(find.text('Choose a route'))).pop();
    await tester.pumpAndSettle();
    expect(find.text('Book Transport'), findsNothing);
    expect(writes, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('route-free vehicles open booking and stays without units remain disabled', (tester) async {
    final client = fixtures.api((request) async => fixtures.response({
      request.url.path.contains('/transport/') ? 'vehicle' : 'accommodation': {'id': 'service-1'},
    }));
    getIt.registerSingleton(MarketplaceActions(MarketplaceRepositoryImpl(MarketplaceRemoteDataSourceImpl(client))));
    await tester.pumpWidget(const MaterialApp(home: CustomerMarketplaceDetailPage(type: MarketplaceType.transport, identifier: 'vehicle-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Book now'));
    await tester.pumpAndSettle();
    expect(find.text('Book Transport'), findsOneWidget);
    await tester.pumpWidget(const MaterialApp(key: ValueKey('stay'), home: CustomerMarketplaceDetailPage(type: MarketplaceType.accommodation, identifier: 'stay-1')));
    await tester.pumpAndSettle();
    expect(find.text('No rooms available'), findsOneWidget);
    final unavailable = find.ancestor(of: find.text('No rooms available'), matching: find.byWidgetPredicate((widget) => widget is FilledButton)).first;
    expect(tester.widget<FilledButton>(unavailable).onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('new vehicle pricing is active and routes are selected by name', (tester) async {
    Map<String, dynamic>? saved;
    final client = fixtures.api((request) async {
      if (request.method == 'POST') {
        expect(request.url.path, '/api/v1/provider/transport/vehicles/vehicle-1/pricing');
        saved = jsonDecode(request.body) as Map<String, dynamic>;
        return fixtures.response({'pricing': saved});
      }
      return fixtures.response({'transportProviderProfile': {'status':'active',
        'vehicles':[{'id':'vehicle-1','approvalStatus':'pending','documents':[],'pricing':[],'availability':[]}],
        'routes':[{'id':'11111111-1111-4111-8111-111111111111','name':'Ujjain to Indore','status':'active'}]}});
    });
    getIt.registerSingleton(MarketplaceActions(MarketplaceRepositoryImpl(MarketplaceRemoteDataSourceImpl(client))));
    await tester.pumpWidget(const MaterialApp(home: ProviderMarketplaceResourcesPage(
      type: MarketplaceType.transport,
      item: MarketplaceItem(type: MarketplaceType.transport, raw:{'id':'vehicle-1','registrationNumber':'MP13TEST'}))));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Add pricing'), 150);
    await tester.ensureVisible(find.text('Add pricing'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add pricing'));
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(find.widgetWithText(SwitchListTile,'Active')).value, true);
    await tester.tap(find.text('All routes / no fixed route'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ujjain to Indore (active)').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField,'Base amount'), '1200');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(saved?['isActive'],true);
    expect(saved?['routeId'],'11111111-1111-4111-8111-111111111111');
    expect(saved?['baseAmount'],1200);
  });

  testWidgets('RC alone names the three missing documents and prevents premature submission', (tester) async {
    var submissions = 0;
    final client = fixtures.api((request) async {
      if (request.method == 'POST') submissions++;
      return fixtures.response({'transportProviderProfile': {'status':'active','vehicles':[
        {'id':'vehicle-1','approvalStatus':'pending','status':'draft',
          'documents':[{'documentType':'registration_certificate','status':'pending','expiresAt':'3032-12-12'}],
          'pricing':[{'isActive':true}], 'availability':[]}], 'routes':[]}});
    });
    getIt.registerSingleton(MarketplaceActions(MarketplaceRepositoryImpl(MarketplaceRemoteDataSourceImpl(client))));
    await tester.pumpWidget(const MaterialApp(home: ProviderMarketplaceResourcesPage(
      type:MarketplaceType.transport,
      item:MarketplaceItem(type:MarketplaceType.transport,raw:{'id':'vehicle-1','registrationNumber':'MP13AM2343'}))));
    await tester.pumpAndSettle();
    expect(find.text('Documents still needed: Insurance, Permit, Pollution certificate (PUC).'), findsOneWidget);
    expect(tester.widget<ProviderActionButton>(find.widgetWithText(ProviderActionButton,'Submit for approval')).onPressed,isNull);
    expect(submissions,0);
  });

  testWidgets('vehicle operations submits from setup and refreshes to awaiting review', (tester) async {
    var submitted = false;
    final client = fixtures.api((request) async {
      if (request.method == 'POST') {
        expect(request.url.path, '/api/v1/provider/transport/vehicles/vehicle-1/submit');
        submitted = true;
        return fixtures.response({'vehicle': {'id': 'vehicle-1'}});
      }
      return fixtures.response({'transportProviderProfile': {
        'status': 'active',
        'vehicles': [{'id': 'vehicle-1', 'approvalStatus': 'pending', 'status': 'draft',
          'submittedAt': submitted ? '2026-10-14T12:00:00Z' : null,
          'documents': [for (final type in MarketplaceItem.vehicleDocumentLabels.keys) {'documentType': type, 'status':'pending'}], 'pricing': [{'isActive':true}], 'availability': []}], 'routes': []
      }});
    });
    getIt.registerSingleton(MarketplaceActions(MarketplaceRepositoryImpl(MarketplaceRemoteDataSourceImpl(client))));
    await tester.pumpWidget(const MaterialApp(home: ProviderMarketplaceResourcesPage(
      type: MarketplaceType.transport,
      item: MarketplaceItem(type: MarketplaceType.transport, raw: {'id':'vehicle-1','registrationNumber':'MP13TEST'}),
    )));
    await tester.pumpAndSettle();
    expect(find.text('Submit for approval'), findsOneWidget);
    await tester.tap(find.text('Submit for approval'));
    await tester.pumpAndSettle();
    expect(submitted, true);
    expect(find.text('Submit for approval'), findsNothing);
    expect(find.textContaining('Submitted. Admin reviews your evidence'), findsOneWidget);
  });

  testWidgets(
      'completion code appears only after start; consumed start code clears on refresh',
      (tester) async {
    final repo = FakeBookingRepository();
    getIt.registerSingleton(BookingActions(repo));
    Widget panel(BookingLifecycle state) => MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: BookingLifecyclePanel(
                    bookingId: 'booking-1',
                    lifecycle: state,
                    onRefresh: () async {}))));
    const ready =
        BookingLifecycle(status: 'confirmed', providerDecision: 'accepted');
    await tester.pumpWidget(panel(ready));
    expect(find.text('Get start code'), findsOneWidget);
    expect(find.text('Get completion code'), findsNothing);
    await tester.tap(find.text('Get start code'));
    await tester.pumpAndSettle();
    expect(find.text('123456'), findsOneWidget);
    expect(repo.end, false);
    await tester.pumpWidget(panel(BookingLifecycle(
        status: 'confirmed',
        providerDecision: 'accepted',
        startedAt: DateTime(2026, 11, 11))));
    expect(find.text('123456'), findsNothing);
    expect(find.text('Get start code'), findsNothing);
    expect(find.text('Get completion code'), findsOneWidget);
    await tester.tap(find.text('Get completion code'));
    await tester.pumpAndSettle();
    expect(repo.end, true);
    await tester.pumpWidget(panel(const BookingLifecycle(
        status: 'completed', providerDecision: 'accepted')));
    expect(find.text('123456'), findsNothing);
    expect(find.text('Get completion code'), findsNothing);
  });
  testWidgets(
      'disabled/arrival policies hide checkout and pending confirmation hides OTP',
      (tester) async {
    getIt.registerSingleton(BookingActions(FakeBookingRepository()));
    for (final policy in ['disabled', 'pay_on_arrival', 'online_required']) {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: BookingLifecyclePanel(
                  bookingId: 'booking-1',
                  lifecycle: BookingLifecycle(
                      status: 'pending',
                      providerDecision: 'accepted',
                      paymentPolicy: policy),
                  onRefresh: () async {}))));
      expect(find.text('Get completion code'), findsNothing);
      expect(find.text('Get start code'), findsNothing);
      expect(find.text('Complete payment'),
          policy == 'online_required' ? findsOneWidget : findsNothing);
    }
  });
  testWidgets(
      'pooja details show confirmed start controls and refresh to completion phase',
      (tester) async {
    var started = false;
    final client = fixtures.api((request) async => fixtures.response({
          'booking': fixtures.booking('pooja', started: started)
            ..['bookingNumber'] = 'AVANTIKA-BOOKING-2026-LONG-REFERENCE'
        }));
    getIt.registerSingleton(CustomerPoojaActions(
        PoojaRepositoryImpl(PoojaRemoteDataSourceImpl(client))));
    getIt.registerSingleton(
        BookingActions(BookingRepositoryImpl(BookingRemoteDataSource(client))));
    await tester.pumpWidget(const MaterialApp(
        home: CustomerPoojaBookingDetailPage(bookingId: 'booking-1')));
    await tester.pumpAndSettle();
    expect(find.text('Get start code'), findsOneWidget);
    expect(find.text('Get completion code'), findsNothing);
    expect(find.text('Complete payment'), findsNothing);
    expect(tester.takeException(), isNull);
    started = true;
    await tester.ensureVisible(find.text('Refresh booking'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Refresh booking'));
    await tester.pumpAndSettle();
    expect(find.text('Get start code'), findsNothing);
    expect(find.text('Get completion code'), findsOneWidget);
    expect(find.text('Cancel Booking'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'accommodation calendar shows reservation-aware stock and edits the selected day',
      (tester) async {
    final row = {
      'date': '2026-11-11',
      'totalInventory': 5,
      'availableInventory': 3,
      'reservedInventory': 2,
      'minimumStayNights': 2,
      'maximumStayNights': 7,
      'isClosed': false
    };
    Map<String, dynamic>? selected;
    final client = fixtures.api((request) async => fixtures.response({
          'items': [row]
        }));
    getIt.registerSingleton(MarketplaceActions(
        MarketplaceRepositoryImpl(MarketplaceRemoteDataSourceImpl(client))));
    await tester.pumpWidget(MaterialApp(
        home: ProviderAccommodationCalendarPage(
            unitId: 'unit-1',
            unitName: 'Deluxe',
            onEdit: (value) async {
              selected = value;
            })));
    await tester.pumpAndSettle();
    expect(find.text('3 available • 2 reserved • 5 total'), findsOneWidget);
    expect(find.textContaining('minimum 2 nights'), findsOneWidget);
    await tester.tap(find.text('Edit day'));
    await tester.pumpAndSettle();
    expect(selected?['date'], '2026-11-11');
    expect(selected?['reservedInventory'], 2);
    expect(tester.takeException(), isNull);
  });
  for (final type in MarketplaceType.values) {
    testWidgets(
        '${type.apiValue} provider cannot accept again or start before payment confirmation',
        (tester) async {
      final client = fixtures.api((request) async => fixtures.response({
            'items': [
              fixtures.booking(type.apiValue,
                  status: 'pending', policy: 'online_required')
            ],
            'pagination': {'totalPages': 1}
          }));
      getIt.registerSingleton(MarketplaceActions(
          MarketplaceRepositoryImpl(MarketplaceRemoteDataSourceImpl(client))));
      await tester.pumpWidget(
          MaterialApp(home: ProviderMarketplaceBookingsPage(type: type)));
      await tester.pumpAndSettle();
      expect(find.text('Frozen service name'), findsOneWidget);
      expect(find.text('Accept'), findsNothing);
      expect(find.text('Start stay'), findsNothing);
      expect(find.text('Start trip'), findsNothing);
      expect(find.text('Waiting For Payment'), findsOneWidget);
      if (type == MarketplaceType.transport) {
        expect(find.text('Assign driver'), findsNothing);
      }
      expect(tester.takeException(), isNull);
    });
    testWidgets(
        '${type.apiValue} customer detail hides cancellation after service start',
        (tester) async {
      final client = fixtures.api((request) async {
        if (request.url.path.endsWith('/tracking')) {
          return fixtures.response({'assignment': null, 'lastLocation': null});
        }
        return fixtures.response(
            {'booking': fixtures.booking(type.apiValue, started: true)});
      });
      getIt.registerSingleton(MarketplaceActions(
          MarketplaceRepositoryImpl(MarketplaceRemoteDataSourceImpl(client))));
      getIt.registerSingleton(BookingActions(
          BookingRepositoryImpl(BookingRemoteDataSource(client))));
      await tester.pumpWidget(MaterialApp(
          home: CustomerMarketplaceBookingDetailPage(
              type: type, bookingId: 'booking-1')));
      await tester.pumpAndSettle();
      expect(find.text('Cancel booking'), findsNothing);
      expect(find.text('Get start code'), findsNothing);
      expect(find.text('Get completion code'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
