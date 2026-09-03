import '../../domain/entities/health_status.dart';
import '../../domain/repositories/system_repository.dart';
import '../datasources/system_remote_data_source.dart';

class SystemRepositoryImpl implements SystemRepository {
  SystemRepositoryImpl(this._remoteDataSource);

  final SystemRemoteDataSource _remoteDataSource;

  @override
  Future<HealthStatus> getHealth() => _remoteDataSource.getHealth();
}
