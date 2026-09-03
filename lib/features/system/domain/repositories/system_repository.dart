import '../entities/health_status.dart';

abstract class SystemRepository {
  Future<HealthStatus> getHealth();
}
