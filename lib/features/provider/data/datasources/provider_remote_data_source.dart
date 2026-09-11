import '../../../../core/ network/api_client.dart';
import '../../../../core/ network/endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/provider_account_status.dart';

abstract class ProviderRemoteDataSource {
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

class ProviderRemoteDataSourceImpl implements ProviderRemoteDataSource {
  const ProviderRemoteDataSourceImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<ProviderAccountStatus> getCurrentUserProviderStatus() async {
    Map<String, dynamic> response;

    try {
      response = await _apiClient.get(
        Endpoints.providerStatus,
        authenticated: true,
      );
    } on ApiException catch (error) {
      if (_meansProviderProfileMissing(error)) {
        return const ProviderAccountStatus(isProvider: false);
      }
      rethrow;
    }

    final responseData = _asMap(response['data']);
    final data = responseData.isNotEmpty ? responseData : response;

    // The backend response has evolved over time. Some versions return the
    // provider profile directly, while others wrap it under provider/profile
    // or another nested object. Read the known wrappers first, then scan the
    // complete response recursively so a valid providerType never becomes
    // "unknown" just because the JSON nesting changed.
    final nestedProvider = _asMap(
      data['providerProfile'] ??
          data['provider_profile'] ??
          data['provider'] ??
          data['profile'],
    );

    final providerType = _normalizeProviderType(
      _firstString(
            nestedProvider,
            const <String>[
              'providerType',
              'provider_type',
              'type',
              'serviceType',
              'service_type',
              'category',
            ],
          ) ??
          _firstString(
            data,
            const <String>[
              'providerType',
              'provider_type',
              'type',
              'serviceType',
              'service_type',
              'category',
            ],
          ) ??
          _findStringRecursively(
            response,
            const <String>{
              'providerType',
              'provider_type',
              'serviceType',
              'service_type',
              'providerCategory',
              'provider_category',
            },
          ),
    );

    final explicit = _firstBoolean(
      data,
      const <String>[
        'isProvider',
        'is_provider',
        'isRegistered',
        'is_registered',
        'registered',
        'exists',
        'providerExists',
        'provider_exists',
        'hasProvider',
        'has_provider',
        'hasProviderProfile',
        'has_provider_profile',
        'providerProfileExists',
        'provider_profile_exists',
        'providerRegistered',
        'provider_registered',
      ],
    );

    final nestedExplicit = _firstBoolean(
      nestedProvider,
      const <String>[
        'isProvider',
        'is_provider',
        'isRegistered',
        'is_registered',
        'registered',
        'exists',
        'providerExists',
        'provider_exists',
        'hasProviderProfile',
        'has_provider_profile',
      ],
    );

    final status = _firstString(
      data,
      const <String>[
        'providerStatus',
        'provider_status',
        'registrationStatus',
        'registration_status',
        'profileStatus',
        'profile_status',
        'status',
      ],
    );

    final nestedStatus = _firstString(
      nestedProvider,
      const <String>[
        'providerStatus',
        'provider_status',
        'registrationStatus',
        'registration_status',
        'profileStatus',
        'profile_status',
        'status',
      ],
    );

    final explicitDecision = explicit ?? nestedExplicit;
    if (explicitDecision != null) {
      return ProviderAccountStatus(
        isProvider: explicitDecision,
        providerType: explicitDecision ? providerType : null,
      );
    }

    final statusDecision =
        _providerStatusDecision(status) ?? _providerStatusDecision(nestedStatus);
    if (statusDecision != null) {
      return ProviderAccountStatus(
        isProvider: statusDecision,
        providerType: statusDecision ? providerType : null,
      );
    }

    final hasIdentity = _hasNonEmptyValue(
          nestedProvider,
          const <String>[
            'id',
            'providerProfileId',
            'provider_profile_id',
            'providerType',
            'provider_type',
            'legalName',
            'legal_name',
            'userId',
            'user_id',
          ],
        ) ||
        _hasNonEmptyValue(
          data,
          const <String>[
            'providerProfileId',
            'provider_profile_id',
            'providerId',
            'provider_id',
            'providerType',
            'provider_type',
          ],
        ) ||
        providerType != null;

    return ProviderAccountStatus(
      isProvider: hasIdentity,
      providerType: hasIdentity ? providerType : null,
    );
  }

