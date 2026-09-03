class HealthStatus {
  const HealthStatus({
    required this.status,
    this.service,
    this.timestamp,
    required this.raw,
  });

  final String status;
  final String? service;
  final String? timestamp;
  final Map<String, dynamic> raw;
}
