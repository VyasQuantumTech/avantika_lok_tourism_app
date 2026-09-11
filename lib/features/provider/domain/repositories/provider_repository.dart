import '../entities/provider_account_status.dart';

abstract class ProviderRepository {
  Future<ProviderAccountStatus> getCurrentUserProviderStatus();

  Future<void> registerCurrentUserAsProvider({
    required String providerType,
    required String legalName,
    required String displayName,
    required String phone,
    required String city,
    required String state,
    required String countryCode,
  });
}
