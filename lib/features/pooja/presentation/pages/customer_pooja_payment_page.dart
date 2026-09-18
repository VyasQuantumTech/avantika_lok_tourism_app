import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/widgets/app_ui.dart';
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

  String _hex(Color color) =>
      '#${(color.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

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
        throw const ApiException('Payment checkout configuration is incomplete.', statusCode: 500, code: 'PAYMENT_CHECKOUT_INVALID');
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
        'theme': <String, dynamic>{'color': _hex(AppColors.primary)},
      });
    } on ApiException catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.message; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = 'Unable to start payment. Please try again.'; });
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
      if (mounted) setState(() { _loading = false; _error = e.message; });
    }
  }

  void _onFailure(PaymentFailureResponse response) {
    if (mounted) setState(() { _loading = false; _error = response.message ?? 'Payment was not completed.'; });
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    if (mounted) AppFeedback.info(context, 'Continue in ${response.walletName ?? 'the selected wallet'} to finish payment.');
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final poojaName = booking.pricingSnapshot['poojaName']?.toString() ?? 'Pooja';
    final code = booking.currency.toUpperCase();
    final amount = '${code == 'INR' ? '₹' : '$code '}${booking.totalAmount.toStringAsFixed(2)}';
    final time = booking.startTime;
    final shortTime = time == null || time.isEmpty ? '' : time.substring(0, time.length >= 5 ? 5 : time.length);

    return AppPage(
      title: 'Payment',
      subtitle: 'Booking ${booking.bookingNumber}',
      child: ListView(
        children: [
          AppPanel(
            child: Column(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
                  child: Icon(Icons.verified_user_outlined, color: AppColors.primary, size: 30),
                ),
                const SizedBox(height: 12),
                Text(poojaName, style: AppTypography.titleLarge, textAlign: TextAlign.center),
                const SizedBox(height: 5),
                Text('${booking.serviceDate}${shortTime.isEmpty ? '' : ' • $shortTime'}', style: AppTypography.caption),
                const SizedBox(height: 16),
                Divider(color: AppColors.divider),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Amount payable', style: AppTypography.label),
                    const Spacer(),
                    Text(amount, style: AppTypography.titleLarge.copyWith(color: AppColors.primary)),
                  ],
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.errorSoft, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: AppColors.error),
                  const SizedBox(width: 9),
                  Expanded(child: Text(_error!, style: AppTypography.caption.copyWith(color: AppColors.error))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _loading ? null : _pay,
              icon: _loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.lock_outline_rounded),
              label: Text(_loading ? 'Preparing payment…' : 'Pay securely with Razorpay'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _loading
                  ? null
                  : () => Navigator.of(context).pushReplacementNamed(RouteNames.customerPoojaBookings),
              icon: const Icon(Icons.schedule_rounded),
              label: const Text('Pay later / View booking'),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.infoSoft, borderRadius: BorderRadius.circular(14)),
            child: Text(
              'Payment is currently optional for the service-start flow. Your booking and its Start/End OTPs remain available in My Pooja Bookings according to the backend booking state.',
              textAlign: TextAlign.center,
              style: AppTypography.caption,
            ),
          ),
        ],
      ),
    );
  }
}
