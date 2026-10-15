import 'package:flutter/material.dart';
import '../../../../app/config/app_config.dart';
import '../../../../app/config/app_flavor.dart';
import '../../../../app/di/injection.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/usecases/verification_actions.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_channel_selector.dart';
import 'otp_verification_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  String _channel = 'email';
  bool _submitting = false;
  String? _serverError;
  @override
  void dispose() {
    for (final controller in [
      _firstNameController,
      _lastNameController,
      _emailController,
      _mobileController
    ]) {
      controller.dispose();
    }
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
          purpose: 'registration',
          firstName: _firstNameController.text,
          lastName: _lastNameController.text);
      if (!mounted) return;
      final verified = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
              builder: (_) => OtpVerificationPage(challenge: challenge)));
      if (!mounted || verified != true) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
          getIt<AppConfig>().flavor == AppFlavor.provider
              ? RouteNames.providerGate
              : RouteNames.home,
          (_) => false);
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _serverError = error.statusCode == 429
            ? 'Too many requests. Please wait before trying again.'
            : error.details.isNotEmpty
                ? error.details.first.message
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
        title: 'Create your\nAvantika Lok account',
        subtitle: 'Verify your email or mobile to get started',
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
                      AuthTextField(
                          controller: _firstNameController,
                          label: 'First Name',
                          icon: Icons.person_outline,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.givenName],
                          validator: AppValidators.firstName),
                      const SizedBox(height: 13),
                      AuthTextField(
                          controller: _lastNameController,
                          label: 'Last Name (optional)',
                          icon: Icons.person_outline,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.familyName],
                          validator: AppValidators.optionalLastName),
                      const SizedBox(height: 13),
                      AuthIdentityField(
                          channel: _channel,
                          emailController: _emailController,
                          mobileController: _mobileController,
                          onSubmitted: (_) => _submit()),
                      const SizedBox(height: 12),
                      Text(
                          'Your account becomes active after you enter the verification code.',
                          style: AppTypography.caption),
                      if (_serverError != null) ...[
                        const SizedBox(height: 12),
                        Text(_serverError!,
                            style: AppTypography.caption
                                .copyWith(color: AppColors.error))
                      ],
                      const SizedBox(height: 16),
                      AuthPrimaryButton(
                          label: 'Create Account',
                          loading: _submitting,
                          onPressed: _submit),
                      const SizedBox(height: 10),
                      AuthSwitchLink(
                          prefix: 'Already have an account?',
                          action: 'Login',
                          onTap: () {
                            if (!_submitting) Navigator.of(context).pop();
                          }),
                    ]))),
      );
}
