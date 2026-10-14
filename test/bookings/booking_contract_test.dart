import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:avantika_lok_tourism_app/core/ network/api_client.dart';
import 'package:avantika_lok_tourism_app/core/storage/secure_storage_service.dart';
import 'package:avantika_lok_tourism_app/core/errors/exceptions.dart';
import 'package:avantika_lok_tourism_app/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:avantika_lok_tourism_app/features/bookings/data/repositories/booking_repository_impl.dart';
import 'package:avantika_lok_tourism_app/features/bookings/data/models/booking_lifecycle_model.dart';
import 'package:avantika_lok_tourism_app/features/marketplace/data/datasources/marketplace_remote_data_source.dart';
import 'package:avantika_lok_tourism_app/features/marketplace/data/repositories/marketplace_repository_impl.dart';
import 'package:avantika_lok_tourism_app/features/marketplace/domain/entities/marketplace_entities.dart';
import 'package:avantika_lok_tourism_app/features/pooja/data/datasources/pooja_remote_data_source.dart';
import 'package:avantika_lok_tourism_app/features/pooja/data/models/pooja_models.dart';
import 'package:avantika_lok_tourism_app/features/profile/data/models/profile_models.dart';

class SessionStorage extends SecureStorageService {
  SessionStorage() : super(const FlutterSecureStorage());
  @override
  Future<String?> readAccessToken() async => 'test-session';
}

ApiClient api(Future<http.Response> Function(http.Request) handler) =>
    ApiClient(
        baseUrl: 'https://backend.test',
        client: MockClient(handler),
        secureStorage: SessionStorage());
http.Response response(dynamic data) =>
    http.Response(jsonEncode({'success': true, 'data': data}), 200);
Map<String, dynamic> booking(String type,
        {String status = 'confirmed',
        String decision = 'accepted',
        String policy = 'disabled',
        bool started = false,
        bool ended = false}) =>
    {
      'id': 'booking-1',
      'bookingNumber': 'AV-1',
      'bookingType': type,
      'status': status,
      'providerDecision': decision,
      'paymentPolicy': policy,
      'serviceDate': '2026-11-11',
      'totalAmount': 1200,
      'currency': 'INR',
      'serviceStartedAt': started ? '2026-11-11T08:00:00Z' : null,
      'serviceEndedAt': ended ? '2026-11-11T09:00:00Z' : null,
      'serviceSummary': {
        'name': 'Frozen service name',
        'providerName': 'Service provider',
        'unitName': 'Deluxe room'
      },
      'paymentState': {'status': 'not_started'},
    };

