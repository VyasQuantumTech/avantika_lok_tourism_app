import '../entities/health_status.dart';
import '../repositories/system_repository.dart';

class GetServiceHealth {
  const GetServiceHealth(this._repository);

  final SystemRepository _repository;

  Future<HealthStatus> call() => _repository.getHealth();
}
