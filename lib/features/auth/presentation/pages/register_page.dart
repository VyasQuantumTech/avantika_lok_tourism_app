import 'package:flutter/material.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/config/app_flavor.dart';
import '../../../../app/di/injection.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/usecases/login_user.dart';
import '../../domain/usecases/register_user.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_text_field.dart';

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
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _submitting = false;
  String? _serverError;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _serverError = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      await getIt<RegisterUser>()(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Registration returns the account only. Sign in immediately so the user
      // receives a persisted access/refresh-token session without a second form.
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
            'Unable to create the account right now. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _friendlyMessage(ApiException error) {
    if (error.code == 'EMAIL_ALREADY_EXISTS' || error.statusCode == 409) {
      return 'An account with this email already exists. Please sign in instead.';
    }
    if (error.statusCode == 429) {
      return 'Too many registration attempts. Please wait a moment and try again.';
    }
    if (error.details.isNotEmpty) {
      return error.details.first.message;
    }
    return error.message;
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Create your\nAvantika Lok account',
      subtitle: 'Register once to manage bookings and services securely',
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AuthTextField(
                      controller: _firstNameController,
                      label: 'First Name',
                      icon: Icons.person_outline,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.givenName],
                      validator: AppValidators.firstName,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AuthTextField(
                      controller: _lastNameController,
                      label: 'Last Name (optional)',
                      icon: Icons.person_outline,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.familyName],
                      validator: AppValidators.optionalLastName,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              AuthTextField(
                controller: _emailController,
                label: 'Email Address',
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [
                  AutofillHints.newUsername,
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
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                validator: AppValidators.registrationPassword,
              ),
              const SizedBox(height: 13),
              AuthTextField(
                controller: _confirmPasswordController,
                label: 'Confirm Password',
                icon: Icons.lock_outline,
                obscureText: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                validator: (value) => AppValidators.confirmPassword(
                  value,
                  _passwordController.text,
                ),
                onFieldSubmitted: (_) {
                  if (!_submitting) _submit();
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Password must be 8–128 characters.',
                style: AppTypography.caption.copyWith(fontSize: 10),
              ),
              if (_serverError != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: const Color(0xFFFFD6DB)),
                  ),
                  child: Text(
                    _serverError!,
                    style: AppTypography.caption.copyWith(
                      color: const Color(0xFFB42335),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              AuthPrimaryButton(
                label: 'Create Account',
                loading: _submitting,
                onPressed: _submit,
              ),
              const SizedBox(height: 10),
              AuthSwitchLink(
                prefix: 'Already have an account?',
                action: 'Login',
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
