import '../entities/provider_account_status.dart';
import '../repositories/provider_repository.dart';

class CheckProviderStatus {
  const CheckProviderStatus(this._repository);

  final ProviderRepository _repository;

  Future<ProviderAccountStatus> call() {
    return _repository.getCurrentUserProviderStatus();
  }
}