void main() {
  for (final type in ['pooja', 'accommodation', 'transport']) {
    test(
        '$type lifecycle never exposes completion before start or controls after closure',
        () {
      final ready = bookingLifecycleFromJson(booking(type));
      expect(ready.canStart, true);
      expect(ready.canFetchEndOtp, false);
      expect(ready.canFetchStartOtp, true);
      expect(ready.canCancel, true);
      final active = bookingLifecycleFromJson(booking(type, started: true));
      expect(active.canFetchStartOtp, false);
      expect(active.canFetchEndOtp, true);
      expect(active.canCancel, false);
      expect(active.canComplete, true);
      for (final status in [
        'withdrawn',
        'cancelled',
        'rejected',
        'expired',
        'completed'
      ]) {
        final closed = bookingLifecycleFromJson(booking(type, status: status));
        expect(closed.active, false);
        expect(closed.canCancel, false);
        expect(closed.canStart, false);
        expect(closed.canFetchEndOtp, false);
        expect(closed.canPay, false);
      }
    });
    test('$type acceptance alone cannot start an online-required booking', () {
      final waiting = bookingLifecycleFromJson(
          booking(type, status: 'pending', policy: 'online_required'));
      expect(waiting.statusLabel, 'Waiting for payment');
      expect(waiting.canStart, false);
      expect(waiting.awaitingProvider, false);
      expect(waiting.canPay, true);
      expect(bookingLifecycleFromJson(booking(type, policy: 'disabled')).canPay,
          false);
      expect(
          bookingLifecycleFromJson(booking(type, policy: 'pay_on_arrival'))
              .canPay,
          false);
      final captured =
          booking(type, status: 'pending', policy: 'online_required');
      captured['paymentState'] = {'status': 'captured'};
      expect(bookingLifecycleFromJson(captured).canPay, false);
    });
    test(
        '$type fetches completion OTP only after fresh service state confirms start',
        () async {
      var current = booking(type);
      final calls = <http.Request>[];
      final repository =
          BookingRepositoryImpl(BookingRemoteDataSource(api((request) async {
        calls.add(request);
        expect(request.headers['Authorization'], 'Bearer test-session');
        return response(request.url.path.endsWith('-otp')
            ? {'otp': '000123'}
            : {'booking': current});
      })));
      await expectLater(
          repository.otp('booking-1', end: true), throwsA(isA<ApiException>()));
      expect(calls.any((r) => r.url.path.endsWith('/end-otp')), false);
      current = booking(type, started: true);
      expect(await repository.otp('booking-1', end: true), '000123');
      expect(calls.last.url.path, '/api/v1/bookings/booking-1/end-otp');
      current = booking(type, status: 'completed', started: true, ended: true);
      await expectLater(
          repository.otp('booking-1', end: true), throwsA(isA<ApiException>()));
    });
  }
  test('vehicle detail keeps active provider routes for general per-km pricing', () async {
    final remote = MarketplaceRemoteDataSourceImpl(api((request) async => response({'vehicle': {
      'id':'vehicle-1', 'pricing':[{'pricingModel':'per_km','perKmAmount':18,'baseAmount':100}],
      'transportProviderProfile': {'routes':[{'id':'route-1','name':'Ujjain to Indore','status':'active','distanceKm':55}],
        'providerProfile':{'city':'Ujjain','state':'MP'}}
    }})));
    final item = await remote.publicDetail(MarketplaceType.transport,'vehicle-1');
    expect(item.routes.single['id'],'route-1');
    expect(item.routes.single['distanceKm'],55);
    expect(item.city,'Ujjain');
  });

  test('vehicle setup accepts pending documents but excludes rejected, archived and expired evidence', () {
    final docs = [for (final type in MarketplaceItem.vehicleDocumentLabels.keys) <String,dynamic>{'documentType':type,'status':'pending','expiresAt':'3032-12-12'}];
    final raw = <String,dynamic>{'documents':docs,'pricing':[{'isActive':true}]};
    final listing = MarketplaceItem(type:MarketplaceType.transport,raw:raw);
    expect(listing.readyToSubmitVehicle,true);
    docs[1]['status']='rejected';
    docs[2]['metadata']={'archivedAt':'2026-10-14'};
    docs[3]['expiresAt']='2020-01-01';
    expect(listing.missingVehicleDocuments,['insurance','permit','puc']);
    expect(listing.readyToSubmitVehicle,false);
    raw['pricing']=[{'isActive':true,'validTo':'2020-01-01'}];
    expect(listing.hasCurrentVehiclePricing,false);
    raw['pricing']=[{'isActive':true,'routeId':'route-1','route':{'status':'draft'}}];
    expect(listing.hasCurrentVehiclePricing,false);
  });

  test('legacy pooja policy stays disabled and frozen summary takes precedence',
      () {
    final json = booking('pooja')..remove('paymentPolicy');
    json['paymentRequired'] = true;
    json['pricingSnapshot'] = {'poojaName': 'Old label'};
    final model = poojaBookingFromJson(json);
    expect(model.state.serviceName, 'Frozen service name');
    expect(model.state.paymentPolicy, 'disabled');
    expect(model.canPanditStart, true);
  });
  test(
      'payment initiation checks policy and uses gateway verification contract',
      () async {
    var current =
        booking('accommodation', status: 'pending', policy: 'disabled');
    final calls = <http.Request>[];
    final repository =
        BookingRepositoryImpl(BookingRemoteDataSource(api((request) async {
      calls.add(request);
      if (request.method == 'GET') return response({'booking': current});
      if (request.url.path.endsWith('/verify')) return response({});
      return response({
        'payment': {
          'id': 'payment-1',
          'bookingId': 'booking-1',
          'status': 'created',
          'amount': 1200,
          'currency': 'INR',
          'checkout': {
            'keyId': 'key',
            'orderId': 'order',
            'amountMinor': 120000,
            'amount': 1200,
            'currency': 'INR'
          }
        }
      });
    })));
    await expectLater(
        repository.initiatePayment('booking-1'), throwsA(isA<ApiException>()));
    expect(calls.where((r) => r.method == 'POST'), isEmpty);
    current =
        booking('accommodation', status: 'pending', policy: 'online_required');
    final payment = await repository.initiatePayment('booking-1');
    expect(payment.amountMinor, 120000);
    expect(jsonDecode(calls.last.body), {'bookingId': 'booking-1'});
    await repository.verifyPayment(
        paymentId: payment.id,
        orderId: 'order',
        gatewayPaymentId: 'gateway-payment',
        signature: 'signed');
    expect(calls.last.url.path, '/api/v1/payments/payment-1/verify');
    expect(jsonDecode(calls.last.body), {
      'razorpayOrderId': 'order',
      'razorpayPaymentId': 'gateway-payment',
      'razorpaySignature': 'signed'
    });
  });
  test(
      'transport previews exact route and window; private evidence remains private',
      () async {
    final calls = <http.Request>[];
    final remote = MarketplaceRemoteDataSourceImpl(api((request) async {
      calls.add(request);
      if (request.url.path.endsWith('/availability')) {
        return response({
          'intervals': [
            {'startTime': '09:00', 'endTime': '12:00'}
          ],
          'quoteReservesCapacity': false,
          'quote': {'totalAmount': 800, 'currency': 'USD'}
        });
      }
      if (request.url.path.endsWith('/media')) {
        return response(
            {'id': 'private-asset', 'visibility': 'private', 'url': null});
      }
      return response({});
    }));
    final quote = await remote.transportAvailability(
        vehicleId: 'vehicle-1',
        date: '2026-11-11',
        startTime: '09:00',
        endTime: '12:00',
        passengers: 2,
        routeId: 'route-1');
    expect(quote.totalAmount, 800);
    expect(quote.currency, 'USD');
    expect(calls.last.url.queryParameters, {
      'date': '2026-11-11',
      'startTime': '09:00',
      'endTime': '12:00',
      'passengers': '2',
      'routeId': 'route-1'
    });
    final media = await remote.uploadDocument(
        bytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'insurance.png',
        mimeType: 'image/png');
    expect(media, 'private-asset');
    expect(calls.last.headers['x-media-visibility'], 'private');
    expect(calls.last.headers['Authorization'], 'Bearer test-session');
    await remote.saveVehicleDocument('vehicle-1', {
      'documentType': 'insurance',
      'mediaAssetId': media,
      'status': 'pending'
    });
    expect(jsonDecode(calls.last.body)['status'], 'pending');
    expect(jsonDecode(calls.last.body).containsKey('storageKey'), false);
  });
  test(
      'driver assignment, arrival and provider-only status route preserve auth',
      () async {
    final calls = <http.Request>[];
    final repository = MarketplaceRepositoryImpl(
        MarketplaceRemoteDataSourceImpl(api((r) async {
      calls.add(r);
      expect(r.headers['Authorization'], 'Bearer test-session');
      return response({});
    })));
    await repository.call('assignRide',
        id: 'booking-1', body: {'driverId': 'driver-1', 'deviceId': null});
    expect(calls.last.method, 'PUT');
    expect(calls.last.url.path,
        '/api/v1/provider/transport/rides/booking-1/assignment');
    expect(jsonDecode(calls.last.body),
        {'driverId': 'driver-1', 'deviceId': null});
    await repository.call('arrived', id: 'booking-1');
    expect(calls.last.method, 'POST');
    await repository.call('vehicleStatus',
        id: 'vehicle-1', body: {'status': 'maintenance'});
    expect(calls.last.method, 'PATCH');
    expect(calls.last.url.path,
        '/api/v1/provider/transport/vehicles/vehicle-1/status');
    await expectLater(
        repository.providerBookingAction(
            MarketplaceType.transport, 'booking-1', 'unsafe'),
        throwsArgumentError);
  });
  test(
      'all customer/provider booking lists follow backend pagination and summaries',
      () async {
    final requests = <http.Request>[];
    final client = api((r) async {
      requests.add(r);
      final page = int.parse(r.url.queryParameters['page']!);
      final type = r.url.queryParameters['bookingType']!;
      return response({
        'items': [booking(type)..['id'] = 'booking-$page'],
        'pagination': {'page': page, 'totalPages': 2, 'total': 2}
      });
    });
    final market = MarketplaceRemoteDataSourceImpl(client);
    for (final type in MarketplaceType.values) {
      expect((await market.customerBookings(type)).map((b) => b.id),
          ['booking-1', 'booking-2']);
      expect((await market.providerBookings(type)).first.displayName,
          'Frozen service name');
    }
    final pooja = PoojaRemoteDataSourceImpl(client);
    expect((await pooja.getCustomerPoojaBookings()).length, 2);
    expect((await pooja.getPanditBookings()).length, 2);
    expect(requests.every((r) => r.url.queryParameters['pageSize'] == '100'),
        true);
  });
  test(
      'accommodation calendar and pause operations use owned provider endpoints',
      () async {
    final requests = <http.Request>[];
    final repository = MarketplaceRepositoryImpl(
        MarketplaceRemoteDataSourceImpl(api((r) async {
      requests.add(r);
      expect(r.headers['Authorization'], 'Bearer test-session');
      return response({
        'items': [
          {
            'date': '2026-11-11',
            'totalInventory': 5,
            'reservedInventory': 2,
            'availableInventory': 3
          }
        ]
      });
    })));
    final result = await repository.call('inventoryCalendar',
        id: 'unit-1',
        body: {'startDate': '2026-11-11', 'endDate': '2026-11-12'});
    expect(requests.last.url.path,
        '/api/v1/provider/accommodations/units/unit-1/inventory');
    expect(requests.last.url.queryParameters,
        {'startDate': '2026-11-11', 'endDate': '2026-11-12'});
    expect(result['items'][0]['reservedInventory'], 2);
    await repository
        .call('pauseAccommodation', id: 'property-1', body: {'paused': true});
    expect(requests.last.method, 'PATCH');
    expect(jsonDecode(requests.last.body), {'paused': true});
    final item = MarketplaceItem(
        type: MarketplaceType.accommodation,
        raw: {'status': 'active', 'approvalStatus': 'approved'});
    expect(item.operationalStatus, 'active');
    expect(item.status, 'approved');
  });

  test('currency summaries preserve null aggregates and separate currencies',
      () {
    final parsed = parseProfileDashboard({
      'provider': {
        'financial': {
          'currency': null,
          'grossCaptured': null,
          'processedRefunds': null,
          'netCollected': null,
          'payoutBalance': null,
          'byCurrency': [
            {
              'currency': 'INR',
              'grossCaptured': 1000,
              'processedRefunds': 100,
              'netCollected': 900
            },
            {
              'currency': 'USD',
              'grossCaptured': 50,
              'processedRefunds': 0,
              'netCollected': 50
            },
          ]
        }
      }
    });
    final financial = parsed.provider!.financial;
    expect(financial.currency, isNull);
    expect(financial.netCollected, isNull);
    expect(financial.payoutBalance, isNull);
    expect(financial.currencies.length, 2);
    expect(financial.format('net'), 'INR 900.00 • USD 50.00');
    final legacy = parseProfileDashboard({
      'provider': {
        'financial': {
          'currency': 'USD',
          'grossCaptured': 10,
          'processedRefunds': 2,
          'netCollected': 8
        }
      }
    });
    expect(legacy.provider!.financial.format('net'), 'USD 8.00');
  });
}
