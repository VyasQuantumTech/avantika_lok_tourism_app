import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/temple_surface.dart';
import '../../../../core/utils/validators.dart';
import 'auth_text_field.dart';

class AuthChannelSelector extends StatelessWidget {
  const AuthChannelSelector(
      {super.key,
      required this.channel,
      required this.onChanged,
      this.enabled = true});
  final String channel;
  final ValueChanged<String> onChanged;
  final bool enabled;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
            color: AppColors.softSurface,
            borderRadius: BorderRadius.circular(24)),
        child: Row(children: [
          for (final item in const [('email', 'Email'), ('sms', 'Mobile')])
            Expanded(
              child: Semantics(
                  selected: channel == item.$1,
                  button: true,
                  child: InkWell(
                    key: ValueKey('auth-channel-${item.$1}'),
                    borderRadius: BorderRadius.circular(22),
                    onTap: enabled ? () => onChanged(item.$1) : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          gradient: channel == item.$1
                              ? TempleArt.brandGradient
                              : null,
                          borderRadius: BorderRadius.circular(22)),
                      child: Text(item.$2,
                          style: AppTypography.body.copyWith(
                              fontSize: 12,
                              color: channel == item.$1
                                  ? AppColors.onPrimary
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w600)),
                    ),
                  )),
            )
        ]),
      );
}

class AuthIdentityField extends StatelessWidget {
  const AuthIdentityField(
      {super.key,
      required this.channel,
      required this.emailController,
      required this.mobileController,
      this.onSubmitted});
  final String channel;
  final TextEditingController emailController, mobileController;
  final ValueChanged<String>? onSubmitted;
  @override
  Widget build(BuildContext context) => AuthTextField(
        key: ValueKey('auth-identity-$channel'),
        controller: channel == 'email' ? emailController : mobileController,
        label: channel == 'email'
            ? 'Email Address'
            : 'Mobile Number (India: 10 digits or +country code)',
        icon: channel == 'email' ? Icons.mail_outline : Icons.phone_outlined,
        keyboardType: channel == 'email'
            ? TextInputType.emailAddress
            : TextInputType.phone,
        textInputAction: TextInputAction.done,
        autofillHints: channel == 'email'
            ? const [AutofillHints.email]
            : const [AutofillHints.telephoneNumber],
        validator:
            channel == 'email' ? AppValidators.email : AppValidators.mobile,
        onFieldSubmitted: onSubmitted,
      );
}
