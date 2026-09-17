import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/pooja_entities.dart';
import '../../domain/usecases/pooja_actions.dart';

class CustomerPoojaBookingsPage extends StatefulWidget {
  const CustomerPoojaBookingsPage({super.key});

  @override
  State<CustomerPoojaBookingsPage> createState() =>
      _CustomerPoojaBookingsPageState();
}

class _CustomerPoojaBookingsPageState
    extends State<CustomerPoojaBookingsPage> {
  late Future<List<PoojaBooking>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = getIt<CustomerPoojaActions>().bookings();
  }

  Future<void> _withdraw(PoojaBooking booking) async {
    try {
      await getIt<CustomerPoojaActions>().withdraw(booking.id);
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
            child: const Text('Keep Booking'),
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
    try {
      await getIt<CustomerPoojaActions>().cancel(booking.id, reason);
      if (!mounted) return;
      setState(_reload);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _review(PoojaBooking booking) async {
    int rating = 5;
    final title = TextEditingController();
    final comment = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Review this Pooja'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final value = index + 1;
                    return IconButton(
                      onPressed: () => setDialogState(() => rating = value),
                      icon: Icon(value <= rating ? Icons.star : Icons.star_border),
                    );
                  }),
                ),
                TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Title (optional)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: comment,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Your review',
                    hintText: 'Tell us about your Pooja experience',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (comment.text.trim().length < 5) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please write at least 5 characters.')));
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Submit Review'),
            ),
          ],
        ),
      ),
    );
    if (submitted != true) { title.dispose(); comment.dispose(); return; }
    try {
      await getIt<CustomerPoojaActions>().review(
        bookingId: booking.id, rating: rating, comment: comment.text, title: title.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review submitted for approval.')));
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      title.dispose(); comment.dispose();
    }
  }

  String _poojaName(PoojaBooking booking) =>
      booking.pricingSnapshot['poojaName']?.toString() ??
      booking.pricingSnapshot['name']?.toString() ??
      'Pooja';

  String _panditName(PoojaBooking booking) =>
      booking.pricingSnapshot['panditName']?.toString() ??
      booking.pricingSnapshot['providerName']?.toString() ??
      'Pandit';

  String _statusText(PoojaBooking booking) {
    if (booking.isCompleted) return 'Completed';
    if (booking.isInProgress) return 'Pooja in progress';
    if (booking.providerDecision == 'rejected') return 'Rejected by Pandit';
    if (booking.status == 'cancelled') return 'Cancelled';
    if (booking.isAwaitingPandit) return 'Waiting for Pandit confirmation';
    if (booking.providerDecision == 'accepted') return 'Confirmed';
    return booking.status;
  }

  Color _statusColor(PoojaBooking booking) {
    if (booking.isCompleted) return AppColors.success;
    if (booking.isInProgress) return AppColors.info;
    if (booking.status == 'cancelled' || booking.providerDecision == 'rejected') {
      return AppColors.error;
    }
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Pooja Bookings'),
        actions: [
          IconButton(
            tooltip: 'Browse Poojas',
            onPressed: () => Navigator.of(context).pushNamed(RouteNames.poojas),
            icon: const Icon(Icons.temple_hindu_outlined),
          ),
        ],
      ),
      body: FutureBuilder<List<PoojaBooking>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _BookingsMessage(
              icon: Icons.error_outline,
              message: snapshot.error is ApiException
                  ? (snapshot.error! as ApiException).message
                  : 'Unable to load Pooja bookings.',
              actionText: 'Retry',
              onAction: () => setState(_reload),
            );
          }

          final bookings = snapshot.data ?? const <PoojaBooking>[];
          if (bookings.isEmpty) {
            return _BookingsMessage(
              icon: Icons.temple_hindu_outlined,
              message: 'You have not booked a Pooja yet.',
              actionText: 'Browse Poojas',
              onAction: () => Navigator.of(context).pushNamed(RouteNames.poojas),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(_reload);
              await _future;
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final booking = bookings[index];
                final statusColor = _statusColor(booking);
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: AppColors.brandSoft,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.temple_hindu_outlined,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _poojaName(booking),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text('Pandit: ${_panditName(booking)}'),
                                ],
                              ),
                            ),
                            Text(
                              '₹${booking.totalAmount.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${booking.bookingNumber} • ${booking.serviceDate} ${booking.startTime?.substring(0, 5) ?? ''}',
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _statusText(booking),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (booking.hasCustomerOtpAccess) ...[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.brandSoft,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.18),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pooja verification OTPs',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  booking.isAwaitingPandit
                                      ? 'Both OTPs are generated for this booking. The Pandit must accept the booking before the Start OTP can be used.'
                                      : booking.isInProgress
                                          ? 'Pooja has started. Give the End OTP to the Pandit only after the Pooja is fully completed.'
                                          : 'Give the Start OTP only when the Pooja is ready to begin. Keep the End OTP private until the Pooja is fully completed.',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _InlineOtp(
                                        label: 'START POOJA OTP',
                                        otp: booking.poojaStartOtp,
                                        icon: Icons.play_circle_outline,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _InlineOtp(
                                        label: 'END POOJA OTP',
                                        otp: booking.poojaEndOtp,
                                        icon: Icons.stop_circle_outlined,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (booking.isAwaitingPandit)
                              TextButton(
                                onPressed: () => _withdraw(booking),
                                child: const Text('Withdraw'),
                              ),
                            if (booking.canCustomerCancel &&
                                booking.serviceStartedAt == null)
                              TextButton(
                                onPressed: () => _cancel(booking),
                                child: const Text('Cancel'),
                              ),
                            if (booking.isCompleted)
                              FilledButton.tonalIcon(
                                onPressed: () => _review(booking),
                                icon: const Icon(Icons.star_outline),
                                label: const Text('Write Review'),
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

class _InlineOtp extends StatelessWidget {
  const _InlineOtp({
    required this.label,
    required this.otp,
    required this.icon,
  });

  final String label;
  final String? otp;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final value = otp?.trim();
    final available = value != null && value.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          SelectableText(
            available ? value : '------',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.5,
              color: available ? null : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingsMessage extends StatelessWidget {
  const _BookingsMessage({
    required this.icon,
    required this.message,
    required this.actionText,
    required this.onAction,
  });

  final IconData icon;
  final String message;
  final String actionText;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(actionText)),
          ],
        ),
      ),
    );
  }
}
