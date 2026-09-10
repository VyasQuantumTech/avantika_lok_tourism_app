import '../../domain/entities/tourism_place.dart';

class TourismPlaceModel extends TourismPlace {
  const TourismPlaceModel({
    required super.id,
    required super.name,
    required super.slug,
    required super.shortDescription,
    required super.description,
    required super.locationLabel,
    required super.address,
    required super.latitude,
    required super.longitude,
    required super.categories,
    required super.images,
    required super.externalMedia,
    required super.stories,
    required super.detailSections,
    required super.visitorInfo,
  });

  factory TourismPlaceModel.fromJson(
    Map<String, dynamic> json, {
    String baseUrl = '',
  }) {
    final location = _map(json['location']);
    final media = _list(json['media']).isNotEmpty
        ? _list(json['media'])
        : _list(json['images']).isNotEmpty
            ? _list(json['images'])
            : _list(json['mediaAssets']).isNotEmpty
                ? _list(json['mediaAssets'])
                : _list(json['mediaLinks']).isNotEmpty
                    ? _list(json['mediaLinks'])
                    : _list(json['placeMedia']).isNotEmpty
                        ? _list(json['placeMedia'])
                        : <dynamic>[
                    if (_string(json['coverImage'] ?? json['cover_image'] ?? json['primaryImage'] ?? json['primary_image']).isNotEmpty)
                      <String, dynamic>{
                        'url': json['coverImage'] ?? json['cover_image'] ?? json['primaryImage'] ?? json['primary_image'],
                        'isPrimary': true,
                      },
                  ];

    final external = <dynamic>[
      ..._list(json['externalMedia']),
      ..._list(json['external_media']),
      ..._list(json['videoLinks']),
      ..._list(json['videos']),
    ];

    final addressParts = <String>[
      _string(json['addressLine1'] ?? json['address_line_1']),
      _string(json['addressLine2'] ?? json['address_line_2']),
      _string(location['name']),
      _string(json['postalCode'] ?? json['postal_code']),
    ].where((part) => part.trim().isNotEmpty).toList(growable: false);

    final categorySource = _list(json['categories']).isNotEmpty
        ? _list(json['categories'])
        : _list(json['placeCategories']);

    return TourismPlaceModel(
      id: _string(json['id']),
      name: _string(json['name'], fallback: 'Tourism Place'),
      slug: _string(json['slug']),
      shortDescription: _string(json['shortDescription'] ?? json['short_description']),
      description: _string(json['description']),
      locationLabel: _locationLabel(location, json),
      address: addressParts.join(', '),
      latitude: _double(json['latitude']),
      longitude: _double(json['longitude']),
      categories: categorySource
          .map((item) => TourismCategoryModel.fromJson(_map(item)))
          .where((item) => item.name.isNotEmpty)
          .toList(growable: false),
      images: media
          .map((item) => TourismImageModel.fromJson(_map(item), baseUrl: baseUrl))
          .where((item) => item.url.isNotEmpty)
          .toList(growable: false),
      externalMedia: external
          .map((item) => TourismExternalMediaModel.fromJson(_map(item), baseUrl: baseUrl))
          .where((item) => item.url.isNotEmpty)
          .toList(growable: false),
      stories: _list(json['stories'])
          .map((item) => TourismStoryModel.fromJson(_map(item)))
          .where((item) => item.title.isNotEmpty || item.content.isNotEmpty)
          .toList(growable: false),
      detailSections: _list(json['detailSections'] ?? json['detail_sections'])
          .map((item) => TourismDetailSectionModel.fromJson(_map(item)))
          .where((item) => item.title.isNotEmpty || item.content.isNotEmpty)
          .toList(growable: false),
      visitorInfo: Map<String, dynamic>.from(
        _map(json['visitorInfo'] ?? json['visitor_info']),
      ),
    );
  }
}

class TourismCategoryModel extends TourismCategory {
  const TourismCategoryModel({required super.id, required super.name, required super.slug});

