import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/pooja_entities.dart';
import '../../domain/usecases/pooja_actions.dart';

class PanditPoojaBookingsPage extends StatefulWidget {
  const PanditPoojaBookingsPage({super.key});

  @override
  State<PanditPoojaBookingsPage> createState() => _PanditPoojaBookingsPageState();
}

class _PanditPoojaBookingsPageState extends State<PanditPoojaBookingsPage> {
  late Future<List<PoojaBooking>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _future = getIt<PanditPoojaActions>().bookings();

  Future<void> _action(Future<PoojaBooking> future) async {
    try {
      await future;
      if (!mounted) return;
      setState(_reload);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _cancel(PoojaBooking booking) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Pooja Booking'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Reason'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || reason.length < 2) return;
    await _action(getIt<PanditPoojaActions>().cancel(booking.id, reason));
  }

  Future<void> _start(PoojaBooking booking) async {
    final controller = TextEditingController();
    final otp = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enter Customer OTP'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(hintText: '6-digit OTP'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Start'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (otp?.length == 6) {
      await _action(getIt<PanditPoojaActions>().start(booking.id, otp!));
    }
  }

  Future<void> _end(PoojaBooking booking) async {
    final controller = TextEditingController();
    final otp = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enter End OTP'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(
            hintText: '6-digit customer End OTP',
            helperText: 'Ask the customer for this OTP only after the Pooja is finished.',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Complete Pooja')),
        ],
      ),
    );
    controller.dispose();
    if (otp?.length == 6) {
      await _action(getIt<PanditPoojaActions>().end(booking.id, otp!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pooja Orders')),
      body: FutureBuilder<List<PoojaBooking>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error is ApiException
                    ? (snapshot.error! as ApiException).message
                    : 'Unable to load bookings.',
              ),
            );
          }
          final bookings = snapshot.data ?? const <PoojaBooking>[];
          if (bookings.isEmpty) {
            return const Center(child: Text('No Pooja orders yet.'));
          }
          return RefreshIndicator(
            onRefresh: () async {
              setState(_reload);
              await _future;
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final booking = bookings[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.pricingSnapshot['poojaName']?.toString() ??
                              booking.bookingNumber,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${booking.serviceDate} ${booking.startTime?.substring(0, 5) ?? ''}',
                        ),
                        Text(
                          'Status: ${booking.status} • Decision: ${booking.providerDecision}',
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (booking.canPanditAccept) ...[
                              FilledButton(
                                onPressed: () => _action(
                                  getIt<PanditPoojaActions>().accept(booking.id),
                                ),
                                child: const Text('Accept'),
                              ),
                              OutlinedButton(
                                onPressed: () => _action(
                                  getIt<PanditPoojaActions>().reject(booking.id),
                                ),
                                child: const Text('Reject'),
                              ),
                            ],
                            if (booking.showPanditPoojaControls) ...[
                              FilledButton.tonal(
                                onPressed: booking.canPanditStart
                                    ? () => _start(booking)
                                    : null,
                                child: Text(
                                  booking.isInProgress
                                      ? 'Pooja Started'
                                      : 'Start Pooja',
                                ),
                              ),
                              FilledButton(
                                onPressed: booking.canPanditEnd
                                    ? () => _end(booking)
                                    : null,
                                child: const Text('End Pooja'),
                              ),
                            ],
                            if ((booking.status == 'pending' ||
                                    booking.status == 'confirmed') &&
                                booking.serviceStartedAt == null)
                              TextButton(
                                onPressed: () => _cancel(booking),
                                child: const Text('Cancel'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
