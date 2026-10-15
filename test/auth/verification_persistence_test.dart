import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:avantika_lok_tourism_app/core/ network/api_client.dart';
import 'package:avantika_lok_tourism_app/core/storage/secure_storage_service.dart';
import 'package:avantika_lok_tourism_app/core/services/notification_service.dart';
import 'package:avantika_lok_tourism_app/features/auth/data/repositories/verification_repository_impl.dart';

class NotificationsFake extends Fake implements NotificationService {
  @override
  Future<void> startSession() async {}
  @override
  Future<void> stopSession() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SecureStorageService storage;
  late VerificationRepositoryImpl repository;
  final challengeData = <String, dynamic>{
    'challengeId': 'first',
    'channel': 'email',
    'purpose': 'login',
    'maskedDestination': 't***@example.test',
    'expiresAt':
        DateTime.now().add(const Duration(minutes: 5)).toIso8601String(),
    'resendAt': DateTime.now().toIso8601String()
  };
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    storage = SecureStorageService(const FlutterSecureStorage());
    final client = MockClient((request) async {
      expect(request.url.host, 'example.test');
      expect(
          request.url.path,
          isIn([
            '/api/v1/auth/otp/request',
            '/api/v1/auth/otp/resend',
            '/api/v1/auth/otp/verify',
            '/api/v1/auth/otp/cancel'
          ]));
      final body = request.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(request.body) as Map<String, dynamic>;
      if (request.url.path.endsWith('/resend')) {
        return http.Response(
            jsonEncode({
              'success': true,
              'data': {...challengeData, 'challengeId': 'second'}
            }),
            200);
      }
      if (request.url.path.endsWith('/verify')) {
        expect(body['otp'], '654321');
        return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'user': {
                  'id': 'user',
                  'email': 'test@example.test',
                  'firstName': 'Test'
                },
                'tokens': {'accessToken': 'access', 'refreshToken': 'refresh'}
              }
            }),
            200);
      }
      if (request.url.path.endsWith('/cancel')) {
        return http.Response('{"success":true,"data":{}}', 200);
      }
      return http.Response(
          jsonEncode({'success': true, 'data': challengeData}), 200);
    });
    repository = VerificationRepositoryImpl(
        ApiClient(
            baseUrl: 'https://example.test',
            client: client,
            secureStorage: storage),
        storage,
        NotificationsFake());
  });
  test('pending challenge restores with only masked public metadata', () async {
    await repository.request(
        channel: 'email', identity: 'test@example.test', purpose: 'login');
    final resumed = await repository.restorePending();
    expect(resumed?.id, 'first');
    expect(resumed?.destination, 't***@example.test');
    final stored = await storage.readPendingVerification();
    expect(stored!.keys, isNot(contains('otp')));
    expect(stored.keys, isNot(contains('identity')));
  });
  test('resend replaces saved reference and cancellation removes it', () async {
    final first = await repository.request(
        channel: 'email', identity: 'test@example.test', purpose: 'login');
    final second = await repository.resend(first);
    expect((await repository.restorePending())?.id, 'second');
    await storage.clearPendingVerification(first.id);
    expect((await repository.restorePending())?.id, 'second');
    await repository.cancel(second);
    expect(await repository.restorePending(), isNull);
  });
  test('verification stores existing token pair and clears pending challenge',
      () async {
    final row = await repository.request(
        channel: 'email', identity: 'test@example.test', purpose: 'login');
    await repository.verify(row, '654321');
    expect(await storage.hasSession(), isTrue);
    expect(await storage.readAccessToken(), 'access');
    expect(await storage.readRefreshToken(), 'refresh');
    expect(await repository.restorePending(), isNull);
  });
  test(
      'corrupt pending metadata does not alter an existing authenticated session',
      () async {
    await storage.saveTokens(
        accessToken: 'existing-access', refreshToken: 'existing-refresh');
    await const FlutterSecureStorage()
        .write(key: 'pending_auth_verification', value: 'broken-json');
    expect(await repository.restorePending(), isNull);
    expect(await storage.hasSession(), isTrue);
    expect(await storage.readAccessToken(), 'existing-access');
  });
}