  factory TourismCategoryModel.fromJson(Map<String, dynamic> json) {
    final nested = _map(json['category']);
    final source = nested.isNotEmpty ? nested : json;
    return TourismCategoryModel(
      id: _string(source['id']),
      name: _string(source['name']),
      slug: _string(source['slug']),
    );
  }
}

class TourismImageModel extends TourismImage {
  const TourismImageModel({
    required super.url,
    required super.thumbnailUrl,
    required super.altText,
    required super.caption,
    required super.isPrimary,
  });

  factory TourismImageModel.fromJson(
    Map<String, dynamic> json, {
    String baseUrl = '',
  }) {
    final asset = _map(json['mediaAsset'] ?? json['media_asset']);
    final pivot = _map(json['PlaceMedia'] ?? json['placeMedia'] ?? json['place_media']);
    final source = asset.isNotEmpty ? <String, dynamic>{...asset, ...json} : json;
    return TourismImageModel(
      url: _absoluteUrl(_string(source['url'] ?? source['fileUrl'] ?? source['file_url'] ?? source['path']), baseUrl),
      thumbnailUrl: _absoluteUrl(_string(source['thumbnailUrl'] ?? source['thumbnail_url']), baseUrl),
      altText: _string(source['altText'] ?? source['alt_text']),
      caption: _string(source['caption']),
      isPrimary: _bool(
        source['isPrimary'] ?? source['is_primary'] ?? pivot['isPrimary'] ?? pivot['is_primary'],
      ),
    );
  }
}

class TourismExternalMediaModel extends TourismExternalMedia {
  const TourismExternalMediaModel({
    required super.type,
    required super.title,
    required super.url,
    required super.thumbnailUrl,
    required super.description,
  });

  factory TourismExternalMediaModel.fromJson(
    Map<String, dynamic> json, {
    String baseUrl = '',
  }) {
    return TourismExternalMediaModel(
      type: _string(json['type'], fallback: 'youtube_video'),
      title: _string(json['title']),
      url: _absoluteUrl(_string(json['url'] ?? json['videoUrl'] ?? json['video_url']), baseUrl),
      thumbnailUrl: _absoluteUrl(_string(json['thumbnailUrl'] ?? json['thumbnail_url']), baseUrl),
      description: _string(json['description']),
    );
  }
}

class TourismStoryModel extends TourismStory {
  const TourismStoryModel({required super.title, required super.content});

  factory TourismStoryModel.fromJson(Map<String, dynamic> json) {
    return TourismStoryModel(
      title: _string(json['title'], fallback: 'Story'),
      content: _string(json['content'] ?? json['description']),
    );
  }
}

class TourismDetailSectionModel extends TourismDetailSection {
  const TourismDetailSectionModel({required super.title, required super.content});

  factory TourismDetailSectionModel.fromJson(Map<String, dynamic> json) {
    return TourismDetailSectionModel(
      title: _string(json['title'] ?? json['heading']),
      content: _string(json['content'] ?? json['description'] ?? json['body']),
    );
  }
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, item) => MapEntry(key.toString(), item));
  return <String, dynamic>{};
}

List<dynamic> _list(dynamic value) => value is List ? value : const <dynamic>[];

String _string(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

double? _double(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(_string(value));
}

bool _bool(dynamic value) {
  if (value is bool) return value;
  return _string(value).toLowerCase() == 'true';
}

String _locationLabel(Map<String, dynamic> location, Map<String, dynamic> place) {
  final parts = <String>[
    _string(location['name']),
    _string(location['state'] ?? location['stateName'] ?? location['state_name']),
    _string(location['country'] ?? location['countryName'] ?? location['country_name']),
  ].where((part) => part.isNotEmpty).toList(growable: false);
  if (parts.isNotEmpty) return parts.toSet().join(', ');
  return _string(place['locationName'] ?? place['location_name']);
}


String _absoluteUrl(String value, String baseUrl) {
  if (value.isEmpty) return '';
  final uri = Uri.tryParse(value);
  if (uri != null && uri.hasScheme) return value;
  if (baseUrl.isEmpty) return value;
  final cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
  final cleanPath = value.startsWith('/') ? value : '/$value';
  return '$cleanBase$cleanPath';
}
