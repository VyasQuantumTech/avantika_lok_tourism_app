class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.code,
    this.details = const <ApiErrorDetail>[],
  });

  final String message;
  final int? statusCode;
  final String? code;
  final List<ApiErrorDetail> details;

  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, code: $code, message: $message)';
}

class ApiErrorDetail {
  const ApiErrorDetail({required this.field, required this.message});

  final String field;
  final String message;
}
