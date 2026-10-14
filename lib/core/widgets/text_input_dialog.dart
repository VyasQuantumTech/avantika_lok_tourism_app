import 'package:flutter/material.dart';
import '../errors/exceptions.dart';

// The route owns its controller until unmount, including its closing animation.
class AppTextInputDialog extends StatefulWidget {
  const AppTextInputDialog(
      {required this.title,
      required this.label,
      this.helperText,
      this.confirmLabel = 'Continue',
      this.keyboardType,
      this.maxLength,
      this.validator,
      this.onSubmit,
      super.key});
  final String title, label, confirmLabel;
  final String? helperText;
  final TextInputType? keyboardType;
  final int? maxLength;
  final String? Function(String)? validator;
  final Future<void> Function(String)? onSubmit;
  @override
  State<AppTextInputDialog> createState() => _AppTextInputDialogState();
}

class _AppTextInputDialogState extends State<AppTextInputDialog> {
  final controller = TextEditingController();
  bool busy = false;
  String? error;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy) return;
    final value = controller.text.trim();
    final validation = widget.validator?.call(value);
    if (validation != null) {
      setState(() => error = validation);
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.onSubmit?.call(value);
      if (mounted) Navigator.pop(context, value);
    } on ApiException catch (failure) {
      if (mounted) setState(() => error = failure.message);
    } catch (_) {
      if (mounted)
        setState(() => error = 'Unable to continue. Please try again.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !busy,
      child: AlertDialog(
        title: Text(widget.title),
        content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: controller,
              autofocus: true,
              enabled: !busy,
              keyboardType: widget.keyboardType,
              maxLength: widget.maxLength,
              decoration: InputDecoration(
                  labelText: widget.label, helperText: widget.helperText),
              onSubmitted: (_) => submit(),
              onChanged: (_) {
                if (error != null) setState(() => error = null);
              }),
          if (error != null)
            Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error))),
        ])),
        actions: [
          TextButton(
              onPressed: busy ? null : () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: busy ? null : submit,
              child: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(widget.confirmLabel)),
        ],
      ));
}
