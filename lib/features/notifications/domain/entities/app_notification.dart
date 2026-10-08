class AppNotification {
  const AppNotification(
      {required this.id,
      required this.title,
      required this.body,
      required this.appFlavor,
      required this.category,
      required this.eventType,
      required this.priority,
      required this.mandatory,
      required this.data,
      required this.route,
      this.createdAt,
      this.readAt});
  final String id, title, body, appFlavor, category, eventType, priority, route;
  final bool mandatory;
  final Map<String, dynamic> data;
  final DateTime? createdAt, readAt;
  bool get isUnread => readAt == null;
}

class NotificationInbox {
  const NotificationInbox(
      {required this.items,
      required this.unreadCount,
      required this.page,
      required this.totalPages});
  final List<AppNotification> items;
  final int unreadCount, page, totalPages;
}

class NotificationPreferences {
  const NotificationPreferences(
      {this.locale = 'en',
      this.categories = const {},
      this.marketingConsent = false,
      this.quietHoursEnabled = false,
      this.quietHoursStart = '22:00',
      this.quietHoursEnd = '07:00',
      this.timezone = 'Asia/Kolkata'});
  final String locale, quietHoursStart, quietHoursEnd, timezone;
  final Map<String, bool> categories;
  final bool marketingConsent, quietHoursEnabled;
}
