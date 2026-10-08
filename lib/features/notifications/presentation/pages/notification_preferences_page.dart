import 'package:flutter/material.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/notification_service.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/usecases/notification_actions.dart';
import 'notifications_page.dart';

class NotificationPreferencesPage extends StatefulWidget {
  const NotificationPreferencesPage({super.key});
  @override
  State<NotificationPreferencesPage> createState() =>
      _NotificationPreferencesPageState();
}

class _NotificationPreferencesPageState
    extends State<NotificationPreferencesPage> {
  NotificationPreferences? _value;
  String? _error;
  bool _saving = false, _enabling = false;
  final _timezone = TextEditingController();
  final Map<String, bool> _categories = {};
  String _locale = 'en', _start = '22:00', _end = '07:00';
  bool _marketing = false, _quiet = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timezone.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final value = await getIt<NotificationActions>().preferences();
      if (!mounted) return;
      setState(() {
        _value = value;
        _categories.clear();
        _categories.addAll(value.categories);
        _locale = value.locale;
        _marketing = value.marketingConsent;
        _quiet = value.quietHoursEnabled;
        _start = value.quietHoursStart;
        _end = value.quietHoursEnd;
        _timezone.text = value.timezone;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _error = error is ApiException
            ? error.message
            : 'Unable to load notification settings.');
      }
    }
  }

  Future<void> _pickTime(bool start) async {
    final parts = (start ? _start : _end).split(':');
    final selected = await showTimePicker(
        context: context,
        initialTime:
            TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])));
    if (!mounted || selected == null) return;
    final value =
        '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}';
    setState(() {
      if (start) {
        _start = value;
      } else {
        _end = value;
      }
    });
  }

  Future<void> _save() async {
    if (_start == _end || _timezone.text.trim().isEmpty) {
      setState(() =>
          _error = 'Choose different quiet-hour times and enter a timezone.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await getIt<NotificationActions>().updatePreferences(
          NotificationPreferences(
              locale: _locale,
              categories: {..._categories, 'security': true},
              marketingConsent: _marketing,
              quietHoursEnabled: _quiet,
              quietHoursStart: _start,
              quietHoursEnd: _end,
              timezone: _timezone.text.trim()));
      if (!mounted) return;
      setState(() => _value = saved);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification settings saved.')));
    } catch (error) {
      if (mounted) {
        setState(() => _error = error is ApiException
            ? error.message
            : 'Unable to save settings. Please retry.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _enablePush() async {
    setState(() => _enabling = true);
    try {
      final enabled = await getIt<NotificationService>().enablePush();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(enabled
              ? 'Push notifications enabled.'
              : 'Push could not be enabled. Check notification permission in your device settings and try again.')));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Unable to enable push notifications. Please retry.')));
      }
    } finally {
      if (mounted) setState(() => _enabling = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Notification settings')),
      body: _value == null
          ? Center(
              child: _error == null
                  ? const CircularProgressIndicator()
                  : Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(_error!),
                      TextButton(onPressed: _load, child: const Text('Retry'))
                    ]))
          : ListView(padding: const EdgeInsets.all(16), children: [
              const Text(
                  'Required account, security, and service messages remain enabled.'),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                  onPressed:
                      _enabling || !getIt<NotificationService>().pushAvailable
                          ? null
                          : _enablePush,
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: Text(
                      _enabling ? 'Enabling…' : 'Enable device notifications')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                  value: _locale,
                  decoration:
                      const InputDecoration(labelText: 'Notification language'),
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'hi', child: Text('Hindi'))
                  ],
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _locale = value ?? 'en')),
              ...notificationCategoryLabels.entries.map((entry) =>
                  SwitchListTile(
                      title: Text(entry.value),
                      value: entry.key == 'security' ||
                          (_categories[entry.key] ?? true),
                      subtitle: entry.key == 'security'
                          ? const Text('Always enabled')
                          : null,
                      onChanged: _saving || entry.key == 'security'
                          ? null
                          : (value) =>
                              setState(() => _categories[entry.key] = value))),
              SwitchListTile(
                  title: const Text('Marketing consent'),
                  subtitle:
                      const Text('Allow promotional offers and announcements.'),
                  value: _marketing,
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _marketing = value)),
              SwitchListTile(
                  title: const Text('Quiet hours'),
                  subtitle: const Text(
                      'Delay optional notifications during these hours.'),
                  value: _quiet,
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _quiet = value)),
              ListTile(
                  title: const Text('Start time'),
                  trailing: Text(_start),
                  onTap: _saving ? null : () => _pickTime(true)),
              ListTile(
                  title: const Text('End time'),
                  trailing: Text(_end),
                  onTap: _saving ? null : () => _pickTime(false)),
              TextField(
                  controller: _timezone,
                  enabled: !_saving,
                  decoration: const InputDecoration(
                      labelText: 'Timezone', hintText: 'Asia/Kolkata')),
              if (_error != null)
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(_error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error))),
              const SizedBox(height: 20),
              FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Saving…' : 'Save settings')),
            ]));
}
