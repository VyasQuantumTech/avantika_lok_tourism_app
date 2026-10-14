import '../entities/home_dashboard.dart';
import '../repositories/home_repository.dart';

class GetHomeDashboard {
  const GetHomeDashboard(this._repository);

  final HomeRepository _repository;

  Future<HomeFeedPage> section(String type, int page) =>
      _repository.getSection(type, page);

  Future<HomePackageDetail> package(String id) => _repository.getPackage(id);

  Future<HomeDashboard> call() => _repository.getDashboard();
}
