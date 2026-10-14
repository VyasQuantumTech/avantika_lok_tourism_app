import '../../domain/entities/home_dashboard.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_data_source.dart';

class HomeRepositoryImpl implements HomeRepository {
  const HomeRepositoryImpl(this._remoteDataSource);

  final HomeRemoteDataSource _remoteDataSource;

  @override
  Future<HomeFeedPage> getSection(String type, int page) =>
      _remoteDataSource.getSection(type, page);

  @override
  Future<HomePackageDetail> getPackage(String id) =>
      _remoteDataSource.getPackage(id);

  @override
  Future<HomeDashboard> getDashboard() => _remoteDataSource.getDashboard();
}
