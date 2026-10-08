import 'dart:convert';
import 'package:avantika_lok_tourism_app/app/config/app_flavor.dart';
import 'package:avantika_lok_tourism_app/core/ network/api_client.dart';
import 'package:avantika_lok_tourism_app/core/services/notification_service.dart';
import 'package:avantika_lok_tourism_app/core/storage/secure_storage_service.dart';
import 'package:avantika_lok_tourism_app/features/notifications/data/datasources/notification_remote_data_source.dart';
import 'package:avantika_lok_tourism_app/features/notifications/data/models/notification_models.dart';
import 'package:avantika_lok_tourism_app/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:avantika_lok_tourism_app/features/notifications/domain/entities/app_notification.dart';
import 'package:avantika_lok_tourism_app/features/notifications/presentation/notification_destination.dart';
import 'package:avantika_lok_tourism_app/app/router/route_names.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'notification_fakes.dart';

class _SessionStorage extends SecureStorageService {
  _SessionStorage() : super(const FlutterSecureStorage());
  @override
  Future<String?> readAccessToken() async => 'session-token';
}

void main() {
  final item = {
    'id': 'notice-1',
    'title': 'Booking confirmed',
    'body': 'Confirmed',
    'appFlavor': 'provider',
    'category': 'booking_updates',
    'mandatory': true,
    'readAt': null,
    'createdAt': '2026-10-08T12:00:00Z',
    'deepLink': {'route': '/provider/bookings/booking-1'},
    'data': {'bookingId': 'booking-1'}
  };
  test('API contract uses authentication, flavor queries and backend envelopes',
      () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      expect(request.headers['Authorization'], 'Bearer session-token');
      final path = request.url.path;
      dynamic data;
      if (path.endsWith('/unread-count')) {
        data = {'unreadCount': 4};
      } else if (path.endsWith('/preferences')) {
        data = request.method == 'PATCH'
            ? jsonDecode(request.body)
            : {'categories': {}, 'quietHours': {}, 'marketingConsent': false};
      } else if (path.endsWith('/devices')) {
        data = {'id': 'registered-device'};
      } else if (path.endsWith('/notice-1') ||
          path.endsWith('/notice-1/read')) {
        data = {'notification': item};
      } else if (path.endsWith('/notifications')) {
        data = {
          'items': [item],
          'unreadCount': 4,
          'pagination': {'page': 2, 'totalPages': 5}
        };
      } else {
        data = {};
      }
      return http.Response(jsonEncode({'success': true, 'data': data}), 200);
    });
    final repository = NotificationRepositoryImpl(NotificationRemoteDataSource(
        ApiClient(
            baseUrl: 'https://backend.test',
            client: client,
            secureStorage: _SessionStorage())));
    final inbox = await repository.inbox(
        appFlavor: 'provider',
        page: 2,
        unreadOnly: true,
        category: 'booking_updates');
    expect(inbox.items.single.isUnread, true);
    expect(inbox.page, 2);
    expect(inbox.totalPages, 5);
    expect(requests.last.url.queryParameters, {
      'appFlavor': 'provider',
      'page': '2',
      'pageSize': '20',
      'unreadOnly': 'true',
      'category': 'booking_updates'
    });
    expect(await repository.unreadCount('provider'), 4);
    expect((await repository.detail('notice-1')).route,
        '/provider/bookings/booking-1');
    await repository.markRead('notice-1');
    expect(requests.last.method, 'PATCH');
    await repository.markAllRead('provider');
    expect(requests.last.url.queryParameters, {'appFlavor': 'provider'});
    final preferences = await repository.preferences();
    expect(preferences.quietHoursStart, '22:00');
    expect(preferences.marketingConsent, false);
    await repository.updatePreferences(const NotificationPreferences(
        categories: {'security': false}, marketingConsent: true, locale: 'hi'));
    final body = jsonDecode(requests.last.body) as Map;
    expect(body['categories']['security'], true);
    expect(body['consentSource'], 'mobile_settings');
    expect(body['consentVersion'], '1');
    expect(body['marketingConsent'], true);
    expect(
        await repository.registerDevice(
            deviceId: 'installation',
            token: 'token',
            appFlavor: 'provider',
            environment: 'production',
            platform: 'ios'),
        'registered-device');
    expect(jsonDecode(requests.last.body), {
      'deviceId': 'installation',
      'token': 'token',
      'appFlavor': 'provider',
      'environment': 'production',
      'platform': 'ios'
    });
    await repository.deactivateDevice('registered-device');
    expect(requests.last.method, 'DELETE');
    await repository.interaction('notice-1', 'opened', channel: 'push');
    expect(
        jsonDecode(requests.last.body), {'kind': 'opened', 'channel': 'push'});
    client.close();
  });
  test('all flavor names match the backend', () {
    expect(AppFlavor.values.map(notificationAppFlavor),
        ['customer', 'provider', 'admin']);
  });
  test(
      'preference defaults preserve mandatory security and no marketing consent',
      () {
    final value = preferencesFromJson({});
    expect(value.marketingConsent, false);
    expect(value.quietHoursEnabled, false);
    expect(preferencesToJson(value)['categories'], {'security': true});
  });
  test('customer booking targets existing detail screen', () {
    final value = notificationDestination(notification(), AppFlavor.user)!;
    expect(value.route, RouteNames.customerPoojaBookingDetail);
    expect(value.arguments, 'booking-1');
  });
  test('provider booking links follow each actual provider type', () {
    final item =
        notification(flavor: 'provider', route: '/provider/bookings/booking-1');
    for (final entry in {
      'pandit': RouteNames.panditPoojaBookings,
      'hotel_manager': RouteNames.providerAccommodationBookings,
      'vehicle_owner': RouteNames.providerTransportBookings
    }.entries) {
      expect(
          notificationDestination(item, AppFlavor.provider,
                  providerType: entry.key)!
              .route,
          entry.value);
    }
  });
  test('unsupported, external and cross-flavor links never navigate', () {
    for (final route in [
      'https://example.com/customer/bookings/1',
      '//example.com/customer/profile',
      '/provider/bookings/1',
      '/customer/unknown/1',
      '/customer/bookings/1?redirect=/provider/kyc'
    ]) {
      expect(
          notificationDestination(notification(route: route), AppFlavor.user),
          null);
    }
    expect(
        notificationDestination(
            notification(flavor: 'provider'), AppFlavor.user),
        null);
    expect(
        notificationDestination(
            notification(flavor: 'admin', route: '/admin/approvals'),
            AppFlavor.admin),
        null);
  });
}
