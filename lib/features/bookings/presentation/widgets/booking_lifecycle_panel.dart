import 'package:flutter/material.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../domain/entities/booking_lifecycle.dart';
import '../../domain/usecases/booking_actions.dart';
import '../pages/booking_payment_page.dart';

class BookingLifecyclePanel extends StatefulWidget {
  const BookingLifecyclePanel(
      {required this.bookingId,
      required this.lifecycle,
      required this.onRefresh,
      super.key});
  final String bookingId;
  final BookingLifecycle lifecycle;
  final Future<void> Function() onRefresh;
  @override
  State<BookingLifecyclePanel> createState() => _BookingLifecyclePanelState();
}

class _BookingLifecyclePanelState extends State<BookingLifecyclePanel> {
  bool busy = false;
  String? code;

  @override
  void didUpdateWidget(BookingLifecyclePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A refresh may consume a code or change its phase. Never retain it.
    code = null;
  }

  Future<void> _code() async {
    if (busy) return;
    setState(() {
      busy = true;
      code = null;
    });
    try {
      final value = await getIt<BookingActions>()
          .otp(widget.bookingId, end: widget.lifecycle.canFetchEndOtp);
      if (mounted) setState(() => code = value);
    } catch (error) {
      if (mounted) {
        AppFeedback.error(
            context,
            error is ApiException
                ? error.message
                : 'Unable to fetch verification code. Refresh and try again.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _pay() async {
    await Navigator.push<bool>(
        context,
        MaterialPageRoute(
            builder: (_) => BookingPaymentPage(bookingId: widget.bookingId)));
    if (mounted) await widget.onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.lifecycle;
    return AppPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AppDetailRow(
          label: 'Booking status',
          value: state.statusLabel,
          icon: Icons.receipt_long_outlined),
      AppDetailRow(
          label: 'Payment',
          value: state.paymentStatus.replaceAll('_', ' '),
          icon: Icons.payments_outlined),
      Text(state.paymentMessage),
      if (state.active &&
          state.status == 'pending' &&
          state.holdExpiresAt != null)
        Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
                'Reservation held until ${state.holdExpiresAt!.toLocal()}. Refresh to check the latest status.')),
      if (state.canPay)
        Padding(
            padding: const EdgeInsets.only(top: 10),
            child: FilledButton.icon(
                onPressed: busy ? null : _pay,
                icon: const Icon(Icons.lock_outline),
                label: const Text('Complete payment'))),
      if (state.canFetchStartOtp || state.canFetchEndOtp) ...[
        const Divider(),
        Text(state.canFetchEndOtp
            ? 'Share the completion code only after your service is complete.'
            : 'Share the start code only when your service is ready to begin.'),
        if (code != null)
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: SelectableText(code!,
                  style: Theme.of(context).textTheme.headlineMedium)),
        OutlinedButton.icon(
            onPressed: busy ? null : _code,
            icon: const Icon(Icons.password_outlined),
            label: Text(busy
                ? 'Fetching…'
                : state.canFetchEndOtp
                    ? 'Get completion code'
                    : 'Get start code')),
      ] else if (state.active && state.startedAt == null) ...[
        const SizedBox(height: 8),
        const Text(
            'Verification codes become available when your booking is confirmed. The completion code is available after service start.'),
      ],
      TextButton.icon(
          onPressed: busy ? null : widget.onRefresh,
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh booking')),
    ]));
  }
}
