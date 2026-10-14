/// Accept only YouTube hosts and valid video IDs, including Shorts/live links.
String? youtubeVideoId(String url) {
  final value = url.trim();
  final validId = RegExp(r'^[a-zA-Z0-9_-]{11}$');
  if (validId.hasMatch(value)) return value;
  final uri = Uri.tryParse(value);
  if (uri == null || !['https', 'http'].contains(uri.scheme)) return null;
  final host = uri.host.toLowerCase();
  String? id;
  if (host == 'youtu.be' || host == 'www.youtu.be') {
    id = uri.pathSegments.isEmpty ? null : uri.pathSegments.first;
  } else if (host == 'youtube.com' ||
      host.endsWith('.youtube.com') ||
      host == 'youtube-nocookie.com' ||
      host.endsWith('.youtube-nocookie.com')) {
    id = uri.queryParameters['v'];
    if (id == null &&
        uri.pathSegments.length >= 2 &&
        ['embed', 'shorts', 'live', 'v'].contains(uri.pathSegments.first)) {
      id = uri.pathSegments[1];
    }
  }
  return id != null && validId.hasMatch(id) ? id : null;
}

String youtubeThumbnail(String url) {
  final id = youtubeVideoId(url);
  return id == null ? '' : 'https://img.youtube.com/vi/$id/hqdefault.jpg';
}