  @override
  Future<void> registerCurrentUserAsProvider({
    required String providerType,
    required String legalName,
    required String displayName,
    required String phone,
    required String city,
    required String state,
    required String countryCode,
  }) async {
    await _apiClient.put(
      Endpoints.providerMe,
      authenticated: true,
      body: <String, dynamic>{
        'providerType': providerType.trim(),
        'legalName': legalName.trim(),
        'displayName': displayName.trim(),
        'phone': phone.trim(),
        'city': city.trim(),
        'state': state.trim(),
        'countryCode': countryCode.trim().toUpperCase(),
      },
    );
  }

  bool _meansProviderProfileMissing(ApiException error) {
    if (error.statusCode == 404) return true;

    final code = error.code?.trim().toUpperCase() ?? '';
    if (code.isEmpty) return false;

    return code == 'PROVIDER_NOT_FOUND' ||
        code == 'PROVIDER_PROFILE_NOT_FOUND' ||
        code == 'PROVIDER_PROFILE_MISSING' ||
        code == 'PROVIDER_NOT_REGISTERED' ||
        code == 'NOT_A_PROVIDER';
  }

  bool? _providerStatusDecision(String? rawStatus) {
    if (rawStatus == null) return null;

    final status = rawStatus.trim().toLowerCase();
    if (status.isEmpty) return null;

    const notRegisteredStatuses = <String>{
      'not_registered',
      'not registered',
      'unregistered',
      'not_provider',
      'not provider',
      'missing',
      'not_found',
      'not found',
      'none',
      'new',
      'absent',
    };

    if (notRegisteredStatuses.contains(status)) {
      return false;
    }

    // KYC/account approval is separate from the existence of a provider
    // profile. Any of these states means provider registration already exists.
    const registeredStatuses = <String>{
      'registered',
      'created',
      'draft',
      'pending',
      'submitted',
      'under_review',
      'under review',
      'approved',
      'active',
      'inactive',
      'rejected',
      'suspended',
      'resubmission_required',
      'resubmission required',
    };

    if (registeredStatuses.contains(status)) {
      return true;
    }

    return null;
  }

  bool? _firstBoolean(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = map[key];
      if (value is bool) return value;

      if (value is num) {
        if (value == 1) return true;
        if (value == 0) return false;
      }

      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
          return true;
        }
        if (normalized == 'false' ||
            normalized == '0' ||
            normalized == 'no') {
          return false;
        }
      }
    }
    return null;
  }

  String? _firstString(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  String? _findStringRecursively(
    dynamic value,
    Set<String> wantedKeys,
  ) {
    if (value is Map) {
      for (final entry in value.entries) {
        final key = entry.key.toString();
        final item = entry.value;

        if (wantedKeys.contains(key) &&
            item is String &&
            item.trim().isNotEmpty) {
          return item;
        }
      }

      for (final item in value.values) {
        final found = _findStringRecursively(item, wantedKeys);
        if (found != null) return found;
      }
    }

    if (value is List) {
      for (final item in value) {
        final found = _findStringRecursively(item, wantedKeys);
        if (found != null) return found;
      }
    }

    return null;
  }

  bool _hasNonEmptyValue(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;

      if (value is String) {
        if (value.trim().isNotEmpty) return true;
        continue;
      }

      return true;
    }
    return false;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return <String, dynamic>{};
  }

  String? _normalizeProviderType(String? value) {
    if (value == null) return null;

    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');

    if (normalized.isEmpty) return null;

    switch (normalized) {
      case 'pandit':
      case 'priest':
      case 'pujari':
        return 'pandit';

      case 'hotel_manager':
      case 'hotel':
      case 'accommodation':
      case 'accommodation_provider':
      case 'accommodation_owner':
      case 'hotel_owner':
        return 'hotel_manager';

      case 'vehicle_owner':
      case 'transport':
      case 'transport_provider':
      case 'transport_owner':
      case 'vehicle':
      case 'cab':
      case 'taxi':
        return 'vehicle_owner';

      default:
        return normalized;
    }
  }
}
