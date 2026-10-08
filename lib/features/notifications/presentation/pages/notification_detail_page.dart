import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../app/config/app_config.dart';
import '../../../../app/config/app_flavor.dart';
import '../../../../app/di/injection.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/notification_service.dart';
import '../../../provider/domain/usecases/check_provider_status.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/usecases/notification_actions.dart';
import '../notification_destination.dart';

class NotificationDetailPage extends StatefulWidget {
  const NotificationDetailPage(
      {required this.id, this.channel = 'in_app', super.key});
  final String id, channel;
  @override
  State<NotificationDetailPage> createState() => _NotificationDetailPageState();
}

class _NotificationDetailPageState extends State<NotificationDetailPage> {
  late Future<AppNotification> _future;
  bool _opening = false;
  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<AppNotification> _load() async {
    final actions = getIt<NotificationActions>();
    final service = getIt<NotificationService>();
    final item = await actions.detail(widget.id);
    if (!service.active || item.appFlavor != service.appFlavor) {
      throw const ApiException(
          'This notification is not available in this app.');
    }
    final read = item.isUnread ? await actions.markRead(item.id) : item;
    await service.refreshUnreadCount();
    unawaited(
        service.recordInteraction(item.id, 'opened', channel: widget.channel));
    return read;
  }

  Future<void> _openRelated(AppNotification item) async {
    setState(() => _opening = true);
    try {
      final flavor = getIt<AppConfig>().flavor;
      String? providerType;
      bool providerApproved = true;
      if (flavor == AppFlavor.provider) {
        final status = await getIt<CheckProviderStatus>()();
        providerType = status.providerType;
        providerApproved = status.kycStatus == 'approved';
      }
      final destination =
          notificationDestination(item, flavor, providerType: providerType);
      if (!mounted ||
          !getIt<NotificationService>().active ||
          destination == null) {
        return;
      }
      unawaited(getIt<NotificationService>()
          .recordInteraction(item.id, 'clicked', channel: widget.channel));
      if (!mounted) return;
      await Navigator.of(context).pushNamed(
          providerApproved || destination.route == RouteNames.providerKyc
              ? destination.route
              : RouteNames.providerGate,
          arguments: providerApproved ? destination.arguments : null);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(error is ApiException
                ? error.message
                : 'Unable to open related details. Please retry.')));
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Notification')),
      body: FutureBuilder<AppNotification>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || snapshot.data == null) {
              return Center(
                  child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(snapshot.error is ApiException
                            ? (snapshot.error as ApiException).message
                            : 'Unable to load this notification.'),
                        TextButton(
                            onPressed: () => setState(() => _future = _load()),
                            child: const Text('Retry'))
                      ])));
            }
            final item = snapshot.data!;
            final destination =
                notificationDestination(item, getIt<AppConfig>().flavor);
            return ListView(padding: const EdgeInsets.all(24), children: [
              Text(item.title,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              if (item.createdAt != null)
                Text(MaterialLocalizations.of(context)
                    .formatShortDate(item.createdAt!.toLocal())),
              if (item.mandatory)
                const Text('Required account or service notification'),
              const SizedBox(height: 20),
              SelectableText(item.body),
              const SizedBox(height: 24),
              if (destination != null)
                FilledButton(
                    onPressed: _opening ? null : () => _openRelated(item),
                    child: Text(_opening ? 'Opening…' : 'View related details'))
            ]);
          }));
}
