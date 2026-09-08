import '../../domain/entities/home_dashboard.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_local_data_source.dart';

class HomeRepositoryImpl implements HomeRepository {
  const HomeRepositoryImpl(this._localDataSource);

  final HomeLocalDataSource _localDataSource;

  @override
  Future<HomeDashboard> getDashboard() => _localDataSource.getDashboard();
}
