import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../auth/presentation/widgets/auth_scaffold.dart';
import '../../../auth/presentation/widgets/auth_text_field.dart';
import '../../domain/usecases/check_provider_status.dart';
import '../../domain/usecases/register_provider.dart';

class ProviderRegistrationPage extends StatefulWidget {
  const ProviderRegistrationPage({super.key});

  @override
  State<ProviderRegistrationPage> createState() =>
      _ProviderRegistrationPageState();
}

class _ProviderRegistrationPageState extends State<ProviderRegistrationPage> {
  static const List<Map<String, String>> _providerTypes = [
    {
      'value': 'pandit',
      'label': 'Pandit',
    },
    {
      'value': 'vehicle_owner',
      'label': 'Transport',
    },
    {
      'value': 'hotel_manager',
      'label': 'Accommodation',
    },
    {
      'value': 'other',
      'label': 'Other',
    },
  ];

  String _selectedProviderType = 'pandit';


  final _formKey = GlobalKey<FormState>();
  final _legalNameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController(text: 'Ujjain');
  final _stateController = TextEditingController(text: 'Madhya Pradesh');
  final _countryCodeController = TextEditingController(text: 'IN');

  bool _submitting = false;
  String? _serverError;

  @override
  void dispose() {
    _legalNameController.dispose();
    _displayNameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryCodeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _serverError = null);

    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      await getIt<RegisterProvider>()(
        providerType: _selectedProviderType,
        legalName: _legalNameController.text,
        displayName: _displayNameController.text,
        phone: _phoneController.text,
        city: _cityController.text,
        state: _stateController.text,
        countryCode: _countryCodeController.text,
      );

      // Confirm the backend now recognises the signed-in user as a provider
      // before allowing entry to the provider dashboard.
      final providerStatus = await getIt<CheckProviderStatus>()();

      if (!providerStatus.isProvider) {
        throw const ApiException(
          'Provider profile was saved, but the account status could not be verified.',
        );
      }

      if (!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil(
        RouteNames.providerGate,
        (_) => false,
      );
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _serverError = _friendlyMessage(error);
      });
    } catch (_) {
      if (!mounted) return;

      setState(
            () => _serverError =
        'Unable to register your provider profile right now. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  String _friendlyMessage(ApiException error) {
    if (error.details.isNotEmpty) {
      return error.details.first.message;
    }

    if (error.statusCode == 409) {
      return 'A provider profile already exists for this account. Please try again.';
    }

    return error.message;
  }

  String? _required(
      String? value,
      String field, {
        int maxLength = 150,
      }) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return '$field is required.';
    }

    if (text.length > maxLength) {
      return '$field must not exceed $maxLength characters.';
    }

    return null;
  }

  String? _phoneValidator(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Phone number is required.';
    }

    if (text.length > 30) {
      return 'Phone number must not exceed 30 characters.';
    }

    if (!RegExp(r'^\+?[0-9]{8,15}$').hasMatch(text)) {
      return 'Enter a valid phone number, e.g. +919999999999.';
    }

    return null;
  }

  String? _countryCodeValidator(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Country code is required.';
    }

    if (!RegExp(r'^[A-Za-z]{2}$').hasMatch(text)) {
      return 'Use a 2-letter country code, e.g. IN.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Complete your\nprovider profile',
      subtitle:
      'Register this account as an Avantika Lok Seva provider before continuing',
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedProviderType,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Provider Type',
                prefixIcon: Icon(
                  Icons.business_center_outlined,
                  color: AppColors.primary,
                ),
                filled: true,
                fillColor: AppColors.brandSoft,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 12,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7),
                  borderSide: BorderSide(
                    color: AppColors.brandBorder,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7),
                  borderSide: BorderSide(
                    color: AppColors.primary,
                    width: 1.3,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7),
                  borderSide: const BorderSide(
                    color: Color(0xFFB42335),
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7),
                  borderSide: const BorderSide(
                    color: Color(0xFFB42335),
                    width: 1.3,
                  ),
                ),
              ),
              items: _providerTypes
                  .map(
                    (providerType) => DropdownMenuItem<String>(
                  value: providerType['value'],
                  child: Text(
                    providerType['label']!,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
                  .toList(),
              onChanged: _submitting
                  ? null
                  : (value) {
                if (value == null) return;

                setState(() {
                  _selectedProviderType = value;
                });
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Provider type is required.';
                }

                return null;
              },
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: _legalNameController,
              label: 'Legal Name',
              icon: Icons.badge_outlined,
              textInputAction: TextInputAction.next,
              validator: (value) => _required(
                value,
                'Legal name',
              ),
            ),
            const SizedBox(height: 13),
            AuthTextField(
              controller: _displayNameController,
              label: 'Display Name',
              icon: Icons.person_outline,
              textInputAction: TextInputAction.next,
              validator: (value) => _required(
                value,
                'Display name',
              ),
            ),
            const SizedBox(height: 13),
            AuthTextField(
              controller: _phoneController,
              label: 'Phone',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              validator: _phoneValidator,
            ),
            const SizedBox(height: 13),
            AuthTextField(
              controller: _cityController,
              label: 'City',
              icon: Icons.location_city_outlined,
              textInputAction: TextInputAction.next,
              validator: (value) => _required(
                value,
                'City',
                maxLength: 100,
              ),
            ),
            const SizedBox(height: 13),
            AuthTextField(
              controller: _stateController,
              label: 'State',
              icon: Icons.map_outlined,
              textInputAction: TextInputAction.next,
              validator: (value) => _required(
                value,
                'State',
                maxLength: 100,
              ),
            ),
            const SizedBox(height: 13),
            AuthTextField(
              controller: _countryCodeController,
              label: 'Country Code',
              icon: Icons.public_outlined,
              textInputAction: TextInputAction.done,
              validator: _countryCodeValidator,
              onFieldSubmitted: (_) {
                if (!_submitting) {
                  _submit();
                }
              },
            ),
            if (_serverError != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: const Color(0xFFFFD6DB),
                  ),
                ),
                child: Text(
                  _serverError!,
                  style: AppTypography.caption.copyWith(
                    color: const Color(0xFFB42335),
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            AuthPrimaryButton(
              label: 'Register as Provider',
              loading: _submitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}