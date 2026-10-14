import 'package:flutter/material.dart';
import 'package:avantika_lok_tourism_app/app/di/injection.dart';
import 'package:avantika_lok_tourism_app/features/home/domain/entities/home_dashboard.dart';
import 'package:avantika_lok_tourism_app/features/favorites/presentation/favorites_page.dart';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:avantika_lok_tourism_app/core/ network/api_client.dart';
import 'package:avantika_lok_tourism_app/core/storage/secure_storage_service.dart';
import 'package:avantika_lok_tourism_app/features/home/data/datasources/home_remote_data_source.dart';
import 'package:avantika_lok_tourism_app/features/favorites/data/datasources/favorites_remote_data_source.dart';
import 'package:avantika_lok_tourism_app/features/favorites/domain/entities/saved_item.dart';
import 'package:avantika_lok_tourism_app/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:avantika_lok_tourism_app/features/favorites/domain/usecases/favorites_actions.dart';
import 'package:avantika_lok_tourism_app/features/favorites/presentation/favorites_controller.dart';

class _Storage extends Fake implements SecureStorageService {
  @override
  Future<String?> readAccessToken() async => 'test-token';
}

class _Repository implements FavoritesRepository {
  List<SavedItem> rows = [];
  bool failSave = false;
  @override
  Future<List<SavedItem>> list() async => rows;
  @override
  Future<String> save(String type, String id) async {
    if (failSave) throw StateError('failed');
    rows = [SavedItem(id: 'saved', type: type, targetId: id)];
    return 'saved';
  }

  @override
  Future<void> remove(String id) async {
    rows = [];
  }
}

