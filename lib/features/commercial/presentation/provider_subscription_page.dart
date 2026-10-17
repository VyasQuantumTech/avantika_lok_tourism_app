import 'dart:math';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../app/di/injection.dart';
import '../../../core/widgets/app_ui.dart';
import '../domain/commercial_repository.dart';
import 'price_breakdown.dart';

class ProviderSubscriptionPage extends StatefulWidget {
  const ProviderSubscriptionPage({super.key});
  @override
  State<ProviderSubscriptionPage> createState() =>
      _ProviderSubscriptionPageState();
}

class _ProviderSubscriptionPageState extends State<ProviderSubscriptionPage> {
  late final Razorpay gateway;
  late Future<List<Map<String, dynamic>>> future;
  Map<String, dynamic>? payment;
  PaymentSuccessResponse? receipt;
  String? error;
  bool busy = false;
  bool mandateCheckout = false;
  final keys = <String, String>{};
  final random = Random.secure();
  CommercialActions get actions => getIt<CommercialActions>();
  @override
  void initState() {
    super.initState();
    reload();
    gateway = Razorpay()
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse r) {
        if (mandateCheckout) {
          if (mounted) {
            setState(() {
              busy = false;
              mandateCheckout = false;
              error =
                  'Authorization received. Refresh after the gateway confirms your mandate.';
              reload();
            });
          }
        } else {
          receipt = r;
          verify();
        }
      })
      ..on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse r) {
        if (mounted) {
          setState(() {
            busy = false;
            error = r.message ?? 'Payment failed. Refresh before retrying.';
          });
        }
      })
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse r) {
        if (mounted) {
          setState(() {
            busy = false;
            error =
                'Continue in your wallet, then refresh subscription status.';
          });
        }
      });
  }

  void reload() {
    future = Future.wait([actions.plans(), actions.subscription()]);
  }

  @override
  void dispose() {
    gateway.clear();
    super.dispose();
  }

  Future<void> verify() async {
    if (payment == null ||
        receipt?.orderId == null ||
        receipt?.paymentId == null ||
        receipt?.signature == null) {
      return;
    }
    setState(() => busy = true);
    try {
      await actions.verify('${payment!['id']}', {
        'razorpayOrderId': receipt!.orderId,
        'razorpayPaymentId': receipt!.paymentId,
        'razorpaySignature': receipt!.signature
      });
      if (mounted) {
        setState(() {
          busy = false;
          error =
              'Payment verified. Subscription activates after gateway capture. Refresh to check status.';
          receipt = null;
          reload();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          error = commercialError(e);
        });
      }
    }
  }

  Future<void> purchase(Map<String, dynamic> plan,
      {bool renewal = false, bool trial = false}) async {
    if (busy) return;
    final c = commercialMap(plan['config']);
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: Text('${plan['name']}'),
                content: Text(renewal
                    ? 'Change to this plan at the next renewal?'
                    : '${commercialMoney(c['priceMinor'], c['currency'])} per billing cycle. Applicable tax and proration will be shown at checkout.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Back')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Continue'))
                ]));
    if (confirmed != true || !mounted) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final id = '${plan['id']}';
      final key = keys.putIfAbsent(
          '$id:$renewal:$trial',
          () =>
              'sub-${DateTime.now().microsecondsSinceEpoch}-${random.nextInt(1 << 30)}');
      final result =
          await actions.checkout(id, key, renewal: renewal, trial: trial);
      if (!mounted) return;
      payment =
          result['payment'] is Map ? commercialMap(result['payment']) : null;
      if (payment == null) {
        setState(() {
          busy = false;
          reload();
        });
        return;
      }
      final checkout = commercialMap(payment!['checkout']);
      if ('${checkout['keyId'] ?? ''}'.isEmpty ||
          '${checkout['orderId'] ?? ''}'.isEmpty) {
        throw StateError('Checkout unavailable');
      }
      final continuePayment = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                  title: const Text('Subscription payment'),
                  content: SingleChildScrollView(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                    if (commercialMap(payment!['metadata'])['price'] is Map)
                      PriceBreakdown(
                          snapshot: commercialMap(
                              commercialMap(payment!['metadata'])['price'])),
                    if ((num.tryParse(
                                '${commercialMap(payment!['metadata'])['appliedCreditMinor']}') ??
                            0) >
                        0)
                      Text(
                          'Subscription credit applied: ${commercialMoney(commercialMap(payment!['metadata'])['appliedCreditMinor'], checkout['currency'])}'),
                    Text(
                        'Amount due: ${commercialMoney(checkout['amountMinor'], checkout['currency'])}. Your current plan stays active until this payment is captured.')
                  ])),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Back')),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Pay securely'))
                  ]));
      if (continuePayment != true) {
        if (mounted) setState(() => busy = false);
        return;
      }
      gateway.open({
        'key': checkout['keyId'],
        'order_id': checkout['orderId'],
        'amount': checkout['amountMinor'],
        'currency': checkout['currency'],
        'name': 'Avantika Lok',
        'description': 'Provider subscription'
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          error = commercialError(e);
        });
      }
    }
  }

  Future<void> enableRenewal(Map<String, dynamic> current) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final result = await actions.enableRenewal('${current['id']}',
          'renew-${DateTime.now().microsecondsSinceEpoch}-${random.nextInt(1 << 30)}');
      if (!mounted) return;
      final checkout = commercialMap(result['checkout']);
      mandateCheckout = true;
      payment = null;
      gateway.open({
        'key': checkout['keyId'],
        'subscription_id': checkout['subscriptionId'],
        'name': 'Avantika Lok',
        'description': 'Authorize automatic subscription renewal'
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          error = commercialError(e);
        });
      }
    }
  }

  Future<void> cancel(Map<String, dynamic> current) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Cancel renewal'),
                content: TextField(
                    controller: controller,
                    decoration: const InputDecoration(labelText: 'Reason')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Keep renewal')),
                  FilledButton(
                      onPressed: () {
                        if (controller.text.trim().length >= 3) {
                          Navigator.pop(context, controller.text.trim());
                        }
                      },
                      child: const Text('Cancel renewal'))
                ]));
    controller.dispose();
    if (reason == null || !mounted) return;
    setState(() => busy = true);
    try {
      await actions.cancel('${current['id']}', reason);
      if (mounted) setState(reload);
    } catch (e) {
      if (mounted) setState(() => error = commercialError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AppPage(
      title: 'Plans & subscription',
      subtitle: 'Manage provider benefits and usage',
      child: FutureBuilder<List<Map<String, dynamic>>>(
          future: future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return snapshot.hasError
                  ? AppErrorState(
                      message: commercialError(snapshot.error!),
                      onRetry: () => setState(reload))
                  : const AppLoadingView(message: 'Loading plans…');
            }
            final plans = snapshot.data![0]['items'] as List? ?? [];
            final state = snapshot.data![1],
                current = commercialMap(state['current']);
            final usage = state['usage'] as List? ?? [];
            return RefreshIndicator(
                onRefresh: () async {
                  setState(reload);
                  await future;
                },
                child: ListView(children: [
                  if (error != null) AppPanel(child: Text(error!)),
                  if (receipt != null)
                    TextButton(
                        onPressed: busy ? null : verify,
                        child: const Text('Retry payment verification')),
                  if (current.isNotEmpty)
                    AppPanel(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(
                              '${commercialMap(commercialMap(current['terms'])['plan'])['name']}',
                              style: Theme.of(context).textTheme.titleLarge),
                          Text('Status: ${current['state']}'),
                          Text(
                              'Access until: ${DateTime.tryParse('${current['endsAt']}')?.toLocal()}'),
                          Text(
                              'Renewal: ${current['autoRenew'] == true ? 'enabled' : 'disabled'}'),
                          if (current['autoRenew'] != true)
                            TextButton(
                                onPressed:
                                    busy ? null : () => enableRenewal(current),
                                child:
                                    const Text('Authorize automatic renewal')),
                          if (current['autoRenew'] == true)
                            TextButton(
                                onPressed: busy ? null : () => cancel(current),
                                child: const Text('Cancel renewal')),
                          const Divider(),
                          const Text('Usage'),
                          for (final raw in usage.take(20))
                            Text(
                                '${commercialMap(raw)['feature']}: ${commercialMap(raw)['quantity']} · ${commercialMap(raw)['period']}')
                        ]))
                  else
                    const AppPanel(
                        child:
                            Text('Choose a plan to unlock provider features.')),
                  for (final raw in plans) ...[
                    const SizedBox(height: 12),
                    Builder(builder: (context) {
                      final plan = commercialMap(raw),
                          c = commercialMap(plan['config']),
                          entitlements = commercialMap(c['entitlements']);
                      return AppPanel(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text('${plan['name']}',
                                style: Theme.of(context).textTheme.titleLarge),
                            Text(
                                '${commercialMoney(c['priceMinor'], c['currency'])} / ${c['cycleDays'] ?? c['cycleMonths']} ${c['cycleDays'] != null ? 'days' : 'months'}'),
                            if ((num.tryParse('${c['setupFeeMinor']}') ?? 0) >
                                0)
                              Text(
                                  'Joining fee: ${commercialMoney(c['setupFeeMinor'], c['currency'])}'),
                            for (final entry in entitlements.entries)
                              if (commercialMap(entry.value)['enabled'] == true)
                                Text(
                                    '✓ ${entry.key.replaceAll('_', ' ')} · ${commercialMap(entry.value)['quota'] ?? 'unlimited'} / ${commercialMap(entry.value)['period'] ?? 'cycle'}'),
                            if ((num.tryParse(
                                        '${c['commissionDiscountBps']}') ??
                                    0) >
                                0)
                              Text(
                                  'Commission discount: ${(num.tryParse('${c['commissionDiscountBps']}') ?? 0) / 100}%'),
                            Wrap(spacing: 8, children: [
                              FilledButton(
                                  onPressed: busy ? null : () => purchase(plan),
                                  child: const Text('Choose / renew')),
                              if (current.isNotEmpty)
                                TextButton(
                                    onPressed: busy
                                        ? null
                                        : () => purchase(plan, renewal: true),
                                    child: const Text('Change at renewal')),
                              if (current.isEmpty &&
                                  (num.tryParse('${c['trialDays']}') ?? 0) > 0)
                                TextButton(
                                    onPressed: busy
                                        ? null
                                        : () => purchase(plan, trial: true),
                                    child: const Text('Start trial'))
                            ])
                          ]));
                    })
                  ],
                  const SizedBox(height: 24),
                  OutlinedButton(
                      onPressed: busy ? null : () => setState(reload),
                      child: const Text('Refresh subscription status'))
                ]));
          }));
}
