import '../repositories/provider_repository.dart';

class RegisterProvider {
  const RegisterProvider(this._repository);

  final ProviderRepository _repository;

  Future<void> call({
    required String providerType,
    required String legalName,
    required String displayName,
    required String phone,
    required String city,
    required String state,
    required String countryCode,
  }) {
    return _repository.registerCurrentUserAsProvider(
      providerType: providerType,
      legalName: legalName,
      displayName: displayName,
      phone: phone,
      city: city,
      state: state,
      countryCode: countryCode,
    );
  }
}
