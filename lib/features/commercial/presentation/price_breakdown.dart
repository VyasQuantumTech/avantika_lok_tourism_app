import 'package:flutter/material.dart';
import '../../../app/di/injection.dart';
import '../../../core/errors/exceptions.dart';
import '../domain/commercial_repository.dart';

Map<String, dynamic> commercialMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : {};
String commercialMoney(dynamic amount, [dynamic currency = 'INR']) =>
    '$currency ${(num.tryParse('$amount') ?? 0) / 100}'.replaceFirstMapped(
        RegExp(r'\d+\.\d+$'),
        (m) => (double.tryParse(m[0]!) ?? 0).toStringAsFixed(2));
String commercialError(Object error) => error is ApiException
    ? error.message
    : 'Unable to load commercial information. Please retry.';

class PriceBreakdown extends StatelessWidget {
  const PriceBreakdown(
      {required this.snapshot, this.provider = false, super.key});
  final Map<String, dynamic> snapshot;
  final bool provider;
  @override
  Widget build(BuildContext context) {
    final currency = snapshot['currency'] ?? 'INR';
    final lines =
        snapshot['lines'] is List ? snapshot['lines'] as List : const [];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final raw in lines)
        if (provider || commercialMap(raw)['bearer'] == 'customer') ...[
          ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                  '${commercialMap(raw)['label'] ?? commercialMap(raw)['type']}'),
              subtitle: Text('${commercialMap(raw)['bearer']}'),
              trailing: Text(
                  commercialMoney(commercialMap(raw)['totalMinor'], currency))),
          for (final tax in (commercialMap(raw)['taxes'] as List? ?? []))
            Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 4),
                child: Text(
                    '${commercialMap(tax)['code']} · ${(num.tryParse('${commercialMap(tax)['rateBps']}') ?? 0) / 100}% · ${commercialMoney(commercialMap(tax)['amountMinor'], currency)} (${commercialMap(tax)['mode']})')),
        ],
      if ((num.tryParse('${snapshot['discountMinor']}') ?? 0) > 0)
        Text(
            'Discount: ${commercialMoney(snapshot['discountMinor'], currency)}'),
      const Divider(),
      Text(
          'Total: ${commercialMoney(snapshot['customerPayableMinor'], currency)}',
          style: Theme.of(context).textTheme.titleMedium),
      if (provider)
        Text(
            'Provider payable: ${commercialMoney(snapshot['providerPayableMinor'], currency)}'),
    ]);
  }
}

Future<Map<String, dynamic>?> reviewCommercialPrice(
        BuildContext context, Map<String, dynamic> booking) =>
    showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _PriceReview(booking));

class _PriceReview extends StatefulWidget {
  const _PriceReview(this.booking);
  final Map<String, dynamic> booking;
  @override
  State<_PriceReview> createState() => _PriceReviewState();
}

class _PriceReviewState extends State<_PriceReview> {
  final coupon = TextEditingController();
  Map<String, dynamic>? quote;
  String? error;
  bool busy = false;
  String method = 'upi';
  List<dynamic> addons = [];
  List<String> methods = ['upi', 'card', 'netbanking', 'wallet', 'cash'];
  final quantities = <String, int>{};
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    coupon.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      busy = true;
      error = null;
      quote = null;
    });
    try {
      final result = await getIt<CommercialActions>().quote({
        ...widget.booking,
        if (coupon.text.trim().isNotEmpty) 'couponCode': coupon.text.trim(),
        'paymentMethod': method,
        'addons': [
          for (final e in quantities.entries)
            if (e.value > 0) {'id': e.key, 'quantity': e.value}
        ]
      });
      if (mounted) {
        setState(() {
          quote = commercialMap(result['commercial']);
          addons = quote!['availableAddons'] as List? ?? [];
          methods = (quote!['availablePaymentMethods'] as List?)
                  ?.map((v) => '$v')
                  .toList() ??
              methods;
          method =
              '${commercialMap(quote!['context'])['paymentMethod'] ?? method}';
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = commercialError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
          title: const Text('Review final price'),
          content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                DropdownButtonFormField<String>(
                    value: method,
                    decoration:
                        const InputDecoration(labelText: 'Payment method'),
                    items: [
                      for (final value in methods)
                        DropdownMenuItem(value: value, child: Text(value))
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          method = v;
                          quote = null;
                        });
                      }
                    }),
                for (final raw in addons)
                  ListTile(
                      title: Text('${commercialMap(raw)['name']}'),
                      subtitle: Text(commercialMoney(
                          commercialMap(raw)['unitPriceMinor'],
                          quote?['currency'] ?? 'INR')),
                      trailing: SizedBox(
                          width: 88,
                          child: TextFormField(
                              initialValue:
                                  '${quantities['${commercialMap(raw)['id']}'] ?? 0}',
                              keyboardType: TextInputType.number,
                              decoration:
                                  const InputDecoration(labelText: 'Quantity'),
                              onChanged: (value) => setState(() {
                                    quantities['${commercialMap(raw)['id']}'] =
                                        int.tryParse(value) ?? 0;
                                    quote = null;
                                  })))),
                TextField(
                    controller: coupon,
                    decoration: const InputDecoration(
                        labelText: 'Coupon code (optional)'),
                    onChanged: (_) => setState(() => quote = null)),
                if (busy)
                  const Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator()),
                if (error != null)
                  Text(error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                if (quote != null) PriceBreakdown(snapshot: quote!),
                if (!busy && quote == null)
                  TextButton(
                      onPressed: load, child: const Text('Calculate price'))
              ]))),
          actions: [
            TextButton(
                onPressed: busy ? null : () => Navigator.pop(context),
                child: const Text('Back')),
            FilledButton(
                onPressed: quote == null || busy
                    ? null
                    : () => Navigator.pop(context, {
                          'expectedPriceHash': quote!['quoteHash'],
                          'paymentMethod': method,
                          'addons': [
                            for (final e in quantities.entries)
                              if (e.value > 0)
                                {'id': e.key, 'quantity': e.value}
                          ],
                          if (coupon.text.trim().isNotEmpty)
                            'couponCode': coupon.text.trim()
                        }),
                child: const Text('Confirm price'))
          ]);
}
