import '../../domain/entities/profile_dashboard.dart';
import '../../domain/entities/profile_snapshot.dart';

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return <String, dynamic>{};
}

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _double(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String? _string(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

bool _bool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value?.toString().toLowerCase();
  if (normalized == 'true' || normalized == '1') return true;
  if (normalized == 'false' || normalized == '0') return false;
  return fallback;
}

ProfileSnapshot parseProfileSnapshot(dynamic raw) {
  final map = _map(raw);
  final account = _map(map['account']);
  final personalRaw = map['personalProfile'];
  final providerRaw = map['providerProfile'];

  return ProfileSnapshot(
    account: ProfileAccount(
      id: _string(account['id']) ?? '',
      email: _string(account['email']) ?? '',
      firstName: _string(account['firstName']) ?? '',
      lastName: _string(account['lastName']),
      status: _string(account['status']) ?? '',
      emailVerifiedAt: DateTime.tryParse(_string(account['emailVerifiedAt']) ?? ''),
    ),
    personalProfile: personalRaw == null
        ? null
        : PersonalProfile(
            phone: _string(_map(personalRaw)['phone']),
            gender: _string(_map(personalRaw)['gender']),
            dateOfBirth: _string(_map(personalRaw)['dateOfBirth']),
            birthTime: _string(_map(personalRaw)['birthTime']),
            addressLine1: _string(_map(personalRaw)['addressLine1']),
            addressLine2: _string(_map(personalRaw)['addressLine2']),
            city: _string(_map(personalRaw)['city']),
            state: _string(_map(personalRaw)['state']),
            postalCode: _string(_map(personalRaw)['postalCode']),
            countryCode: _string(_map(personalRaw)['countryCode']) ?? 'IN',
            avatarMediaAssetId:
                _string(_map(personalRaw)['avatarMediaAssetId']),
            avatarUrl: _string(_map(personalRaw)['avatarUrl']),
          ),
    accountType: _string(map['accountType']) ?? 'customer',
    providerProfile: providerRaw == null
        ? null
        : ProviderProfileInfo(
            id: _string(_map(providerRaw)['id']) ?? '',
            providerType: _string(_map(providerRaw)['providerType']) ?? '',
            legalName: _string(_map(providerRaw)['legalName']) ?? '',
            displayName: _string(_map(providerRaw)['displayName']),
            phone: _string(_map(providerRaw)['phone']),
            addressLine1: _string(_map(providerRaw)['addressLine1']),
            addressLine2: _string(_map(providerRaw)['addressLine2']),
            city: _string(_map(providerRaw)['city']),
            state: _string(_map(providerRaw)['state']),
            postalCode: _string(_map(providerRaw)['postalCode']),
            countryCode: _string(_map(providerRaw)['countryCode']),
            kycApplicationId: _string(_map(_map(providerRaw)['kyc'])['applicationId']),
            kycStatus:
                _string(_map(_map(providerRaw)['kyc'])['status']) ?? 'not_submitted',
          ),
  );
}

ProfileDashboard parseProfileDashboard(dynamic raw) {
  final map = _map(raw);
  final customer = _map(map['customer']);
  final bookings = _map(customer['bookings']);
  final favorites = _map(customer['favorites']);
  final providerRaw = map['provider'];

  ProviderDashboardSummary? provider;
  if (providerRaw != null) {
    final p = _map(providerRaw);
    final providerBookings = _map(p['bookings']);
    final ratings = _map(p['ratings']);
    final financial = _map(p['financial']);
    final domain = _map(p['domain']);
    final vehicles = _map(domain['vehicles']);
    final accommodations = _map(domain['accommodations']);
    final packages = _map(domain['packages']);
    final rawCapabilities = p['capabilities'];

    provider = ProviderDashboardSummary(
      providerType: _string(p['providerType']) ?? '',
      capabilities: rawCapabilities is List
          ? rawCapabilities.map((item) => item.toString()).toList(growable: false)
          : const <String>[],
      kycStatus: _string(_map(p['kyc'])['status']) ?? 'not_submitted',
      kycApplicationId: _string(_map(p['kyc'])['applicationId']),
      totalBookings: _int(providerBookings['total']),
      upcomingBookings: _int(providerBookings['upcoming']),
      pendingActionBookings: _int(providerBookings['pendingAction']),
      completedBookings: _int(providerBookings['completed']),
      ratings: ProviderRatingSummary(
        count: _int(ratings['count']),
        averageRating: ratings['averageRating'] == null
            ? null
            : _double(ratings['averageRating']),
      ),
      financial: ProviderFinancialSummary(
        currency: _string(financial['currency']) ?? 'INR',
        grossCaptured: _double(financial['grossCaptured']),
        processedRefunds: _double(financial['processedRefunds']),
        netCollected: _double(financial['netCollected']),
        payoutBalance: financial['payoutBalance'] == null
            ? null
            : _double(financial['payoutBalance']),
        note: _string(financial['note']),
      ),
      domain: ProviderDomainSummary(
        configured: _bool(domain['configured'],
            fallback: _int(packages['total']) > 0),
        active: domain['active'] == null ? null : _bool(domain['active']),
        status: _string(domain['status']),
        offerings: _int(domain['offerings']),
        weeklyAvailabilityRules: _int(domain['weeklyAvailabilityRules']),
        vehicleTotal: _int(vehicles['total']),
        vehicleActive: _int(vehicles['active']),
        routes: _int(domain['routes']),
        futureAvailabilityRows: _int(domain['futureAvailabilityRows']),
        accommodationTotal: _int(accommodations['total']),
        accommodationActive: _int(accommodations['active']),
        units: _int(domain['units']),
        packageTotal: _int(packages['total']),
        packageActive: _int(packages['active']),
      ),
    );
  }

  return ProfileDashboard(
    identity: parseProfileSnapshot(map['identity']),
    customer: CustomerDashboardSummary(
      totalBookings: _int(bookings['total']),
      upcomingBookings: _int(bookings['upcoming']),
      completedBookings: _int(bookings['completed']),
      closedWithoutCompletion: _int(bookings['closedWithoutCompletion']),
      reviewsGiven: _int(customer['reviewsGiven']),
      totalFavorites: _int(favorites['total']),
      placeFavorites: _int(favorites['place']),
      accommodationFavorites: _int(favorites['accommodation']),
      transportFavorites: _int(favorites['transport']),
      poojaFavorites: _int(favorites['pooja']),
      packageFavorites: _int(favorites['package']),
    ),
    provider: provider,
  );
}
