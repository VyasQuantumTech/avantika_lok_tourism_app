import 'package:flutter/material.dart';
import '../../../app/di/injection.dart';
import '../../../core/widgets/app_ui.dart';
import '../domain/commercial_repository.dart';
import 'price_breakdown.dart';

class TaxProfilePage extends StatefulWidget {
  const TaxProfilePage({super.key});
  @override
  State<TaxProfilePage> createState() => _TaxProfilePageState();
}

class _TaxProfilePageState extends State<TaxProfilePage> {
  final key = GlobalKey<FormState>();
  final fields = {
    for (final k in ['legalName', 'address', 'countryCode', 'state', 'taxId'])
      k: TextEditingController()
  };
  bool busy = true;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final result = await getIt<CommercialActions>().profile();
      final profile = commercialMap(commercialMap(result['profile'])['config']);
      for (final e in fields.entries) {
        e.value.text =
            '${profile[e.key] ?? (e.key == 'countryCode' ? 'IN' : '')}';
      }
    } catch (e) {
      error = commercialError(e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (!key.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      await getIt<CommercialActions>().saveProfile(
          {for (final e in fields.entries) e.key: e.value.text.trim()});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Tax profile submitted for finance verification.')));
      }
    } catch (e) {
      if (mounted) setState(() => error = commercialError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AppPage(
      title: 'Tax profile',
      child: Form(
          key: key,
          child: ListView(children: [
            if (error != null) Text(error!),
            for (final e in fields.entries)
              Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextFormField(
                      controller: e.value,
                      decoration: InputDecoration(
                          labelText:
                              e.key.replaceAll(RegExp(r'(?=[A-Z])'), ' ')),
                      validator: (v) =>
                          e.key != 'taxId' && (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null)),
            FilledButton(
                onPressed: busy ? null : save,
                child: Text(busy ? 'Loading…' : 'Submit for verification'))
          ])));
}
