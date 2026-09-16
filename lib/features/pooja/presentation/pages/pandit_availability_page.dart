import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/pooja_entities.dart';
import '../../domain/usecases/pooja_actions.dart';

class PanditAvailabilityPage extends StatefulWidget {
  const PanditAvailabilityPage({super.key});

  @override
  State<PanditAvailabilityPage> createState() => _PanditAvailabilityPageState();
}

class _PanditAvailabilityPageState extends State<PanditAvailabilityPage> {
  late Future<PanditPoojaDashboard> _future;
  int _weekday = 1;
  TimeOfDay _start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 18, minute: 0);

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _future = getIt<PanditPoojaActions>().dashboard();

  String _time(TimeOfDay value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  Future<void> _add() async {
    try {
      await getIt<PanditPoojaActions>().addAvailability(
        weekday: _weekday,
        startTime: _time(_start),
        endTime: _time(_end),
      );
      if (!mounted) return;
      setState(_reload);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    const days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Availability')),
      body: FutureBuilder<PanditPoojaDashboard>(
        future: _future,
        builder: (context, snapshot) {
          final rules = snapshot.data?.availability ?? const <PanditAvailability>[];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<int>(
                value: _weekday,
                decoration: const InputDecoration(labelText: 'Weekday'),
                items: List.generate(
                  7,
                  (i) => DropdownMenuItem(value: i, child: Text(days[i])),
                ),
                onChanged: (v) => setState(() => _weekday = v ?? 1),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Start: ${_time(_start)}'),
                onTap: () async {
                  final v = await showTimePicker(
                    context: context,
                    initialTime: _start,
                  );
                  if (v != null) setState(() => _start = v);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('End: ${_time(_end)}'),
                onTap: () async {
                  final v = await showTimePicker(
                    context: context,
                    initialTime: _end,
                  );
                  if (v != null) setState(() => _end = v);
                },
              ),
              FilledButton(onPressed: _add, child: const Text('Add Rule')),
              const SizedBox(height: 20),
              const Text(
                'Current weekly rules',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              ...rules.map(
                (rule) => Card(
                  child: ListTile(
                    title: Text(days[rule.weekday]),
                    subtitle: Text('${rule.startTime} - ${rule.endTime}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await getIt<PanditPoojaActions>()
                            .deleteAvailability(rule.id);
                        if (mounted) setState(_reload);
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
