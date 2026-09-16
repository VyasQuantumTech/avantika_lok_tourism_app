class ProfileAccount {
  const ProfileAccount({
    required this.id,
    required this.email,
    required this.firstName,
    this.lastName,
    required this.status,
    this.emailVerifiedAt,
  });

  final String id;
  final String email;
  final String firstName;
  final String? lastName;
  final String status;
  final DateTime? emailVerifiedAt;

  String get fullName {
    final value = '$firstName ${lastName ?? ''}'.trim();
    return value.isEmpty ? email : value;
  }
}

class PersonalProfile {
  const PersonalProfile({
    this.phone,
    this.gender,
    this.dateOfBirth,
    this.birthTime,
    this.placeOfBirth,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.postalCode,
    this.countryCode = 'IN',
    this.avatarMediaAssetId,
    this.avatarUrl,
  });

  final String? phone;
  final String? gender;
  final String? dateOfBirth;
  final String? birthTime;
  final String? placeOfBirth;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? countryCode;
  final String? avatarMediaAssetId;
  final String? avatarUrl;

  String get locationText {
    return [city, state]
        .where((value) => value != null && value!.trim().isNotEmpty)
        .map((value) => value!.trim())
        .join(', ');
  }

  String get addressText {
    return [
      addressLine1,
      addressLine2,
      city,
      state,
      postalCode,
    ]
        .where((value) => value != null && value!.trim().isNotEmpty)
        .map((value) => value!.trim())
        .join(', ');
  }
}

class ProviderProfileInfo {
  const ProviderProfileInfo({
    required this.id,
    required this.providerType,
    required this.legalName,
    this.displayName,
    this.phone,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.postalCode,
    this.countryCode,
    this.kycApplicationId,
    required this.kycStatus,
  });

  final String id;
  final String providerType;
  final String legalName;
  final String? displayName;
  final String? phone;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? countryCode;
  final String? kycApplicationId;
  final String kycStatus;

  String get publicName {
    final display = displayName?.trim();
    return display == null || display.isEmpty ? legalName : display;
  }

  String get locationText {
    return [city, state]
        .where((value) => value != null && value!.trim().isNotEmpty)
        .map((value) => value!.trim())
        .join(', ');
  }
}

class ProfileSnapshot {
  const ProfileSnapshot({
    required this.account,
    this.personalProfile,
    required this.accountType,
    this.providerProfile,
  });

  final ProfileAccount account;
  final PersonalProfile? personalProfile;
  final String accountType;
  final ProviderProfileInfo? providerProfile;

  bool get isProvider =>
      accountType == 'provider' && providerProfile != null;
}