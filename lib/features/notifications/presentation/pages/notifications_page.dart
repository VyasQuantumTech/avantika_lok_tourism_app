import 'package:flutter/material.dart';
import '../../../../app/di/injection.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/notification_service.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/usecases/notification_actions.dart';

const notificationCategoryLabels = <String, String>{
  'transactions': 'Payments',
  'booking_updates': 'Booking updates',
  'reminders': 'Reminders',
  'reviews': 'Reviews',
  'marketing': 'Offers',
  'system': 'System',
  'security': 'Security'
};

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _actions = getIt<NotificationActions>();
  final _service = getIt<NotificationService>();
  final List<AppNotification> _items = [];
  bool _loading = true,
      _loadingMore = false,
      _marking = false,
      _unreadOnly = false;
  String? _category, _error;
  int _page = 0, _totalPages = 0, _request = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool more = false}) async {
    if (more && (_loading || _loadingMore || _page >= _totalPages)) return;
    final request = ++_request;
    final next = more ? _page + 1 : 1;
    setState(() {
      _error = null;
      if (more) {
        _loadingMore = true;
      } else {
        _loading = true;
        _loadingMore = false;
      }
    });
    try {
      final result = await _actions.inbox(
          appFlavor: _service.appFlavor,
          page: next,
          unreadOnly: _unreadOnly,
          category: _category);
      if (!mounted || request != _request || !_service.active) return;
      setState(() {
        if (!more) _items.clear();
        final existing = _items.map((item) => item.id).toSet();
        _items.addAll(result.items.where((item) =>
            item.appFlavor == _service.appFlavor && existing.add(item.id)));
        _page = result.page;
        _totalPages = result.totalPages;
      });
      await _service.refreshUnreadCount();
    } catch (error) {
      if (mounted && request == _request) {
        setState(() => _error = error is ApiException
            ? error.message
            : 'Unable to load notifications. Please try again.');
      }
    } finally {
      if (mounted && request == _request) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _markAll() async {
    setState(() => _marking = true);
    try {
      await _actions.markAllRead(_service.appFlavor);
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Unable to mark notifications as read. Please retry.')));
      }
    } finally {
      if (mounted) setState(() => _marking = false);
    }
  }

  Future<void> _open(AppNotification item) async {
    await Navigator.of(context)
        .pushNamed(RouteNames.notificationDetail, arguments: item.id);
    if (mounted && _service.active) await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Notifications'), actions: [
        IconButton(
            tooltip: 'Notification settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context)
                .pushNamed(RouteNames.notificationPreferences)),
        IconButton(
            tooltip: 'Mark all as read',
            icon: const Icon(Icons.done_all),
            onPressed: _marking || _loading ? null : _markAll)
      ]),
      body: Column(children: [
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              FilterChip(
                  label: const Text('Unread'),
                  selected: _unreadOnly,
                  onSelected: (value) {
                    setState(() => _unreadOnly = value);
                    _load();
                  }),
              const SizedBox(width: 16),
              Expanded(
                  child: DropdownButton<String>(
                      isExpanded: true,
                      value: _category ?? '',
                      items: [
                        const DropdownMenuItem(
                            value: '', child: Text('All categories')),
                        ...notificationCategoryLabels.entries.map((entry) =>
                            DropdownMenuItem(
                                value: entry.key, child: Text(entry.value)))
                      ],
                      onChanged: (value) {
                        setState(() => _category = value == '' ? null : value);
                        _load();
                      }))
            ])),
        Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (_error != null) ...[
                            Text(_error!, textAlign: TextAlign.center),
                            TextButton(
                                onPressed: () => _load(more: _items.isNotEmpty),
                                child: const Text('Retry'))
                          ],
                          if (_items.isEmpty && _error == null)
                            const Padding(
                                padding: EdgeInsets.symmetric(vertical: 80),
                                child: Column(children: [
                                  Icon(Icons.notifications_none, size: 48),
                                  SizedBox(height: 16),
                                  Text('No notifications yet')
                                ])),
                          ..._items.map((item) => Card(
                              child: ListTile(
                                  leading: Icon(item.isUnread
                                      ? Icons.notifications_active_outlined
                                      : Icons.notifications_outlined),
                                  title: Text(item.title,
                                      style: TextStyle(
                                          fontWeight: item.isUnread
                                              ? FontWeight.bold
                                              : FontWeight.normal)),
                                  subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(item.body,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 6),
                                        Text(
                                            '${notificationCategoryLabels[item.category] ?? item.category}${item.mandatory ? ' • Required' : ''}'),
                                        if (item.createdAt != null)
                                          Text(MaterialLocalizations.of(context)
                                              .formatShortDate(
                                                  item.createdAt!.toLocal()))
                                      ]),
                                  isThreeLine: true,
                                  onTap: () => _open(item)))),
                          if (_page < _totalPages)
                            TextButton(
                                onPressed: _loadingMore
                                    ? null
                                    : () => _load(more: true),
                                child: Text(
                                    _loadingMore ? 'Loading…' : 'Load more')),
                        ]))),
      ]));
}
