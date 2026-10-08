import '../../domain/entities/app_notification.dart';

Map<String, dynamic> notificationMap(dynamic value) => value is Map
    ? value.map((key, value) => MapEntry(key.toString(), value))
    : {};

class AppNotificationModel extends AppNotification {
  AppNotificationModel.fromJson(Map<String, dynamic> json)
      : super(
            id: json['id'] as String,
            title: json['title'] as String? ?? '',
            body: json['body'] as String? ?? '',
            appFlavor: json['appFlavor'] as String? ?? 'customer',
            category: json['category'] as String? ?? 'system',
            eventType: json['eventType'] as String? ?? '',
            priority: json['priority'] as String? ?? 'normal',
            mandatory: json['mandatory'] == true,
            data: notificationMap(json['data']),
            route: notificationMap(json['deepLink'])['route'] as String? ?? '',
            createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
            readAt: DateTime.tryParse(json['readAt']?.toString() ?? ''));
}

NotificationInbox inboxFromJson(Map<String, dynamic> json) {
  final pagination = notificationMap(json['pagination']);
  return NotificationInbox(
      items: (json['items'] as List? ?? [])
          .map((value) => AppNotificationModel.fromJson(notificationMap(value)))
          .toList(),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      page: (pagination['page'] as num?)?.toInt() ?? 1,
      totalPages: (pagination['totalPages'] as num?)?.toInt() ?? 0);
}

NotificationPreferences preferencesFromJson(Map<String, dynamic> json) {
  final quiet = notificationMap(json['quietHours']);
  return NotificationPreferences(
      locale: json['locale'] as String? ?? 'en',
      categories: notificationMap(json['categories'])
          .map((key, value) => MapEntry(key, value != false)),
      marketingConsent: json['marketingConsent'] == true,
      quietHoursEnabled: quiet['enabled'] == true,
      quietHoursStart: quiet['start'] as String? ?? '22:00',
      quietHoursEnd: quiet['end'] as String? ?? '07:00',
      timezone: quiet['timezone'] as String? ?? 'Asia/Kolkata');
}

Map<String, dynamic> preferencesToJson(NotificationPreferences value) => {
      'locale': value.locale,
      'categories': {...value.categories, 'security': true},
      'marketingConsent': value.marketingConsent,
      'consentSource': 'mobile_settings',
      'consentVersion': '1',
      'quietHours': {
        'enabled': value.quietHoursEnabled,
        'start': value.quietHoursStart,
        'end': value.quietHoursEnd,
        'timezone': value.timezone
      }
    };
