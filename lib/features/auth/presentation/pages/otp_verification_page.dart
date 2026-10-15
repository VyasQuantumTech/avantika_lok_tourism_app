import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/verification_challenge.dart';
import '../../domain/usecases/verification_actions.dart';

class OtpVerificationPage extends StatefulWidget {
  const OtpVerificationPage({super.key, required this.challenge});
  final VerificationChallenge challenge;
  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  late VerificationChallenge _challenge;
  final _code = TextEditingController();
  Timer? _timer;
  bool _busy = false, _complete = false;
  String? _error;
  int get _remaining =>
      _challenge.resendAt.difference(DateTime.now()).inSeconds.clamp(0, 3600);
  @override
  void initState() {
    super.initState();
    _challenge = widget.challenge;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(
            () => _error = 'Unable to verify right now. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() => _run(() async {
        if (!RegExp(r'^\d{6}$').hasMatch(_code.text)) {
          throw const ApiException('Enter the six-digit code.');
        }
        if (_challenge.purpose == 'delete_account') {
          final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                      title: const Text('Confirm account deletion'),
                      content: const Text(
                          'Your account will be disabled and all devices signed out. Booking, payment and legal records may be retained under the retention policy. This action cannot be undone in the app.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel')),
                        TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete account'))
                      ]));
          if (confirmed != true) return;
        }
        await getIt<VerificationActions>().repository.verify(
            _challenge, _code.text,
            confirm: _challenge.purpose == 'delete_account');
        _complete = true;
        if (mounted) Navigator.pop(context, true);
      });
  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_busy,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop && !_complete) {
            unawaited(getIt<VerificationActions>()
                .repository
                .cancel(_challenge)
                .catchError((_) {}));
          }
        },
        child: Scaffold(
            appBar: AppBar(title: const Text('Verify your identity')),
            body: ListView(padding: const EdgeInsets.all(24), children: [
              Text('Enter the code sent to ${_challenge.destination}'),
              const SizedBox(height: 20),
              TextField(
                  controller: _code,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration:
                      const InputDecoration(labelText: 'Verification code'),
                  onSubmitted: (_) {
                    if (!_busy) _verify();
                  }),
              Text(DateTime.now().isAfter(_challenge.expiresAt)
                  ? 'Code expired. Request a new code.'
                  : 'Code expires in ${_challenge.expiresAt.difference(DateTime.now()).inSeconds.clamp(0, 900)} seconds.'),
              if (_error != null)
                Text(_error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              const SizedBox(height: 16),
              FilledButton(
                  onPressed: _busy ? null : _verify,
                  child: Text(_busy ? 'Please wait…' : 'Verify')),
              TextButton(
                  onPressed: _busy || _remaining > 0
                      ? null
                      : () => _run(() async {
                            final next = await getIt<VerificationActions>()
                                .repository
                                .resend(_challenge);
                            if (mounted) {
                              setState(() {
                                _challenge = next;
                                _code.clear();
                              });
                            }
                          }),
                  child: Text(_remaining > 0
                      ? 'Resend in $_remaining seconds'
                      : 'Resend code')),
              TextButton(
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                            await getIt<VerificationActions>()
                                .repository
                                .cancel(_challenge);
                            _complete = true;
                            if (context.mounted) Navigator.pop(context, false);
                          }),
                  child: const Text('Change email / mobile')),
            ])),
      );
}
