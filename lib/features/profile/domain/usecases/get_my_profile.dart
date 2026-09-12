import '../entities/profile_snapshot.dart';
import '../repositories/profile_repository.dart';

class GetMyProfile {
  const GetMyProfile(this._repository);
  final ProfileRepository _repository;
  Future<ProfileSnapshot> call() => _repository.getMyProfile();
}
