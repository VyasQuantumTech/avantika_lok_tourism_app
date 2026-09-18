import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../domain/entities/pooja_entities.dart';
import '../../domain/usecases/pooja_actions.dart';

class CustomerPoojaBookingPage extends StatefulWidget {
  const CustomerPoojaBookingPage({required this.pooja, required this.offering, super.key});
  final Pooja pooja;
  final PoojaOffering offering;

  @override
  State<CustomerPoojaBookingPage> createState() => _CustomerPoojaBookingPageState();
}

class _CustomerPoojaBookingPageState extends State<CustomerPoojaBookingPage> {
  DateTime? _date;
  TimeOfDay? _time;
  int _participants = 1;
  final TextEditingController _notes = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  String _dateValue(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  String _timeValue(TimeOfDay value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  String get _money {
    final code = widget.offering.currency.trim().toUpperCase();
    final prefix = code == 'INR' ? '₹' : '$code ';
    return '$prefix${widget.offering.priceAmount.toStringAsFixed(0)}';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 1),
      initialDate: _date ?? now,
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null && mounted) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    if (_date == null || _time == null) {
      AppFeedback.error(context, 'Select service date and start time.');
      return;
    }
    setState(() => _saving = true);
    try {
      final booking = await getIt<CustomerPoojaActions>().book(
        offeringId: widget.offering.id,
        serviceDate: _dateValue(_date!),
        startTime: _timeValue(_time!),
        participants: _participants,
        notes: _notes.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(RouteNames.poojaPayment, arguments: booking);
    } on ApiException catch (error) {
      if (mounted) AppFeedback.error(context, error.message);
    } catch (_) {
      if (mounted) AppFeedback.error(context, 'Unable to create this booking right now.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Book Pooja',
      subtitle: 'Confirm service details before booking',
      child: ListView(
        children: [
          AppPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(13)),
                      child: Icon(Icons.temple_hindu_outlined, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.pooja.name, style: AppTypography.sectionTitle),
                          Text('Pandit ${widget.offering.panditName}', style: AppTypography.caption),
                        ],
                      ),
                    ),
                    Text(_money, style: AppTypography.title.copyWith(color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppStatusChip(label: widget.offering.serviceMode),
                    if (widget.offering.durationMinutes != null)
                      AppStatusChip(label: '${widget.offering.durationMinutes} min'),
                    if (widget.offering.city?.trim().isNotEmpty == true)
                      AppStatusChip(label: widget.offering.city!),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const AppSectionTitle(title: 'Schedule', subtitle: 'Choose when you want the Pooja to begin'),
          const SizedBox(height: 10),
          AppPanel(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.calendar_today_outlined, color: AppColors.primary),
                  title: Text(_date == null ? 'Select service date' : _dateValue(_date!), style: AppTypography.label),
                  subtitle: Text('Required', style: AppTypography.caption),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _pickDate,
                ),
                Divider(height: 1, color: AppColors.divider),
                ListTile(
                  leading: Icon(Icons.schedule_outlined, color: AppColors.primary),
                  title: Text(_time == null ? 'Select start time' : _timeValue(_time!), style: AppTypography.label),
                  subtitle: Text('Required', style: AppTypography.caption),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _pickTime,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const AppSectionTitle(title: 'Participants'),
          const SizedBox(height: 10),
          AppPanel(
            child: Row(
              children: [
                Expanded(child: Text('Number of participants', style: AppTypography.label)),
                IconButton(
                  onPressed: _participants > 1 ? () => setState(() => _participants--) : null,
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                ),
                Container(
                  width: 46,
                  alignment: Alignment.center,
                  child: Text('$_participants', style: AppTypography.title),
                ),
                IconButton(
                  onPressed: _participants < 100 ? () => setState(() => _participants++) : null,
                  icon: const Icon(Icons.add_circle_outline_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const AppSectionTitle(title: 'Notes', subtitle: 'Optional instructions for the Pandit'),
          const SizedBox(height: 10),
          TextField(
            controller: _notes,
            minLines: 3,
            maxLines: 5,
            maxLength: 500,
            decoration: const InputDecoration(hintText: 'Any special requirement, Sankalp details or instructions…'),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.infoSoft, borderRadius: BorderRadius.circular(14)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.info, size: 20),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Your profile must include name, date of birth, birth time and place of birth if required by the booking validation.',
                    style: AppTypography.caption,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check_circle_outline_rounded),
              label: Text(_saving ? 'Creating booking…' : 'Confirm Booking'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
