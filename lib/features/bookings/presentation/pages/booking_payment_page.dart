import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../domain/entities/booking_payment_session.dart';
import '../../domain/entities/booking_lifecycle.dart';
import '../../domain/usecases/booking_actions.dart';

class BookingPaymentPage extends StatefulWidget {
  const BookingPaymentPage({required this.bookingId, super.key});
  final String bookingId;
  @override
  State<BookingPaymentPage> createState() => _BookingPaymentPageState();
}

class _BookingPaymentPageState extends State<BookingPaymentPage> {
  late final Razorpay gateway;
  late Future<BookingLifecycle> future;
  BookingPaymentSession? session;
  PaymentSuccessResponse? receipt;
  bool busy = false;
  String? error;

  @override
  void initState() {
    super.initState();
    future = getIt<BookingActions>().lifecycle(widget.bookingId);
    gateway = Razorpay()
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _success)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _failure)
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, _wallet);
  }

  void _reload() { future = getIt<BookingActions>().lifecycle(widget.bookingId); }

  @override
  void dispose() {
    gateway.clear();
    super.dispose();
  }

  Future<void> _pay() async {
    if (busy || receipt != null) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      // Repository rechecks current backend policy/state before creating an order.
      session = await getIt<BookingActions>().initiatePayment(widget.bookingId);
      if (!mounted) return;
      final checkout = session!;
      if (checkout.keyId.isEmpty ||
          checkout.orderId.isEmpty ||
          checkout.amountMinor <= 0) {
        throw const ApiException(
            'Payment checkout configuration is incomplete.');
      }
      gateway.open({
        'key': checkout.keyId,
        'order_id': checkout.orderId,
        'amount': checkout.amountMinor,
        'currency': checkout.currency,
        'name': 'Avantika Lok',
        'description': 'Service booking',
        'retry': {'enabled': true, 'max_count': 2}
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          error = _message(e);
        });
      }
    }
  }

  Future<void> _success(PaymentSuccessResponse response) async {
    receipt = response;
    if (!mounted) return;
    await _verify();
  }

  Future<void> _verify() async {
    if (session == null ||
        receipt?.orderId == null ||
        receipt?.paymentId == null ||
        receipt?.signature == null) {
      if (mounted) {
        setState(() {
          busy = false;
          error =
              'Payment details are incomplete. Refresh the booking to check payment status.';
        });
      }
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await getIt<BookingActions>().verifyPayment(
          paymentId: session!.id,
          orderId: receipt!.orderId!,
          gatewayPaymentId: receipt!.paymentId!,
          signature: receipt!.signature!);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          error =
              '${_message(e)} Retry verification or refresh your booking before making another payment.';
        });
      }
    }
  }

  void _failure(PaymentFailureResponse response) {
    if (mounted) {
      setState(() {
        busy = false;
        error = response.message ?? 'Payment was not completed.';
      });
    }
  }

  void _wallet(ExternalWalletResponse response) {
    if (mounted) {
      setState(() {
        busy = false;
        error =
            'Continue in ${response.walletName ?? 'your wallet'}, then refresh the booking to check payment status.';
      });
    }
  }

  String _message(Object e) => e is ApiException
      ? e.message
      : 'Unable to complete payment verification.';

  @override
  Widget build(BuildContext context) => AppPage(
      title: 'Booking payment',
      child: FutureBuilder<BookingLifecycle>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AppLoadingView();
            }
            if (snapshot.hasError || snapshot.data == null) {
              return AppErrorState(
                  message: _message(snapshot.error ??
                      const ApiException('Booking unavailable.')),
                  onRetry: () => setState(_reload));
            }
            final state = snapshot.data!;
            return ListView(children: [
              AppPanel(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(state.serviceName ?? 'Service booking',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    Text(state.paymentMessage),
                    const SizedBox(height: 8),
                    Text(
                        'Payment status: ${state.paymentStatus.replaceAll('_', ' ')}'),
                    if (state.holdExpiresAt != null)
                      Text(
                          'Reservation held until ${state.holdExpiresAt!.toLocal()}'),
                    if (session != null)
                      Text(
                          'Checkout total: ${session!.currency} ${session!.amount.toStringAsFixed(2)}'),
                  ])),
              if (error != null)
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(error!)),
              const SizedBox(height: 12),
              if (receipt != null)
                FilledButton(
                    onPressed: busy ? null : _verify,
                    child: Text(
                        busy ? 'Verifying…' : 'Retry payment verification'))
              else if (state.canPay)
                FilledButton(
                    onPressed: busy ? null : _pay,
                    child: Text(busy
                        ? 'Checkout in progress…'
                        : 'Pay securely with Razorpay')),
              TextButton(
                  onPressed: busy
                      ? null
                      : () => setState(_reload),
                  child: const Text('Refresh payment status')),
              OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back to booking')),
            ]);
          }));
}
