import '../../domain/entities/health_status.dart';

class HealthModel extends HealthStatus {
  const HealthModel({
    required super.status,
    super.service,
    super.timestamp,
    required super.raw,
  });

  factory HealthModel.fromJson(Map<String, dynamic> json) {
    final payload = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    return HealthModel(
      status: (payload['status'] ?? json['status'] ?? json['message'] ?? 'unknown')
          .toString(),
      service: (payload['service'] ?? json['service'])?.toString(),
      timestamp: (payload['timestamp'] ?? json['timestamp'])?.toString(),
      raw: Map<String, dynamic>.unmodifiable(json),
    );
  }
}
