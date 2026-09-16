class ProviderKycSnapshot {
  const ProviderKycSnapshot({
    required this.providerType,
    required this.status,
    required this.complete,
    required this.requirements,
    required this.documents,
    this.applicationId,
    this.reviewReason,
  });

  final String providerType;
  final String status;
  final bool complete;
  final String? applicationId;
  final String? reviewReason;
  final List<ProviderKycRequirement> requirements;
  final List<ProviderKycDocument> documents;

  bool get canEdit => status == 'not_submitted' || status == 'resubmission_required';
  bool get canSubmit => canEdit && complete;
  bool get isApproved => status == 'approved';
  bool get isInReview => status == 'pending' || status == 'under_review';
}

class ProviderKycRequirement {
  const ProviderKycRequirement({
    required this.key,
    required this.category,
    required this.required,
    required this.minimumDocuments,
    required this.acceptedTypes,
    required this.matchingDocumentCount,
    required this.satisfied,
  });

  final String key;
  final String category;
  final bool required;
  final int minimumDocuments;
  final List<String> acceptedTypes;
  final int matchingDocumentCount;
  final bool satisfied;
}

class ProviderKycDocument {
  const ProviderKycDocument({
    required this.id,
    required this.category,
    required this.documentType,
    required this.fileRegistered,
    this.documentNumberLast4,
    this.originalFileName,
    this.mimeType,
    this.documentSide,
    this.issuedAt,
    this.expiresAt,
  });

  final String id;
  final String category;
  final String documentType;
  final bool fileRegistered;
  final String? documentNumberLast4;
  final String? originalFileName;
  final String? mimeType;
  final String? documentSide;
  final String? issuedAt;
  final String? expiresAt;
}
