import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/di/injection.dart';
import '../../../core/widgets/app_ui.dart';
import '../domain/commercial_repository.dart';
import 'price_breakdown.dart';

class FinanceDocumentsPage extends StatefulWidget {
  const FinanceDocumentsPage({this.provider = true, super.key});
  final bool provider;
  @override
  State<FinanceDocumentsPage> createState() => _FinanceDocumentsPageState();
}

class _FinanceDocumentsPageState extends State<FinanceDocumentsPage> {
  late Future<List<Map<String, dynamic>>> future;
  @override
  void initState() {
    super.initState();
    reload();
  }

  void reload() {
    final actions = getIt<CommercialActions>();
    future = Future.wait([
      if (widget.provider)
        actions.finance()
      else
        Future.value(<String, dynamic>{}),
      actions.invoices(provider: widget.provider)
    ]);
  }

  @override
  Widget build(BuildContext context) => AppPage(
      title: widget.provider ? 'Statements & invoices' : 'My invoices',
      child: FutureBuilder<List<Map<String, dynamic>>>(
          future: future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return snapshot.hasError
                  ? AppErrorState(
                      message: commercialError(snapshot.error!),
                      onRetry: () => setState(reload))
                  : const AppLoadingView(
                      message: 'Loading financial documents…');
            }
            final balances = commercialMap(snapshot.data![0]['currencies']);
            final docs = snapshot.data![1]['items'] as List? ?? [];
            return RefreshIndicator(
                onRefresh: () async {
                  setState(reload);
                  await future;
                },
                child: ListView(children: [
                  for (final cur in balances.entries)
                    AppPanel(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(cur.key,
                              style: Theme.of(context).textTheme.titleLarge),
                          for (final account
                              in commercialMap(cur.value).entries)
                            ListTile(
                                title: Text(account.key.replaceAll('_', ' ')),
                                trailing: Text(
                                    commercialMoney(account.value, cur.key)))
                        ])),
                  const SizedBox(height: 16),
                  Text('Issued documents',
                      style: Theme.of(context).textTheme.titleLarge),
                  if (docs.isEmpty) const Text('No issued invoices yet.'),
                  for (final raw in docs)
                    Builder(builder: (context) {
                      final doc = commercialMap(raw);
                      return ListTile(
                          leading: const Icon(Icons.receipt_long_outlined),
                          title: Text('${doc['number']}'),
                          subtitle:
                              Text('${doc['type']} · ${doc['createdAt']}'),
                          trailing: Text(commercialMoney(
                              doc['totalMinor'], doc['currency'])),
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                  builder: (_) => _InvoicePage(doc))));
                    })
                ]));
          }));
}

class _InvoicePage extends StatelessWidget {
  const _InvoicePage(this.doc);
  final Map<String, dynamic> doc;
  @override
  Widget build(BuildContext context) {
    final s = commercialMap(doc['snapshot']),
        issuer = commercialMap(s['issuer']);
    return AppPage(
        title: '${doc['number']}',
        child: ListView(children: [
          Text('${issuer['legalName'] ?? 'Avantika Lok'}',
              style: Theme.of(context).textTheme.titleLarge),
          Text('${issuer['address'] ?? ''}'),
          if (issuer['taxId'] != null) Text('Tax ID: ${issuer['taxId']}'),
          Text('Issued: ${doc['createdAt']}'),
          Text('Type: ${doc['type']}'),
          PriceBreakdown(snapshot: s, provider: true),
          Text(
              'Document total: ${commercialMoney(doc['totalMinor'], doc['currency'])}'),
          if (s['reason'] != null) Text('Reason: ${s['reason']}'),
          Text('${issuer['footer'] ?? ''}'),
          Builder(
              builder: (context) => OutlinedButton.icon(
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Save / share invoice'),
                  onPressed: () async {
                    try {
                      final file = await getIt<CommercialActions>()
                          .document('${doc['id']}');
                      if (!context.mounted) return;
                      final box = context.findRenderObject() as RenderBox?;
                      await Share.shareXFiles([
                        XFile.fromData(
                            Uint8List.fromList(utf8.encode('${file['html']}')),
                            mimeType: 'text/html')
                      ],
                          fileNameOverrides: [
                            '${file['number']}.html'
                          ],
                          sharePositionOrigin: box == null
                              ? null
                              : box.localToGlobal(Offset.zero) & box.size);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(commercialError(e))));
                      }
                    }
                  })),
          OutlinedButton.icon(
              icon: const Icon(Icons.copy),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(
                    text:
                        '${doc['number']}\n${issuer['legalName'] ?? 'Avantika Lok'}\n${issuer['address'] ?? ''}\nTotal: ${commercialMoney(doc['totalMinor'], doc['currency'])}\nIssued: ${doc['createdAt']}'));
              },
              label: const Text('Copy invoice summary'))
        ]));
  }
}
