import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/pooja_entities.dart';
import '../../domain/usecases/pooja_actions.dart';

class CustomerPoojaBookingPage extends StatefulWidget {
  const CustomerPoojaBookingPage({
    required this.pooja,
    required this.offering,
    super.key,
  });

  final Pooja pooja;
  final PoojaOffering offering;

  @override
  State<CustomerPoojaBookingPage> createState() => _CustomerPoojaBookingPageState();
}

class _CustomerPoojaBookingPageState extends State<CustomerPoojaBookingPage> {
  DateTime? _date;
  TimeOfDay? _time;
  int _participants = 1;
  final _notes = TextEditingController();
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

  Future<void> _submit() async {
    if (_date == null || _time == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select service date and start time.')),
      );
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
      Navigator.of(context).pushReplacementNamed(
        RouteNames.poojaPayment,
        arguments: booking,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Pooja')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.pooja.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text('Pandit: ${widget.offering.panditName}'),
          Text(
            '₹${widget.offering.priceAmount.toStringAsFixed(0)} • ${widget.offering.serviceMode}',
          ),
          const SizedBox(height: 20),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_outlined),
            title: Text(
              _date == null ? 'Select date' : _dateValue(_date!),
            ),
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime(now.year, now.month, now.day),
                lastDate: DateTime(now.year + 1),
                initialDate: _date ?? now,
              );
              if (picked != null) setState(() => _date = picked);
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule_outlined),
            title: Text(
              _time == null ? 'Select start time' : _timeValue(_time!),
            ),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _time ?? const TimeOfDay(hour: 9, minute: 0),
              );
              if (picked != null) setState(() => _time = picked);
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(child: Text('Participants')),
              IconButton(
                onPressed: _participants > 1
                    ? () => setState(() => _participants--)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('$_participants'),
              IconButton(
                onPressed: _participants < 100
                    ? () => setState(() => _participants++)
                    : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _saving ? null : _submit,
            child: Text(_saving ? 'Booking…' : 'Book Pooja'),
          ),
          const SizedBox(height: 12),
          const Text(
            'Your profile must contain name, date of birth, birth time and place of birth before the backend permits a Pooja booking.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
