import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../app/di/injection.dart';
import '../../../core/widgets/app_ui.dart';
import '../domain/commercial_repository.dart';
import 'price_breakdown.dart';

class ProviderWorkspacePage extends StatefulWidget {
  const ProviderWorkspacePage({super.key});
  @override
  State<ProviderWorkspacePage> createState() => _ProviderWorkspacePageState();
}

class _ProviderWorkspacePageState extends State<ProviderWorkspacePage> {
  late Future<Map<String, dynamic>> future;
  late Razorpay gateway;
  bool busy = false;
  String? error;
  Map<String, dynamic>? payment;
  final intents = <String, String>{};
  final random = Random.secure();
  CommercialActions get actions => getIt<CommercialActions>();
  String requestKey() =>
      'workspace-${DateTime.now().microsecondsSinceEpoch}-${random.nextInt(1 << 30)}';
  @override
  void initState() {
    super.initState();
    reload();
    gateway = Razorpay()
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse r) async {
        try {
          if (payment != null) {
            await actions.verify('${payment!['id']}', {
              'razorpayOrderId': r.orderId,
              'razorpayPaymentId': r.paymentId,
              'razorpaySignature': r.signature
            });
          }
          if (mounted) {
            setState(() {
              busy = false;
              error =
                  'Payment verified. Visibility starts after gateway capture.';
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
      })
      ..on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse r) {
        if (mounted) {
          setState(() {
            busy = false;
            error = r.message;
          });
        }
      })
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse r) {
        if (mounted) setState(() => busy = false);
      });
  }

  void reload() {
    future = actions.tools();
  }

  @override
  void dispose() {
    gateway.clear();
    super.dispose();
  }

  Future<void> create(String kind) async {
    final labels = <String, List<String>>{
      'lead': ['name', 'contact', 'notes'],
      'staff': ['userId'],
      'campaign': ['title', 'creative', 'audience'],
      'branding': ['headline', 'description'],
      'api_key': ['label'],
      'support': ['subject', 'message'],
      'coupon': ['code', 'fixedMinor', 'budgetMinor', 'usageLimit']
    };
    final fields = {for (final k in labels[kind]!) k: TextEditingController()};
    final form = GlobalKey<FormState>();
    final input = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => AlertDialog(
                title: Text('Create ${kind.replaceAll('_', ' ')}'),
                content: SizedBox(
                    width: 400,
                    child: Form(
                        key: form,
                        child: SingleChildScrollView(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                              for (final f in fields.entries)
                                Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: TextFormField(
                                        controller: f.value,
                                        decoration:
                                            InputDecoration(labelText: f.key),
                                        validator: (v) =>
                                            (v?.trim().isEmpty ?? true)
                                                ? 'Required'
                                                : null))
                            ])))),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Back')),
                  FilledButton(
                      onPressed: () {
                        if (form.currentState!.validate()) {
                          Navigator.pop(context, {
                            for (final f in fields.entries)
                              f.key: f.value.text.trim()
                          });
                        }
                      },
                      child: const Text('Create'))
                ]));
    for (final c in fields.values) {
      c.dispose();
    }
    if (input == null || !mounted) return;
    setState(() => busy = true);
    try {
      Map<String, dynamic> result;
      if (kind == 'coupon') {
        result = await actions.coupon({
          'kind': 'coupon',
          'code': input['code'],
          'name': input['code'],
          'status': 'active',
          'effectiveFrom': DateTime.now().toUtc().toIso8601String(),
          'reason': 'Provider created promotion',
          'config': {
            'fixedMinor': int.parse(input['fixedMinor']),
            'budgetMinor': int.parse(input['budgetMinor']),
            'usageLimit': int.parse(input['usageLimit'])
          }
        });
      } else {
        if (kind == 'staff') {
          input['permissions'] = ['leads', 'basic_analytics'];
        }
        result = await actions.createTool(
            {'kind': kind, 'reference': requestKey(), 'payload': input});
      }
      if (!mounted) return;
      if (result['apiKey'] != null) {
        final key = '${result['apiKey']}';
        await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
                    title: const Text('Save integration key'),
                    content: SelectableText(key),
                    actions: [
                      TextButton(
                          onPressed: () =>
                              Clipboard.setData(ClipboardData(text: key)),
                          child: const Text('Copy')),
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Done'))
                    ]));
      }
      if (mounted) setState(reload);
    } catch (e) {
      if (mounted) setState(() => error = commercialError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> analytics(bool advanced) async {
    setState(() => busy = true);
    try {
      final data = await actions.analytics(advanced: advanced);
      if (!mounted) return;
      await showDialog<void>(
          context: context,
          builder: (context) =>
              AlertDialog(
                  title:
                      Text(advanced ? 'Advanced analytics' : 'Basic analytics'),
                  content: SingleChildScrollView(child: _Metrics(data)),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'))
                  ]));
    } catch (e) {
      if (mounted) setState(() => error = commercialError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> buy(Map<String, dynamic> product, bool credits) async {
    setState(() => busy = true);
    try {
      final id = '${product['id']}';
      final result = await actions.visibility(
          id, intents.putIfAbsent('$id:$credits', requestKey),
          credits: credits);
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
      final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                  title: const Text('Visibility purchase'),
                  content: Text(
                      'Pay ${commercialMoney(checkout['amountMinor'], checkout['currency'])}?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Back')),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Pay'))
                  ]));
      if (confirmed != true) {
        if (mounted) setState(() => busy = false);
        return;
      }
      gateway.open({
        'key': checkout['keyId'],
        'order_id': checkout['orderId'],
        'amount': checkout['amountMinor'],
        'currency': checkout['currency'],
        'name': 'Avantika Lok',
        'description': 'Provider visibility'
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

  @override
  Widget build(BuildContext context) => AppPage(
      title: 'Provider workspace',
      subtitle: 'Tools available through your subscription',
      child: FutureBuilder<Map<String, dynamic>>(
          future: future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return snapshot.hasError
                  ? AppErrorState(
                      message: commercialError(snapshot.error!),
                      onRetry: () => setState(reload))
                  : const AppLoadingView(message: 'Loading workspace…');
            }
            final data = snapshot.data!,
                items = data['items'] as List? ?? [],
                products = data['products'] as List? ?? [];
            return RefreshIndicator(
                onRefresh: () async {
                  setState(reload);
                  await future;
                },
                child: ListView(children: [
                  if (error != null) Text(error!),
                  Wrap(spacing: 8, children: [
                    for (final kind in [
                      'lead',
                      'staff',
                      'campaign',
                      'branding',
                      'api_key',
                      'support',
                      'coupon'
                    ])
                      OutlinedButton(
                          onPressed: busy ? null : () => create(kind),
                          child: Text('New ${kind.replaceAll('_', ' ')}')),
                    OutlinedButton(
                        onPressed: busy ? null : () => analytics(false),
                        child: const Text('Basic analytics')),
                    OutlinedButton(
                        onPressed: busy ? null : () => analytics(true),
                        child: const Text('Advanced analytics'))
                  ]),
                  const SizedBox(height: 20),
                  for (final raw in items)
                    ExpansionTile(
                        title: Text(
                            '${commercialMap(raw)['kind']} · ${commercialMap(commercialMap(raw)['payload'])['name'] ?? commercialMap(commercialMap(raw)['payload'])['title'] ?? commercialMap(raw)['state']}'),
                        children: [
                          Padding(
                              padding: const EdgeInsets.all(16),
                              child: _Metrics(
                                  commercialMap(commercialMap(raw)['payload'])))
                        ]),
                  const Divider(),
                  Text('Featured & sponsored visibility',
                      style: Theme.of(context).textTheme.titleLarge),
                  for (final raw in products)
                    Builder(builder: (context) {
                      final product = commercialMap(raw),
                          c = commercialMap(product['config']);
                      return AppPanel(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text('${product['name']}'),
                            Text(
                                '${commercialMoney(c['priceMinor'], c['currency'])} / ${c['durationDays']} days'),
                            Wrap(spacing: 8, children: [
                              FilledButton(
                                  onPressed:
                                      busy ? null : () => buy(product, false),
                                  child: const Text('Purchase')),
                              TextButton(
                                  onPressed:
                                      busy ? null : () => buy(product, true),
                                  child: const Text('Use plan credits'))
                            ])
                          ]));
                    }),
                  for (final raw in (data['purchases'] as List? ?? []))
                    ListTile(
                        title: Text(
                            '${commercialMap(raw)['kind']} · ${commercialMap(raw)['state']}'),
                        subtitle: Text('Until ${commercialMap(raw)['endsAt']}'))
                ]));
          }));
}

class _Metrics extends StatelessWidget {
  const _Metrics(this.data);
  final Map<String, dynamic> data;
  @override
  Widget build(BuildContext context) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final e in data.entries)
              if (e.key != 'keyHash')
                Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: e.value is Map
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text(e.key,
                                    style:
                                        Theme.of(context).textTheme.titleSmall),
                                Padding(
                                    padding: const EdgeInsets.only(left: 12),
                                    child: _Metrics(commercialMap(e.value)))
                              ])
                        : Text('${e.key.replaceAll('_', ' ')}: ${e.value}'))
          ]);
}
