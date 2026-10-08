import '../../../../core/ network/api_client.dart';
import '../../../../core/ network/endpoints.dart';
import '../models/notification_models.dart';

class NotificationRemoteDataSource {
  const NotificationRemoteDataSource(this._client);
  final ApiClient _client;
  String query(String path, Map<String, String> values) =>
      Uri(path: path, queryParameters: values).toString();
  Future<Map<String, dynamic>> inbox(
          {required String appFlavor,
          required int page,
          required bool unreadOnly,
          String? category}) async =>
      notificationMap((await _client.get(
          query(Endpoints.notifications, {
            'appFlavor': appFlavor,
            'page': '$page',
            'pageSize': '20',
            'unreadOnly': '$unreadOnly',
            if (category != null) 'category': category
          }),
          authenticated: true))['data']);
  Future<int> unreadCount(String flavor) async =>
      (notificationMap((await _client.get(
              query('${Endpoints.notifications}/unread-count',
                  {'appFlavor': flavor}),
              authenticated: true))['data'])['unreadCount'] as num)
          .toInt();
  Future<Map<String, dynamic>> detail(String id) async =>
      notificationMap(notificationMap((await _client.get(
          '${Endpoints.notifications}/${Uri.encodeComponent(id)}',
          authenticated: true))['data'])['notification']);
  Future<Map<String, dynamic>> markRead(String id) async =>
      notificationMap(notificationMap((await _client.patch(
          '${Endpoints.notifications}/${Uri.encodeComponent(id)}/read',
          authenticated: true))['data'])['notification']);
  Future<void> markAllRead(String flavor) async {
    await _client.patch(
        query('${Endpoints.notifications}/read-all', {'appFlavor': flavor}),
        authenticated: true);
  }

  Future<Map<String, dynamic>> preferences() async => notificationMap(
      (await _client.get('${Endpoints.notifications}/preferences',
          authenticated: true))['data']);
  Future<Map<String, dynamic>> updatePreferences(
          Map<String, dynamic> body) async =>
      notificationMap((await _client.patch(
          '${Endpoints.notifications}/preferences',
          body: body,
          authenticated: true))['data']);
  Future<String> registerDevice(Map<String, dynamic> body) async =>
      notificationMap((await _client.post('${Endpoints.notifications}/devices',
          body: body, authenticated: true))['data'])['id'] as String;
  Future<void> deactivateDevice(String id) async {
    await _client.delete(
        '${Endpoints.notifications}/devices/${Uri.encodeComponent(id)}',
        authenticated: true);
  }

  Future<void> interaction(String id, String kind, String channel) async {
    await _client.post(
        '${Endpoints.notifications}/${Uri.encodeComponent(id)}/interactions',
        body: {'kind': kind, 'channel': channel},
        authenticated: true);
  }
}