void main() {
  test(
      'dashboard loads authenticated actual typed items and resolves media paths',
      () async {
    final api = ApiClient(
        baseUrl: 'https://api.example.test',
        secureStorage: _Storage(),
        client: MockClient((request) async {
          expect(request.url.path, '/api/v1/dashboard');
          expect(request.headers['authorization'], 'Bearer test-token');
          return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'dashboard': {
                    'profile': {
                      'name': 'Actual Customer',
                      'email': 'customer@example.test',
                      'avatar': ''
                    },
                    'services': [],
                    'sections': [
                      {
                        'type': 'pooja',
                        'title': 'Poojas',
                        'items': [
                          {
                            'id': 'real',
                            'type': 'pooja',
                            'title': 'Real pooja',
                            'imageUrl': '/api/v1/media/photo/content',
                            'fromPrices': [
                              {'currency': 'INR', 'amount': 800.5}
                            ]
                          }
                        ]
                      }
                    ]
                  }
                }
              }),
              200);
        }));
    final dashboard = await HomeRemoteDataSourceImpl(api).getDashboard();
    expect(dashboard.profile.name, 'Actual Customer');
    expect(dashboard.sections.single.items.single.id, 'real');
    expect(dashboard.sections.single.items.single.imageUrl,
        'https://api.example.test/api/v1/media/photo/content');
    expect(dashboard.sections.single.items.single.prices, ['INR 800.5']);
    expect(dashboard.accommodations, isEmpty);
  });
  test(
      'favourites data source keeps unavailable saved items and uses server IDs for deletion',
      () async {
    final requests = <http.Request>[];
    final api = ApiClient(
        baseUrl: 'https://api.example.test',
        secureStorage: _Storage(),
        client: MockClient((request) async {
          requests.add(request);
          if (request.method == 'GET') {
            return http.Response(
                jsonEncode({
                  'data': {
                    'favorites': [
                      {
                        'id': 'favorite',
                        'targetType': 'package',
                        'targetId': 'package-id',
                        'item': null,
                        'available': false
                      }
                    ]
                  }
                }),
                200);
          }
          if (request.method == 'POST') {
            return http.Response(
                jsonEncode({
                  'data': {
                    'favorite': {'id': 'favorite'}
                  }
                }),
                201);
          }
          return http.Response(jsonEncode({'data': {}}), 200);
        }));
    final source = FavoritesRemoteDataSource(api);
    expect((await source.list()).single.item, isNull);
    expect(await source.save('package', 'package-id'), 'favorite');
    expect(jsonDecode(requests.last.body),
        {'targetType': 'package', 'targetId': 'package-id'});
    await source.remove('favorite');
    expect(requests.last.url.path, '/api/v1/profile/me/favorites/favorite');
    expect(
        requests
            .every((r) => r.headers['authorization'] == 'Bearer test-token'),
        isTrue);
  });
  test(
      'controller saves/removes per type and preserves state after save failures',
      () async {
    final repository = _Repository();
    final controller = FavoritesController(FavoritesActions(repository));
    await controller.load();
    await controller.toggle('pooja', 'real');
    expect(controller.idFor('pooja', 'real'), 'saved');
    expect(controller.idFor('transport', 'real'), isNull);
    await controller.toggle('pooja', 'real');
    expect(controller.items, isEmpty);
    repository.failSave = true;
    await expectLater(controller.toggle('pooja', 'real'), throwsStateError);
    expect(controller.items, isEmpty);
    expect(controller.busy, isEmpty);
    controller.reset();
    expect(controller.loaded, isFalse);
  });
  testWidgets(
      'Favourite tabs show owned category items and remove through the shared controller',
      (tester) async {
    final repository = _Repository();
    repository.rows = [
      const SavedItem(
          id: 'pooja-save',
          type: 'pooja',
          targetId: 'pooja',
          item: HomeFeedItem(id: 'pooja', type: 'pooja', title: 'Saved pooja')),
      const SavedItem(
          id: 'stay-save',
          type: 'accommodation',
          targetId: 'stay',
          item: HomeFeedItem(
              id: 'stay', type: 'accommodation', title: 'Saved stay')),
    ];
    final controller = FavoritesController(FavoritesActions(repository));
    await controller.load();
    getIt.registerSingleton<FavoritesController>(controller);
    addTearDown(() async {
      await getIt.reset();
    });
    await tester.pumpWidget(const MaterialApp(home: FavoritesPage()));
    await tester.pumpAndSettle();
    expect(find.text('Saved pooja'), findsOneWidget);
    expect(find.text('Saved stay'), findsNothing);
    await tester.tap(find.text('Accommodation'));
    await tester.pumpAndSettle();
    expect(find.text('Saved stay'), findsOneWidget);
    expect(find.text('Saved pooja'), findsNothing);
    await tester.tap(find.byTooltip('Remove favourite').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('Saved stay'), findsNothing);
    expect(controller.idFor('accommodation', 'stay'), isNull);
    expect(tester.takeException(), isNull);
  });
  test('section browsing obeys server pagination when a page has fewer cards',
      () async {
    final api = ApiClient(
        baseUrl: 'https://api.example.test',
        secureStorage: _Storage(),
        client: MockClient((request) async {
          expect(request.url.queryParameters['page'], '2');
          return http.Response(
              jsonEncode({
                'data': {
                  'section': {
                    'items': [],
                    'pagination': {'page': 2, 'totalPages': 3}
                  }
                }
              }),
              200);
        }));
    final page = await HomeRemoteDataSourceImpl(api).getSection('pooja', 2);
    expect(page.items, isEmpty);
    expect(page.hasNextPage, isTrue);
  });
  test('package details use the public repository data boundary', () async {
    final api = ApiClient(
        baseUrl: 'https://api.example.test',
        secureStorage: _Storage(),
        client: MockClient((request) async {
          expect(request.url.path, '/api/v1/tourism/packages/real-package');
          return http.Response(
              jsonEncode({
                'data': {
                  'package': {
                    'title': 'Real package',
                    'description': 'Actual itinerary',
                    'durationDays': 2,
                    'durationNights': 1,
                    'inclusions': ['Hotel'],
                    'exclusions': ['Flight'],
                    'itinerary': [
                      {
                        'dayNumber': 1,
                        'title': 'Visit',
                        'description': 'Temple'
                      }
                    ],
                    'pricing': [
                      {'currency': 'INR', 'amount': '2500.50'}
                    ]
                  }
                }
              }),
              200);
        }));
    final package =
        await HomeRemoteDataSourceImpl(api).getPackage('real-package');
    expect(package.title, 'Real package');
    expect(package.inclusions, ['Hotel']);
    expect(package.prices, ['INR 2500.50']);
  });
}
