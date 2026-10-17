import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avantika_lok_tourism_app/app/di/injection.dart';
import 'package:avantika_lok_tourism_app/features/commercial/data/commercial_repository_impl.dart';
import 'package:avantika_lok_tourism_app/features/commercial/domain/commercial_repository.dart';
import 'package:avantika_lok_tourism_app/features/commercial/presentation/price_breakdown.dart';
import 'package:avantika_lok_tourism_app/features/commercial/presentation/provider_subscription_page.dart';
import '../bookings/booking_contract_test.dart' as fixtures;
import '../auth/auth_test_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    await getIt.reset();
    await configureAuthTestFonts();
  });
  tearDown(() async {
    await getIt.reset();
  });
  test(
      'commercial remote paths include API version and preserve purchase idempotency',
      () async {
    final requests = <String>[];
    final client = fixtures.api((r) async {
      requests.add(r.url.path);
      if (r.method == 'POST') {
        expect(jsonDecode(r.body)['idempotencyKey'], 'stable-test-intent');
      }
      return fixtures.response({'items': []});
    });
    final actions = CommercialActions(
        CommercialRepositoryImpl(CommercialRemoteDataSource(client)));
    await actions.plans();
    await actions.checkout('plan-1', 'stable-test-intent');
    expect(requests, [
      '/api/v1/provider/subscription-plans',
      '/api/v1/provider/subscriptions/checkout'
    ]);
  });
  testWidgets(
      'customer price breakdown excludes provider fees while showing tax and final total',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: PriceBreakdown(snapshot: {
      'currency': 'INR',
      'customerPayableMinor': 11800,
      'lines': [
        {
          'type': 'service',
          'label': 'Service',
          'bearer': 'customer',
          'netMinor': 10000,
          'taxMinor': 1800,
          'totalMinor': 11800,
          'taxes': [
            {
              'code': 'GST',
              'rateBps': 1800,
              'amountMinor': 1800,
              'mode': 'exclusive'
            }
          ]
        },
        {
          'type': 'commission',
          'label': 'Provider commission',
          'bearer': 'provider',
          'netMinor': 1000,
          'taxMinor': 0,
          'totalMinor': 1000,
          'taxes': []
        }
      ]
    }))));
    await tester.pumpAndSettle();
    expect(find.text('Provider commission'), findsNothing);
    expect(find.textContaining('GST'), findsOneWidget);
    expect(find.text('Total: INR 118.00'), findsOneWidget);
  });
  testWidgets(
      'quote confirmation waits for authoritative result and returns its fingerprint',
      (tester) async {
    Map<String, dynamic>? submitted, result;
    final client = fixtures.api((r) async {
      submitted = jsonDecode(r.body) as Map<String, dynamic>;
      return fixtures.response({
        'commercial': {
          'quoteHash': 'authoritative-hash',
          'currency': 'INR',
          'customerPayableMinor': 12300,
          'lines': [],
          'availableAddons': []
        }
      });
    });
    getIt.registerSingleton(CommercialActions(
        CommercialRepositoryImpl(CommercialRemoteDataSource(client))));
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                    onPressed: () async {
                      result = await reviewCommercialPrice(context, {
                        'bookingType': 'pooja',
                        'panditPoojaId': 'offering'
                      });
                    },
                    child: const Text('Review'))))));
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    expect(submitted?['paymentMethod'], 'upi');
    expect(find.text('Total: INR 123.00'), findsOneWidget);
    await tester.tap(find.text('Confirm price'));
    await tester.pumpAndSettle();
    expect(result?['expectedPriceHash'], 'authoritative-hash');
    expect(result?['paymentMethod'], 'upi');
  });
  testWidgets('provider sees plan entitlements and current access state',
      (tester) async {
    final client = fixtures.api((r) async =>
        fixtures.response(r.url.path.endsWith('/subscription-plans')
            ? {
                'items': [
                  {
                    'id': 'gold',
                    'name': 'Gold',
                    'config': {
                      'priceMinor': 199900,
                      'currency': 'INR',
                      'cycleMonths': 1,
                      'entitlements': {
                        'listing': {
                          'enabled': true,
                          'quota': 20,
                          'period': 'month'
                        }
                      }
                    }
                  }
                ]
              }
            : {
                'current': {
                  'id': 'current',
                  'state': 'active',
                  'endsAt': '2030-01-01T00:00:00Z',
                  'autoRenew': false,
                  'terms': {
                    'plan': {'name': 'Gold'}
                  }
                },
                'usage': []
              }));
    getIt.registerSingleton(CommercialActions(
        CommercialRepositoryImpl(CommercialRemoteDataSource(client))));
    await tester
        .pumpWidget(const MaterialApp(home: ProviderSubscriptionPage()));
    await tester.pumpAndSettle();
    expect(find.text('Status: active'), findsOneWidget);
    expect(find.textContaining('listing'), findsOneWidget);
    expect(find.text('Authorize automatic renewal'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
