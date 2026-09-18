class ProviderReview {
  const ProviderReview({
    required this.id,
    required this.rating,
    required this.createdAt,
    this.title,
    this.comment,
    this.bookingId,
    this.bookingNumber,
    this.serviceName,
    this.customerName,
    this.response,
    this.respondedAt,
  });

  final String id;
  final int rating;
  final DateTime? createdAt;
  final String? title;
  final String? comment;
  final String? bookingId;
  final String? bookingNumber;
  final String? serviceName;
  final String? customerName;
  final String? response;
  final DateTime? respondedAt;

  bool get hasResponse => response?.trim().isNotEmpty == true;
}
