import '../entities/home_dashboard.dart';

abstract class HomeRepository {
  Future<HomeDashboard> getDashboard();
}
