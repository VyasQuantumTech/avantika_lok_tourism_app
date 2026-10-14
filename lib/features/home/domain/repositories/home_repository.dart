import '../entities/home_dashboard.dart';

abstract class HomeRepository {
  Future<HomeDashboard> getDashboard();
  Future<HomePackageDetail> getPackage(String id);
  Future<HomeFeedPage> getSection(String type, int page);
}
