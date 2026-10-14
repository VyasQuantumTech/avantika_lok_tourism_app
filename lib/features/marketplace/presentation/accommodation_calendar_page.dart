import 'package:flutter/material.dart';
import '../../../app/di/injection.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/widgets/app_ui.dart';
import '../domain/usecases/marketplace_actions.dart';

class ProviderAccommodationCalendarPage extends StatefulWidget {
  const ProviderAccommodationCalendarPage(
      {required this.unitId,
      required this.unitName,
      required this.onEdit,
      super.key});
  final String unitId;
  final String unitName;
  final Future<void> Function(Map<String, dynamic> row) onEdit;
  @override
  State<ProviderAccommodationCalendarPage> createState() => _CalendarState();
}

class _CalendarState extends State<ProviderAccommodationCalendarPage> {
  late DateTime start;
  late DateTime end;
  late Future<dynamic> future;
  @override
  void initState() {
    super.initState();
    start = DateUtils.dateOnly(DateTime.now());
    end = start.add(const Duration(days: 30));
    load();
  }

  String iso(DateTime date) => date.toIso8601String().substring(0, 10);
  void load() { future = getIt<MarketplaceActions>().providerCall('inventoryCalendar',
          id: widget.unitId,
          body: {'startDate': iso(start), 'endDate': iso(end)}); }
  Future<void> dates() async {
    final range = await showDateRangePicker(
        context: context,
        firstDate: DateTime.now().subtract(const Duration(days: 365)),
        lastDate: DateTime.now().add(const Duration(days: 730)),
        initialDateRange: DateTimeRange(start: start, end: end));
    if (range != null && mounted) {
      setState(() {
        start = range.start;
        end = range.end;
        load();
      });
    }
  }

  @override
  Widget build(BuildContext context) => AppPage(
      title: 'Room inventory',
      subtitle: widget.unitName,
      actions: [
        IconButton(
            tooltip: 'Select date range',
            onPressed: dates,
            icon: const Icon(Icons.date_range))
      ],
      child: FutureBuilder<dynamic>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AppLoadingView();
            }
            if (snapshot.hasError || snapshot.data is! Map) {
              return AppErrorState(
                  message: snapshot.error is ApiException
                      ? (snapshot.error as ApiException).message
                      : 'Unable to load inventory calendar.',
                  onRetry: () => setState(load));
            }
            final values = (snapshot.data as Map)['items'];
            final rows = values is List
                ? values
                    .whereType<Map>()
                    .map((row) => Map<String, dynamic>.from(row))
                    .toList()
                : <Map<String, dynamic>>[];
            return RefreshIndicator(
                onRefresh: () async {
                  setState(load);
                  await future;
                },
                child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Text('${iso(start)} – ${iso(end)}'),
                      const SizedBox(height: 12),
                      const Text(
                          'Availability includes existing reservations. Changes are checked against reserved capacity when saved.'),
                      const SizedBox(height: 12),
                      for (final row in rows)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: AppPanel(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text('${row['date']}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium),
                                  Text(
                                      '${row['availableInventory']} available • ${row['reservedInventory']} reserved • ${row['totalInventory']} total'),
                                  Text(row['isClosed'] == true
                                      ? 'Closed'
                                      : 'Open'),
                                  Text(
                                      'Stay: minimum ${row['minimumStayNights'] ?? 1} nights${row['maximumStayNights'] == null ? '' : ', maximum ${row['maximumStayNights']} nights'}'),
                                  TextButton.icon(
                                      onPressed: () async {
                                        await widget.onEdit(row);
                                        if (mounted) setState(load);
                                      },
                                      icon: const Icon(Icons.edit_outlined),
                                      label: const Text('Edit day')),
                                ]))),
                    ]));
          }));
}
