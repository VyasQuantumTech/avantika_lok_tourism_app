import 'dart:typed_data';

import '../entities/provider_account_status.dart';
import '../entities/provider_kyc.dart';

abstract class ProviderRepository {
  Future<ProviderAccountStatus> getCurrentUserProviderStatus();

  Future<ProviderKycSnapshot> getMyKyc();

  Future<void> addMyKycDocument({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required String category,
    required String documentType,
    String? documentNumber,
    String? documentSide,
    String? issuedAt,
    String? expiresAt,
  });

  Future<void> deleteMyKycDocument(String documentId);

  Future<void> submitMyKyc();

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
