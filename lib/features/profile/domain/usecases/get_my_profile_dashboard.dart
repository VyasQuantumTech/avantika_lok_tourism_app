import '../entities/profile_dashboard.dart';
import '../repositories/profile_repository.dart';

class GetMyProfileDashboard {
  const GetMyProfileDashboard(this._repository);
  final ProfileRepository _repository;
  Future<ProfileDashboard> call() => _repository.getMyDashboard();
}
