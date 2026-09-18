import 'package:flutter/material.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/config/app_flavor.dart';
import '../../../../app/di/injection.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/usecases/login_user.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_text_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitting = false;
  String? _serverError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _serverError = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      await getIt<LoginUser>()(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;

      final config = getIt<AppConfig>();
      final nextRoute = config.flavor == AppFlavor.provider
          ? RouteNames.providerGate
          : RouteNames.home;

      Navigator.of(context).pushNamedAndRemoveUntil(
        nextRoute,
        (_) => false,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _serverError = _friendlyMessage(error));
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _serverError =
            'Unable to sign in right now. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _friendlyMessage(ApiException error) {
    if (error.code == 'INVALID_CREDENTIALS' || error.statusCode == 401) {
      return 'The email or password is incorrect.';
    }
    if (error.statusCode == 429) {
      return 'Too many sign-in attempts. Please wait a moment and try again.';
    }
    return error.message;
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Go ahead and set up\nyour account',
      subtitle: 'Sign in to enjoy the best booking experience',
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.softSurface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Container(
                  margin: const EdgeInsets.all(3),
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    'Email',
                    style: AppTypography.body.copyWith(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _emailController,
                label: 'Email Address',
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [
                  AutofillHints.username,
                  AutofillHints.email,
                ],
                validator: AppValidators.email,
              ),
              const SizedBox(height: 13),
              AuthTextField(
                controller: _passwordController,
                label: 'Password',
                icon: Icons.key_outlined,
                obscureText: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                validator: AppValidators.loginPassword,
                onFieldSubmitted: (_) {
                  if (!_submitting) _submit();
                },
              ),
              if (_serverError != null) ...[
                const SizedBox(height: 12),
                _InlineError(message: _serverError!),
              ],
              const SizedBox(height: 16),
              AuthPrimaryButton(
                label: 'Login',
                loading: _submitting,
                onPressed: _submit,
              ),
              const SizedBox(height: 16),
              AuthSwitchLink(
                prefix: 'New to Avantika Lok?',
                action: 'Create account',
                onTap: () =>
                    Navigator.of(context).pushNamed(RouteNames.register),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.errorSoft,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppColors.error.withValues(alpha: .22)),
      ),
      child: Text(
        message,
        style: AppTypography.caption.copyWith(
          color: AppColors.error,
          fontSize: 11,
          height: 1.3,
        ),
      ),
    );
  }
}
