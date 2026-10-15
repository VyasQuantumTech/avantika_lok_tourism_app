import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:avantika_lok_tourism_app/core/ network/api_client.dart';
import 'package:avantika_lok_tourism_app/core/ network/endpoints.dart';
import 'package:avantika_lok_tourism_app/core/errors/exceptions.dart';
import 'package:avantika_lok_tourism_app/core/storage/secure_storage_service.dart';
import 'package:avantika_lok_tourism_app/core/services/notification_service.dart';
import 'package:avantika_lok_tourism_app/features/auth/data/repositories/verification_repository_impl.dart';

class _RealNetwork extends HttpOverrides {}

class _Notifications extends Fake implements NotificationService {
  @override
  Future<void> startSession() async {}
  @override
  Future<void> stopSession() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const base = String.fromEnvironment('AUTH_CONTRACT_BASE_URL');
  const email = String.fromEnvironment('AUTH_CONTRACT_EMAIL');
  test(
      'Dart transport exchanges real backend OTP/session envelopes for signup and existing super admin',
      () async {
    expect(base.startsWith('http://127.0.0.1:'), isTrue,
        reason: 'Run only against the isolated local Node contract fixture.');
    await HttpOverrides.runWithHttpOverrides(() async {
      FlutterSecureStorage.setMockInitialValues({});
      final storage = SecureStorageService(const FlutterSecureStorage());
      final client = http.Client();
      final api =
          ApiClient(baseUrl: base, client: client, secureStorage: storage);
      final repository =
          VerificationRepositoryImpl(api, storage, _Notifications());
      Future<String> receivedCode(String id) async {
        final response = await client.get(
            Uri.parse('$base/__fixture/code?challengeId=$id'),
            headers: {'x-isolated-test': 'local-contract-test-only'});
        expect(response.statusCode, 200);
        return (jsonDecode(response.body) as Map)['code'] as String;
      }

      try {
        final capability = await repository.capabilities();
        expect(capability['emailOtp'], isTrue);
        expect(capability['smsOtp'], isTrue);
        final registration = await repository.request(
            channel: 'email',
            identity: email,
            purpose: 'registration',
            firstName: 'Contract user');
        expect(await storage.hasSession(), isFalse);
        final registrationCode = await receivedCode(registration.id);
        await repository.verify(registration, registrationCode);
        expect(await storage.hasSession(), isTrue);
        final customer =
            (await api.get(Endpoints.me, authenticated: true))['data'] as Map;
        expect((customer['authorization'] as Map)['role']['name'], 'customer');
        expect(customer['user']['emailVerifiedAt'], isNotNull);
        await expectLater(
            repository.verify(registration, registrationCode),
            throwsA(isA<ApiException>()
                .having((e) => e.code, 'code', 'OTP_INVALID')));
        await storage.clearSession();
        final adminLogin = await repository.request(
            channel: 'sms', identity: '7405235056', purpose: 'login');
        final adminCode = await receivedCode(adminLogin.id);
        await repository.verify(adminLogin, adminCode);
        final admin =
            (await api.get(Endpoints.me, authenticated: true))['data'] as Map;
        expect((admin['authorization'] as Map)['role']['name'], 'super_admin');
        expect(admin['user']['mobile'], '7405235056',
            reason: 'Existing account storage is not rewritten.');
        expect(admin['user']['mobileVerifiedAt'], isNotNull);
        await api.post(Endpoints.logout,
            authenticated: true,
            body: {'refreshToken': await storage.readRefreshToken()});
        await expectLater(
            api.get(Endpoints.me, authenticated: true),
            throwsA(isA<ApiException>()
                .having((e) => e.statusCode, 'status', 401)));
      } finally {
        client.close();
      }
    }, _RealNetwork());
  });
}
