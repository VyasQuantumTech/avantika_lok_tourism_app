import 'package:flutter_test/flutter_test.dart';
import 'package:avantika_lok_tourism_app/core/utils/media_urls.dart';
import 'package:avantika_lok_tourism_app/features/marketplace/data/datasources/marketplace_remote_data_source.dart';
import 'package:avantika_lok_tourism_app/features/marketplace/domain/entities/marketplace_entities.dart';
import '../bookings/booking_contract_test.dart' as fixtures;

void main() {
  test('backend media paths use API origin; absolute signed URLs remain intact',
      () {
    for (final path in [
      '/api/v1/media/photo/content',
      'api/v1/media/photo/content'
    ]) {
      expect(
          resolveMediaUrl(path, 'https://backend.test:8443/api/v1/?tenant=1'),
          'https://backend.test:8443/api/v1/media/photo/content');
    }
    expect(
        resolveMediaUrl('https://cdn.test/photo.jpg?signature=a%2Fb',
            'https://backend.test'),
        'https://cdn.test/photo.jpg?signature=a%2Fb');
    expect(resolveMediaUrl('//cdn.test/photo.jpg', 'https://backend.test'),
        'https://cdn.test/photo.jpg');
    expect(resolveMediaUrl('javascript:invalid', 'https://backend.test'), '');
    expect(resolveMediaUrl('', 'https://backend.test'), '');
  });

  test(
      'nested room photos normalize without mutating payload or private storage keys',
      () {
    final raw = <String, dynamic>{
      'units': [
        {
          'id': 'unit-1',
          'mediaAssets': [
            {'url': '/api/v1/media/room/content'}
          ]
        },
      ],
      'documents': [
        {'storageKey': 'private/insurance.jpg'}
      ],
      'images': ['/api/v1/media/property/content']
    };
    final normalized = normalizeMediaUrls(raw, 'https://backend.test');
    expect((normalized['units'] as List).first['mediaAssets'].first['url'],
        'https://backend.test/api/v1/media/room/content');
    expect(normalized['images'],
        ['https://backend.test/api/v1/media/property/content']);
    expect((raw['units'] as List).first['mediaAssets'].first['url'],
        '/api/v1/media/room/content');
    expect((normalized['documents'] as List).first['storageKey'],
        'private/insurance.jpg');
  });

  test('gallery selects one image per asset and excludes video/private media',
      () {
    final item = MarketplaceItem(type: MarketplaceType.transport, raw: {
      'mediaAssets': [
        {
          'type': 'image',
          'url': 'https://backend.test/original',
          'thumbnailUrl': 'https://backend.test/thumb'
        },
        {
          'type': 'image',
          'url': '',
          'thumbnailUrl': 'https://backend.test/second'
        },
        {'type': 'video', 'url': 'https://backend.test/video'},
        {'visibility': 'private', 'url': 'https://backend.test/private'},
      ],
    });
    expect(item.imageUrls,
        ['https://backend.test/original', 'https://backend.test/second']);
  });

  test(
      'transport listing and detail resolve public vehicle photos at data boundary',
      () async {
    final remote =
        MarketplaceRemoteDataSourceImpl(fixtures.api((request) async {
      final vehicle = {
        'id': 'vehicle-1',
        'mediaAssets': [
          {
            'url': '/api/v1/media/photo/content',
            'thumbnailUrl': '/api/v1/media/photo/thumbnail'
          },
        ]
      };
      return request.url.path.endsWith('/vehicles/vehicle-1')
          ? fixtures.response({'vehicle': vehicle})
          : fixtures.response({
              'items': [
                {
                  'vehicles': [vehicle]
                }
              ],
              'pagination': {'totalPages': 1}
            });
    }));
    final list = await remote.publicItems(MarketplaceType.transport);
    final detail =
        await remote.publicDetail(MarketplaceType.transport, 'vehicle-1');
    expect(list.single.imageUrls,
        ['https://backend.test/api/v1/media/photo/content']);
    expect(detail.imageUrls, list.single.imageUrls);
  });
}
