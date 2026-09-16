import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/pooja_entities.dart';
import '../../domain/usecases/pooja_actions.dart';

class CustomerPoojaPaymentPage extends StatefulWidget {
  const CustomerPoojaPaymentPage({required this.booking, super.key});

  final PoojaBooking booking;

  @override
  State<CustomerPoojaPaymentPage> createState() => _CustomerPoojaPaymentPageState();
}

class _CustomerPoojaPaymentPageState extends State<CustomerPoojaPaymentPage> {
  late final Razorpay _razorpay;
  PoojaPaymentSession? _session;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onFailure);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _pay() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = await getIt<CustomerPoojaActions>().initiatePayment(widget.booking.id);
      if (!mounted) return;
      if (session.keyId.isEmpty || session.orderId.isEmpty || session.amountMinor <= 0) {
        throw const ApiException(
          'Payment checkout configuration is incomplete.',
          statusCode: 500,
          code: 'PAYMENT_CHECKOUT_INVALID',
        );
      }
      _session = session;
      setState(() => _loading = false);
      _razorpay.open(<String, dynamic>{
        'key': session.keyId,
        'order_id': session.orderId,
        'amount': session.amountMinor,
        'currency': session.currency,
        'name': 'Avantika Lok',
        'description': widget.booking.pricingSnapshot['poojaName']?.toString() ?? 'Pooja booking',
        'retry': <String, dynamic>{'enabled': true, 'max_count': 2},
        'theme': <String, dynamic>{'color': '#8B1E2D'},
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to start payment. Please try again.';
      });
    }
  }

  Future<void> _onSuccess(PaymentSuccessResponse response) async {
    final session = _session;
    if (session == null || response.orderId == null || response.paymentId == null || response.signature == null) {
      if (mounted) setState(() => _error = 'Payment succeeded but verification details are missing.');
      return;
    }
    setState(() => _loading = true);
    try {
      await getIt<CustomerPoojaActions>().verifyPayment(
        paymentId: session.id,
        razorpayOrderId: response.orderId!,
        razorpayPaymentId: response.paymentId!,
        razorpaySignature: response.signature!,
      );
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        RouteNames.customerPoojaBookings,
        (route) => route.settings.name == RouteNames.home,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  void _onFailure(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = response.message ?? 'Payment was not completed.';
    });
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Continue in ${response.walletName ?? 'the selected wallet'} to finish payment.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final poojaName = widget.booking.pricingSnapshot['poojaName']?.toString() ?? 'Pooja';
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.verified_user_outlined, size: 54),
          const SizedBox(height: 16),
          Text(poojaName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Booking ${widget.booking.bookingNumber}'),
          Text('${widget.booking.serviceDate} ${widget.booking.startTime?.substring(0, 5) ?? ''}'),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Expanded(child: Text('Amount payable', style: TextStyle(fontWeight: FontWeight.w700))),
                  Text('₹${widget.booking.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _loading ? null : _pay,
            icon: _loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.lock_outline),
            label: Text(_loading ? 'Preparing payment…' : 'Pay securely with Razorpay'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _loading ? null : () => Navigator.of(context).pushReplacementNamed(RouteNames.customerPoojaBookings),
            child: const Text('Pay later / View booking'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Your booking remains pending until payment is captured and the Pandit accepts it. Start OTP becomes available only after confirmation.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
