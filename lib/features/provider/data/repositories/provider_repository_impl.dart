import 'dart:typed_data';

import '../../domain/entities/provider_account_status.dart';
import '../../domain/entities/provider_kyc.dart';
import '../../domain/repositories/provider_repository.dart';
import '../datasources/provider_remote_data_source.dart';

class ProviderRepositoryImpl implements ProviderRepository {
  const ProviderRepositoryImpl(this._remoteDataSource);

  final ProviderRemoteDataSource _remoteDataSource;

  @override
  Future<ProviderAccountStatus> getCurrentUserProviderStatus() {
    return _remoteDataSource.getCurrentUserProviderStatus();
  }

  @override
  Future<ProviderKycSnapshot> getMyKyc() => _remoteDataSource.getMyKyc();

  @override
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
  }) => _remoteDataSource.addMyKycDocument(
        bytes: bytes,
        fileName: fileName,
        mimeType: mimeType,
        category: category,
        documentType: documentType,
        documentNumber: documentNumber,
        documentSide: documentSide,
        issuedAt: issuedAt,
        expiresAt: expiresAt,
      );

  @override
  Future<void> deleteMyKycDocument(String documentId) =>
      _remoteDataSource.deleteMyKycDocument(documentId);

  @override
  Future<void> submitMyKyc() => _remoteDataSource.submitMyKyc();

  @override
  Future<void> registerCurrentUserAsProvider({
    required String providerType,
    required String legalName,
    required String displayName,
    required String phone,
    required String city,
    required String state,
    required String countryCode,
  }) {
    return _remoteDataSource.registerCurrentUserAsProvider(
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
