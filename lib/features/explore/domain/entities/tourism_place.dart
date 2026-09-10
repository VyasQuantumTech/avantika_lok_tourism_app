class TourismPlace {
  const TourismPlace({
    required this.id,
    required this.name,
    required this.slug,
    required this.shortDescription,
    required this.description,
    required this.locationLabel,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.categories,
    required this.images,
    required this.externalMedia,
    required this.stories,
    required this.detailSections,
    required this.visitorInfo,
  });

  final String id;
  final String name;
  final String slug;
  final String shortDescription;
  final String description;
  final String locationLabel;
  final String address;
  final double? latitude;
  final double? longitude;
  final List<TourismCategory> categories;
  final List<TourismImage> images;
  final List<TourismExternalMedia> externalMedia;
  final List<TourismStory> stories;
  final List<TourismDetailSection> detailSections;
  final Map<String, dynamic> visitorInfo;

  String get coverImage {
    if (images.isEmpty) return '';
    final primary = images.where((image) => image.isPrimary);
    return primary.isNotEmpty ? primary.first.url : images.first.url;
  }
}

class TourismCategory {
  const TourismCategory({required this.id, required this.name, required this.slug});

  final String id;
  final String name;
  final String slug;
}

class TourismImage {
  const TourismImage({
    required this.url,
    required this.thumbnailUrl,
    required this.altText,
    required this.caption,
    required this.isPrimary,
  });

  final String url;
  final String thumbnailUrl;
  final String altText;
  final String caption;
  final bool isPrimary;
}

class TourismExternalMedia {
  const TourismExternalMedia({
    required this.type,
    required this.title,
    required this.url,
    required this.thumbnailUrl,
    required this.description,
  });

  final String type;
  final String title;
  final String url;
  final String thumbnailUrl;
  final String description;

  bool get isVideo => type.toLowerCase().contains('video') || type.toLowerCase().contains('youtube');
}

class TourismStory {
  const TourismStory({required this.title, required this.content});

  final String title;
  final String content;
}

class TourismDetailSection {
  const TourismDetailSection({required this.title, required this.content});

  final String title;
  final String content;
}
