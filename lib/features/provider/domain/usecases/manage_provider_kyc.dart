import 'dart:typed_data';

import '../entities/provider_kyc.dart';
import '../repositories/provider_repository.dart';

class ManageProviderKyc {
  const ManageProviderKyc(this._repository);

  final ProviderRepository _repository;

  Future<ProviderKycSnapshot> load() => _repository.getMyKyc();

  Future<void> addDocument({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required String category,
    required String documentType,
    String? documentNumber,
    String? documentSide,
    String? issuedAt,
    String? expiresAt,
  }) => _repository.addMyKycDocument(
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

  Future<void> deleteDocument(String documentId) =>
      _repository.deleteMyKycDocument(documentId);

  Future<void> submit() => _repository.submitMyKyc();
}
