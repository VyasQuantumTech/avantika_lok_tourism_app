import 'package:flutter/material.dart';
import '../../../app/di/injection.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/widgets/app_ui.dart';
import '../domain/usecases/marketplace_actions.dart';

// Optional tracking equipment only. Provider KYC identifies the trip operator.
class ProviderTransportOperationsPage extends StatefulWidget {
  const ProviderTransportOperationsPage({super.key});
  @override
  State<ProviderTransportOperationsPage> createState() => _DevicesState();
}

class _DevicesState extends State<ProviderTransportOperationsPage> {
  late Future<Map<String, dynamic>> future;
  @override
  void initState() {
    super.initState();
    load();
  }

  void load() {
    future = getIt<MarketplaceActions>()
        .providerCall('devices')
        .then((value) => Map<String, dynamic>.from(value as Map));
  }

  Future<void> edit([Map<String, dynamic>? row]) async {
    final body = await showDialog<Map<String, dynamic>>(
        context: context, builder: (_) => _DeviceDialog(initial: row ?? {}));
    if (body == null || !mounted) return;
    try {
      await getIt<MarketplaceActions>()
          .providerCall('saveDevice', id: row?['id']?.toString(), body: body);
      if (mounted) {
        setState(load);
        AppFeedback.success(context, 'Tracking device saved.');
      }
    } on ApiException catch (e) {
      if (mounted) AppFeedback.error(context, e.message);
    } catch (_) {
      if (mounted) {
        AppFeedback.error(context, 'Unable to save this device. Please retry.');
      }
    }
  }

  @override
  Widget build(BuildContext context) => AppPage(
      title: 'Tracking devices',
      subtitle: 'Optional equipment for your vehicles',
      child: FutureBuilder<Map<String, dynamic>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return AppErrorState(
                  message: snapshot.error is ApiException
                      ? (snapshot.error as ApiException).message
                      : 'Unable to load tracking devices.',
                  onRetry: () => setState(load));
            }
            if (!snapshot.hasData) return const AppLoadingView();
            final rows =
                (snapshot.data!['items'] as List? ?? []).whereType<Map>();
            return ListView(children: [
              const AppPanel(
                  child: Text(
                      'You drive your trips using your approved provider account. Separate driver registration and assignment are not required.')),
              OutlinedButton.icon(
                  onPressed: () => edit(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add device')),
              if (rows.isEmpty) const Text('No tracking devices added.'),
              for (final row in rows)
                ListTile(
                    title: Text('${row['label'] ?? row['deviceUid']}'),
                    subtitle: Text('${row['status']}'),
                    trailing: IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => edit(Map<String, dynamic>.from(row)))),
            ]);
          }));
}

class _DeviceDialog extends StatefulWidget {
  const _DeviceDialog({required this.initial});
  final Map<String, dynamic> initial;
  @override
  State<_DeviceDialog> createState() => _DeviceDialogState();
}

class _DeviceDialogState extends State<_DeviceDialog> {
  final form = GlobalKey<FormState>();
  late final TextEditingController identifier, name;
  late String status;
  @override
  void initState() {
    super.initState();
    identifier =
        TextEditingController(text: '${widget.initial['deviceUid'] ?? ''}');
    name = TextEditingController(text: '${widget.initial['label'] ?? ''}');
    status = '${widget.initial['status'] ?? 'inactive'}';
  }

  @override
  void dispose() {
    identifier.dispose();
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
          title: const Text('Tracking device'),
          content: Form(
              key: form,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextFormField(
                    controller: identifier,
                    decoration:
                        const InputDecoration(labelText: 'Device identifier'),
                    validator: (v) => (v ?? '').trim().length < 3
                        ? 'Enter at least 3 characters.'
                        : null),
                TextFormField(
                    controller: name,
                    decoration:
                        const InputDecoration(labelText: 'Device name')),
                DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const ['inactive', 'active', 'suspended']
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) => status = v!),
              ])),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () {
                  if (form.currentState!.validate()) {
                    Navigator.pop(context, <String, dynamic>{
                      'deviceUid': identifier.text.trim(),
                      'label':
                          name.text.trim().isEmpty ? null : name.text.trim(),
                      'status': status
                    });
                  }
                },
                child: const Text('Save'))
          ]);
}
