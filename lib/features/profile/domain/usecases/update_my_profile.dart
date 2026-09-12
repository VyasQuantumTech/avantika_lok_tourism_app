import '../entities/profile_snapshot.dart';
import '../repositories/profile_repository.dart';

class UpdateMyProfile {
  const UpdateMyProfile(this._repository);
  final ProfileRepository _repository;

  Future<ProfileSnapshot> call({required Map<String, dynamic> fields}) {
    return _repository.updateMyProfile(fields: fields);
  }
}
