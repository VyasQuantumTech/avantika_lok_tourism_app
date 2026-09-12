import 'package:flutter/material.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/config/app_flavor.dart';
import '../../../../app/di/injection.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/profile_snapshot.dart';
import '../../domain/usecases/get_my_profile.dart';
import '../../domain/usecases/update_my_profile.dart';
import '../../domain/usecases/update_my_provider_profile.dart';

class CustomerProfileEditPage extends StatelessWidget {
  const CustomerProfileEditPage({super.key});
  @override
  Widget build(BuildContext context) => const ProfileEditPage(providerMode: false);
}

class ProviderProfileEditPage extends StatelessWidget {
  const ProviderProfileEditPage({super.key});
  @override
  Widget build(BuildContext context) => const ProfileEditPage(providerMode: true);
}

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({required this.providerMode, super.key});
  final bool providerMode;

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  late Future<ProfileSnapshot> _future;

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _address1 = TextEditingController();
  final _address2 = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _postal = TextEditingController();
  final _dob = TextEditingController();
  final _birthTime = TextEditingController();

  final _providerLegalName = TextEditingController();
  final _providerDisplayName = TextEditingController();
  final _providerPhone = TextEditingController();
  final _providerAddress1 = TextEditingController();
  final _providerAddress2 = TextEditingController();
  final _providerCity = TextEditingController();
  final _providerState = TextEditingController();
  final _providerPostal = TextEditingController();

  ProfileSnapshot? _loaded;
  String? _gender;
  bool _submitting = false;
  bool _bound = false;
  String? _serverError;

  @override
  void initState() {
    super.initState();
    _future = getIt<GetMyProfile>()();
  }

  @override
  void dispose() {
    for (final controller in [
      _firstName, _lastName, _phone, _address1, _address2, _city, _state,
      _postal, _dob, _birthTime, _providerLegalName, _providerDisplayName,
      _providerPhone, _providerAddress1, _providerAddress2, _providerCity,
      _providerState, _providerPostal,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _bind(ProfileSnapshot profile) {
    if (_bound) return;
    _bound = true;
    _loaded = profile;
    final personal = profile.personalProfile;
    final provider = profile.providerProfile;
    _firstName.text = profile.account.firstName;
    _lastName.text = profile.account.lastName ?? '';
    _phone.text = personal?.phone ?? '';
    _address1.text = personal?.addressLine1 ?? '';
    _address2.text = personal?.addressLine2 ?? '';
    _city.text = personal?.city ?? '';
    _state.text = personal?.state ?? '';
    _postal.text = personal?.postalCode ?? '';
    _dob.text = personal?.dateOfBirth ?? '';
    _birthTime.text = _trimTime(personal?.birthTime);
    _gender = personal?.gender;

    _providerLegalName.text = provider?.legalName ?? '';
    _providerDisplayName.text = provider?.displayName ?? '';
    _providerPhone.text = provider?.phone ?? '';
    _providerAddress1.text = provider?.addressLine1 ?? '';
    _providerAddress2.text = provider?.addressLine2 ?? '';
    _providerCity.text = provider?.city ?? '';
    _providerState.text = provider?.state ?? '';
    _providerPostal.text = provider?.postalCode ?? '';
  }

  String _trimTime(String? value) {
    if (value == null || value.isEmpty) return '';
    return value.length >= 5 ? value.substring(0, 5) : value;
  }

  String? _nullable(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _pickDate() async {
    final existing = DateTime.tryParse(_dob.text);
    final date = await showDatePicker(
      context: context,
      initialDate: existing ?? DateTime(1995, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date == null) return;
    setState(() {
      _dob.text = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _pickTime() async {
    final parts = _birthTime.text.split(':');
    final initial = parts.length >= 2
        ? TimeOfDay(hour: int.tryParse(parts[0]) ?? 9, minute: int.tryParse(parts[1]) ?? 0)
        : const TimeOfDay(hour: 9, minute: 0);
    final time = await showTimePicker(context: context, initialTime: initial);
    if (time == null) return;
    setState(() {
      _birthTime.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    final loaded = _loaded;
    if (loaded == null) return;

    setState(() {
      _submitting = true;
      _serverError = null;
    });

    try {
      await getIt<UpdateMyProfile>()(
        fields: <String, dynamic>{
          'firstName': _firstName.text.trim(),
          'lastName': _nullable(_lastName.text),
          'phone': _nullable(_phone.text),
          'gender': _gender,
          'dateOfBirth': _nullable(_dob.text),
          'birthTime': _nullable(_birthTime.text),
          'addressLine1': _nullable(_address1.text),
          'addressLine2': _nullable(_address2.text),
          'city': _nullable(_city.text),
          'state': _nullable(_state.text),
          'postalCode': _nullable(_postal.text),
          'countryCode': loaded.personalProfile?.countryCode ?? 'IN',
        },
      );

      if (widget.providerMode) {
        final provider = loaded.providerProfile;
        if (provider == null) {
          throw const ApiException('Provider profile is missing for this account.');
        }
        await getIt<UpdateMyProviderProfile>()(
          providerType: provider.providerType,
          legalName: _providerLegalName.text.trim(),
          displayName: _nullable(_providerDisplayName.text),
          phone: _nullable(_providerPhone.text),
          addressLine1: _nullable(_providerAddress1.text),
          addressLine2: _nullable(_providerAddress2.text),
          city: _nullable(_providerCity.text),
          state: _nullable(_providerState.text),
          postalCode: _nullable(_providerPostal.text),
          countryCode: provider.countryCode ?? 'IN',
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully.')));
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _serverError = error.details.isNotEmpty ? error.details.first.message : error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _serverError = 'Unable to update profile right now.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final flavor = getIt<AppConfig>().flavor;
    if (widget.providerMode && flavor != AppFlavor.provider) {
      return const Scaffold(body: Center(child: Text('Provider profile editing is only available in provider flavor.')));
    }
    if (!widget.providerMode && flavor == AppFlavor.provider) {
      return const Scaffold(body: Center(child: Text('Customer profile editing is unavailable in provider flavor.')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back)),
        title: Text('Profile Edit', style: AppTypography.sectionTitle),
        centerTitle: true,
      ),
      body: FutureBuilder<ProfileSnapshot>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (snapshot.hasError || snapshot.data == null) {
            final message = snapshot.error is ApiException ? (snapshot.error! as ApiException).message : 'Unable to load profile.';
            return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(message)));
          }
          _bind(snapshot.data!);
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 43,
                    backgroundColor: const Color(0xFFE1E1E1),
                    child: Icon(Icons.person, color: Colors.white, size: 54),
                  ),
                ),
                const SizedBox(height: 18),
                _ReadOnlyField(label: 'Email', value: snapshot.data!.account.email),
                Row(
                  children: [
                    Expanded(child: _Field(label: 'First Name', controller: _firstName, validator: _required)),
                    const SizedBox(width: 10),
                    Expanded(child: _Field(label: 'Last Name', controller: _lastName)),
                  ],
                ),
                _Field(label: 'Mobile Number', controller: _phone, keyboardType: TextInputType.phone),
                _Field(label: 'Address Line 1', controller: _address1, maxLines: 2),
                _Field(label: 'Address Line 2', controller: _address2, maxLines: 2),
                Row(children: [
                  Expanded(child: _Field(label: 'City', controller: _city)),
                  const SizedBox(width: 10),
                  Expanded(child: _Field(label: 'State', controller: _state)),
                ]),
                _Field(label: 'Postal Code', controller: _postal),
                const SizedBox(height: 6),
                Text('Gender', style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
                Wrap(
                  spacing: 8,
                  children: [
                    _GenderChoice(label: 'Male', value: 'male', groupValue: _gender, onChanged: (v) => setState(() => _gender = v)),
                    _GenderChoice(label: 'Female', value: 'female', groupValue: _gender, onChanged: (v) => setState(() => _gender = v)),
                    _GenderChoice(label: 'Other', value: 'other', groupValue: _gender, onChanged: (v) => setState(() => _gender = v)),
                  ],
                ),
                Row(children: [
                  Expanded(child: _TapField(label: 'Date of Birth', controller: _dob, hint: 'YYYY-MM-DD', icon: Icons.calendar_today_outlined, onTap: _pickDate)),
                  const SizedBox(width: 10),
                  Expanded(child: _TapField(label: 'Birth Time', controller: _birthTime, hint: 'HH:MM', icon: Icons.access_time, onTap: _pickTime)),
                ]),
                if (widget.providerMode) ...[
                  const SizedBox(height: 18),
                  Text('Provider Details', style: AppTypography.sectionTitle),
                  const SizedBox(height: 8),
                  _ReadOnlyField(label: 'Provider Type', value: snapshot.data!.providerProfile?.providerType ?? ''),
                  _Field(label: 'Legal Name', controller: _providerLegalName, validator: _required),
                  _Field(label: 'Display Name', controller: _providerDisplayName),
                  _Field(label: 'Provider Mobile', controller: _providerPhone, keyboardType: TextInputType.phone),
                  _Field(label: 'Provider Address Line 1', controller: _providerAddress1, maxLines: 2),
                  _Field(label: 'Provider Address Line 2', controller: _providerAddress2, maxLines: 2),
                  Row(children: [
                    Expanded(child: _Field(label: 'Provider City', controller: _providerCity)),
                    const SizedBox(width: 10),
                    Expanded(child: _Field(label: 'Provider State', controller: _providerState)),
                  ]),
                  _Field(label: 'Provider Postal Code', controller: _providerPostal),
                ],
                if (_serverError != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(color: const Color(0xFFFFF1F2), borderRadius: BorderRadius.circular(8)),
                    child: Text(_serverError!, style: const TextStyle(color: Color(0xFFB42335), fontSize: 12)),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: _submitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _submitting
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Update'),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Profile photo upload is intentionally not faked here: the backend requires a public MediaAsset ID. Existing avatar media will continue to display when present.',
                  textAlign: TextAlign.center,
                  style: AppTypography.caption,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String? _required(String? value) => value == null || value.trim().isEmpty ? 'Required' : null;
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.controller, this.keyboardType, this.maxLines = 1, this.validator});
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE3E3E3))),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      initialValue: value,
      readOnly: true,
      decoration: InputDecoration(labelText: label, filled: true, fillColor: const Color(0xFFF5F5F5), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
    ),
  );
}

class _TapField extends StatelessWidget {
  const _TapField({required this.label, required this.controller, required this.hint, required this.icon, required this.onTap});
  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(labelText: label, hintText: hint, suffixIcon: Icon(icon, size: 18), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
    ),
  );
}

class _GenderChoice extends StatelessWidget {
  const _GenderChoice({required this.label, required this.value, required this.groupValue, required this.onChanged});
  final String label;
  final String value;
  final String? groupValue;
  final ValueChanged<String?> onChanged;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Radio<String>(value: value, groupValue: groupValue, onChanged: onChanged, visualDensity: VisualDensity.compact),
      Text(label, style: AppTypography.caption.copyWith(fontSize: 11)),
    ],
  );
}
