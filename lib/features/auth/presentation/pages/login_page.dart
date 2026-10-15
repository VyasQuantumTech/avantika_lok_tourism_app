import 'package:flutter/material.dart';
import '../../../../app/config/app_config.dart';
import '../../../../app/config/app_flavor.dart';
import '../../../../app/di/injection.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/usecases/verification_actions.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_channel_selector.dart';
import 'otp_verification_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  String _channel = 'email';
  bool _submitting = false;
  String? _serverError;
  @override
  void initState() {
    super.initState();
    if (getIt.isRegistered<VerificationActions>()) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _resumePending());
    }
  }

  void _goToApp() => Navigator.of(context).pushNamedAndRemoveUntil(
      getIt<AppConfig>().flavor == AppFlavor.provider
          ? RouteNames.providerGate
          : RouteNames.home,
      (_) => false);
  Future<void> _resumePending() async {
    try {
      final pending =
          await getIt<VerificationActions>().repository.restorePending();
      if (!mounted || pending == null || _submitting) return;
      final verified = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
              builder: (_) => OtpVerificationPage(challenge: pending)));
      if (mounted && verified == true) _goToApp();
    } catch (_) {/* A new OTP can be requested from this form. */}
  }

  @override
  void dispose() {
    _emailController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    FocusScope.of(context).unfocus();
    setState(() => _serverError = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final challenge = await getIt<VerificationActions>().repository.request(
          channel: _channel,
          identity: _channel == 'email'
              ? _emailController.text
              : _mobileController.text,
          purpose: 'login');
      if (!mounted) return;
      final verified = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
              builder: (_) => OtpVerificationPage(challenge: challenge)));
      if (mounted && verified == true) _goToApp();
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _serverError = error.statusCode == 429
            ? 'Too many requests. Please wait before trying again.'
            : error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _serverError =
            'Unable to send a verification code. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthScaffold(
        title: 'Welcome to\nAvantika Lok',
        subtitle: 'Sign in securely with a one-time verification code',
        child: AutofillGroup(
            child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AuthChannelSelector(
                          channel: _channel,
                          enabled: !_submitting,
                          onChanged: (value) => setState(() {
                                _channel = value;
                                _serverError = null;
                              })),
                      const SizedBox(height: 16),
                      AuthIdentityField(
                          channel: _channel,
                          emailController: _emailController,
                          mobileController: _mobileController,
                          onSubmitted: (_) => _submit()),
                      const SizedBox(height: 12),
                      Text(
                          'We’ll send a one-time code to your ${_channel == 'email' ? 'email address' : 'mobile number'}.',
                          style: AppTypography.caption),
                      if (_serverError != null) ...[
                        const SizedBox(height: 12),
                        Text(_serverError!,
                            style: AppTypography.caption
                                .copyWith(color: AppColors.error))
                      ],
                      const SizedBox(height: 16),
                      AuthPrimaryButton(
                          label: 'Send verification code',
                          loading: _submitting,
                          onPressed: _submit),
                      const SizedBox(height: 16),
                      AuthSwitchLink(
                          prefix: 'New to Avantika Lok?',
                          action: 'Create account',
                          onTap: () {
                            if (!_submitting) {
                              Navigator.of(context)
                                  .pushNamed(RouteNames.register);
                            }
                          }),
                    ]))),
      );
}
