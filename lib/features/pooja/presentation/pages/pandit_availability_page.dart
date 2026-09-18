import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/widgets/app_ui.dart';
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
  bool _saving = false;

  static const _days = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _future = getIt<PanditPoojaActions>().dashboard();

  String _time(TimeOfDay value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  Future<void> _pick({required bool start}) async {
    final current = start ? _start : _end;
    final value = await showTimePicker(context: context, initialTime: current);
    if (value == null) return;
    setState(() => start ? _start = value : _end = value);
  }

  Future<void> _add() async {
    final startMinutes = _start.hour * 60 + _start.minute;
    final endMinutes = _end.hour * 60 + _end.minute;
    if (endMinutes <= startMinutes) {
      AppFeedback.error(context, 'End time must be later than start time.');
      return;
    }
    setState(() => _saving = true);
    try {
      await getIt<PanditPoojaActions>().addAvailability(
        weekday: _weekday,
        startTime: _time(_start),
        endTime: _time(_end),
      );
      if (!mounted) return;
      AppFeedback.success(context, 'Availability rule added.');
      setState(_reload);
    } on ApiException catch (error) {
      if (mounted) AppFeedback.error(context, error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(PanditAvailability rule) async {
    final confirmed = await AppDialogs.confirm(
      context,
      title: 'Remove availability?',
      message: 'Remove ${_days[rule.weekday]} ${rule.startTime}–${rule.endTime} from your weekly schedule?',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await getIt<PanditPoojaActions>().deleteAvailability(rule.id);
      if (!mounted) return;
      AppFeedback.success(context, 'Availability rule removed.');
      setState(_reload);
    } on ApiException catch (error) {
      if (mounted) AppFeedback.error(context, error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Availability',
      subtitle: 'Set the weekly slots customers can book',
      child: FutureBuilder<PanditPoojaDashboard>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingView(message: 'Loading availability…');
          }
          if (snapshot.hasError) {
            return AppErrorState(
              message: snapshot.error is ApiException
                  ? (snapshot.error! as ApiException).message
                  : 'Unable to load availability.',
              onRetry: () => setState(_reload),
            );
          }
          final rules = snapshot.data?.availability ?? const <PanditAvailability>[];
          final sorted = [...rules]
            ..sort((a, b) {
              final day = a.weekday.compareTo(b.weekday);
              return day != 0 ? day : a.startTime.compareTo(b.startTime);
            });
          return RefreshIndicator(
            onRefresh: () async {
              setState(_reload);
              await _future;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                AppPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppSectionTitle(
                        title: 'Add weekly slot',
                        subtitle: 'Create a repeatable availability window',
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: _weekday,
                        decoration: const InputDecoration(labelText: 'Weekday'),
                        items: List.generate(
                          7,
                          (i) => DropdownMenuItem(value: i, child: Text(_days[i])),
                        ),
                        onChanged: (value) => setState(() => _weekday = value ?? 1),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _TimeBox(
                              label: 'Start time',
                              value: _time(_start),
                              onTap: () => _pick(start: true),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _TimeBox(
                              label: 'End time',
                              value: _time(_end),
                              onTap: () => _pick(start: false),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _add,
                          icon: _saving
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.add_rounded),
                          label: const Text('Add availability'),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppDimensions.sectionGap),
                AppSectionTitle(
                  title: 'Current weekly rules',
                  subtitle: '${rules.length} active schedule ${rules.length == 1 ? 'rule' : 'rules'}',
                ),
                const SizedBox(height: 10),
                if (sorted.isEmpty)
                  const AppEmptyState(
                    title: 'No availability rules',
                    message: 'Add at least one weekly slot to define when customers can book you.',
                    icon: Icons.calendar_month_outlined,
                  )
                else
                  ...sorted.map(
                    (rule) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AppPanel(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.schedule_rounded, color: AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_days[rule.weekday], style: AppTypography.label),
                                  const SizedBox(height: 3),
                                  Text('${rule.startTime} – ${rule.endTime} • ${rule.timezone}', style: AppTypography.caption),
                                ],
                              ),
                            ),
                            AppStatusChip(label: rule.isActive ? 'active' : 'inactive'),
                            IconButton(
                              tooltip: 'Remove rule',
                              onPressed: () => _delete(rule),
                              icon: Icon(Icons.delete_outline_rounded, color: AppColors.error),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  const _TimeBox({required this.label, required this.value, required this.onTap});

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.smallRadius),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: AppColors.softSurface,
          borderRadius: BorderRadius.circular(AppDimensions.smallRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.caption),
            const SizedBox(height: 5),
            Row(
              children: [
                Icon(Icons.schedule_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(value, style: AppTypography.label),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
