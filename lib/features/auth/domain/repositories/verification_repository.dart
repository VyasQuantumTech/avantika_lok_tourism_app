import '../entities/verification_challenge.dart';

abstract class VerificationRepository {
  Future<VerificationChallenge> request(
      {required String channel,
      required String identity,
      required String purpose,
      String? firstName,
      String? lastName});
  Future<VerificationChallenge> resend(VerificationChallenge challenge);
  Future<void> cancel(VerificationChallenge challenge);
  Future<void> verify(VerificationChallenge challenge, String code,
      {bool confirm = false});
  Future<Map<String, dynamic>> capabilities();
  Future<VerificationChallenge?> restorePending();
  Future<void> logoutAll();
  Future<List<Map<String, dynamic>>> sessions();
  Future<List<Map<String, dynamic>>> socialIdentities();
  Future<void> unlink(String identityId);
  Future<void> social(String provider, {bool link = false});
}
