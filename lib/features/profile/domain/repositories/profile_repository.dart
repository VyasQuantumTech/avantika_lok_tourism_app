import '../entities/profile_dashboard.dart';
import '../entities/profile_snapshot.dart';

abstract class ProfileRepository {
  Future<ProfileSnapshot> getMyProfile();
  Future<ProfileDashboard> getMyDashboard();

  Future<ProfileSnapshot> updateMyProfile({
    required Map<String, dynamic> fields,
  });

  Future<void> updateMyProviderProfile({
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
  });
}
