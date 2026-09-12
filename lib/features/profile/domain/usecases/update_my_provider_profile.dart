import '../repositories/profile_repository.dart';

class UpdateMyProviderProfile {
  const UpdateMyProviderProfile(this._repository);
  final ProfileRepository _repository;

  Future<void> call({
    required String providerType,
    required String legalName,
    String? displayName,
    String? phone,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? postalCode,
    String countryCode = 'IN',
  }) {
    return _repository.updateMyProviderProfile(
      providerType: providerType,
      legalName: legalName,
      displayName: displayName,
      phone: phone,
      addressLine1: addressLine1,
      addressLine2: addressLine2,
      city: city,
      state: state,
      postalCode: postalCode,
      countryCode: countryCode,
    );
  }
}
