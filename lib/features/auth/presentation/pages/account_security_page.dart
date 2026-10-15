import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../../app/di/injection.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/usecases/verification_actions.dart';
import 'otp_verification_page.dart';

class AccountSecurityPage extends StatefulWidget {
  const AccountSecurityPage({super.key});
  @override
  State<AccountSecurityPage> createState() => _AccountSecurityPageState();
}

class _AccountSecurityPageState extends State<AccountSecurityPage> {
  String? _error;
  bool _busy = false;
  String _channel = 'email';
  final _identity = TextEditingController();
  late Future<List<Map<String, dynamic>>> _sessions =
      getIt<VerificationActions>().repository.sessions();
  late Future<List<Map<String, dynamic>>> _social =
      getIt<VerificationActions>().repository.socialIdentities();
  late final _capabilities =
      getIt<VerificationActions>().repository.capabilities();
  @override
  void dispose() {
    _identity.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
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
            () => _error = 'Unable to complete this action. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _signedOut() {
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
          context, RouteNames.login, (_) => false);
    }
  }

  Future<void> _challenge(String purpose) => _run(() async {
        final challenge = await getIt<VerificationActions>().repository.request(
            channel: _channel, identity: _identity.text, purpose: purpose);
        if (!mounted) return;
        final ok = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
                builder: (_) => OtpVerificationPage(challenge: challenge)));
        if (ok == true) _signedOut();
      });
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Account security')),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        const Text(
            'Add or change a verified email/mobile, manage sign-in methods, or request account deletion. Verification is required before changes take effect.'),
        SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'email', label: Text('Email')),
              ButtonSegment(value: 'sms', label: Text('Mobile'))
            ],
            selected: {
              _channel
            },
            onSelectionChanged:
                _busy ? null : (v) => setState(() => _channel = v.first)),
        TextField(
            controller: _identity,
            decoration: InputDecoration(
                labelText: _channel == 'email'
                    ? 'Email address'
                    : 'Mobile with country code')),
        if (_error != null)
          Text(_error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
        FilledButton(
            onPressed: _busy
                ? null
                : () => _challenge(
                    _channel == 'email' ? 'change_email' : 'change_mobile'),
            child: const Text('Verify and save identity')),
        FutureBuilder<Map<String, dynamic>>(
            future: _capabilities,
            builder: (context, snapshot) {
              final providers =
                  (snapshot.data?['socialProviders'] as List?) ?? [];
              return Column(children: [
                for (final provider in providers)
                  if (provider != 'apple' ||
                      defaultTargetPlatform == TargetPlatform.iOS ||
                      defaultTargetPlatform == TargetPlatform.macOS)
                    TextButton(
                        onPressed: _busy
                            ? null
                            : () => _run(() => getIt<VerificationActions>()
                                .repository
                                .social(provider.toString(), link: true)),
                        child: Text('Link $provider'))
              ]);
            }),
        TextButton(
            onPressed: _busy
                ? null
                : () => _run(() async {
                      await getIt<VerificationActions>().repository.logoutAll();
                      _signedOut();
                    }),
            child: const Text('Log out all devices')),
        FutureBuilder<List<Map<String, dynamic>>>(
            future: _sessions,
            builder: (context, snapshot) => Column(children: [
                  const Text('Active sessions'),
                  if (snapshot.hasError)
                    TextButton(
                        onPressed: () => setState(() => _sessions =
                            getIt<VerificationActions>().repository.sessions()),
                        child: const Text('Retry session list')),
                  for (final item in snapshot.data ?? <Map<String, dynamic>>[])
                    ListTile(
                        title: Text(item['device']?.toString() ?? 'Device'),
                        subtitle: Text('Signed in: ${item['createdAt']}')),
                ])),
        FutureBuilder<List<Map<String, dynamic>>>(
            future: _social,
            builder: (context, snapshot) => Column(children: [
                  if (snapshot.hasError)
                    TextButton(
                        onPressed: () => setState(() => _social =
                            getIt<VerificationActions>()
                                .repository
                                .socialIdentities()),
                        child: const Text('Retry linked providers')),
                  for (final item in snapshot.data ?? <Map<String, dynamic>>[])
                    ListTile(
                        title: Text(item['provider'].toString()),
                        trailing: TextButton(
                            onPressed: _busy
                                ? null
                                : () => _run(() async {
                                      await getIt<VerificationActions>()
                                          .repository
                                          .unlink(item['id'].toString());
                                      if (mounted) {
                                        setState(() => _social =
                                            getIt<VerificationActions>()
                                                .repository
                                                .socialIdentities());
                                      }
                                    }),
                            child: const Text('Unlink'))),
                ])),
        const Divider(),
        const Text(
            'Delete Account disables your account and signs out every device. Required booking, payment and legal records may be retained. Enter your current verified email or mobile above to receive a fresh deletion code.'),
        TextButton(
            onPressed: _busy ? null : () => _challenge('delete_account'),
            child: const Text('Delete Account')),
        const Text(
            'Lost access? Use another verified channel to sign in. If none is available, contact support for manual recovery.'),
      ]));
}
