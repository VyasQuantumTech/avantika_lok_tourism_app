/// Resolve public media paths against the configured API origin, independently
/// of any API path prefix. Absolute CDN URLs and signed queries stay intact.
String resolveMediaUrl(String value, String baseUrl) {
  final path = value.trim();
  if (path.isEmpty) return '';
  final uri = Uri.tryParse(path);
  if (uri == null) return '';
  if (uri.hasScheme) {
    return (uri.scheme == 'http' || uri.scheme == 'https') &&
            uri.host.isNotEmpty
        ? path
        : '';
  }
  final base = Uri.tryParse(baseUrl);
  if (base == null ||
      !const {'http', 'https'}.contains(base.scheme) ||
      base.host.isEmpty) return '';
  return Uri.parse('${base.origin}/').resolveUri(uri).toString();
}

/// Normalize copies at the data boundary so nested room/vehicle images are
/// usable by both customer and provider widgets without changing API payloads.
Map<String, dynamic> normalizeMediaUrls(
    Map<String, dynamic> raw, String baseUrl) {
  const fields = {
    'url',
    'public_url',
    'publicUrl',
    'media_url',
    'mediaUrl',
    'content_url',
    'contentUrl',
    'thumbnail_url',
    'thumbnailUrl',
    'image_url',
    'imageUrl',
    'cover_image_url',
    'coverImageUrl',
    'coverUrl'
  };
  const collections = {'mediaAssets', 'media', 'images', 'gallery'};
  dynamic normalize(dynamic value, {bool media = false}) {
    if (value is Map) {
      return value.map((key, child) => MapEntry(
          '$key',
          fields.contains('$key') && child is String
              ? resolveMediaUrl(child, baseUrl)
              : normalize(child, media: collections.contains('$key'))));
    }
    if (value is List)
      return value.map((child) => normalize(child, media: media)).toList();
    if (media && value is String) return resolveMediaUrl(value, baseUrl);
    return value;
  }

  return Map<String, dynamic>.from(normalize(raw) as Map);
}
