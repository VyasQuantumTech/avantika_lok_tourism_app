import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:avantika_lok_tourism_app/app/di/injection.dart';
import 'package:avantika_lok_tourism_app/app/config/app_config.dart';
import 'package:avantika_lok_tourism_app/app/config/app_flavor.dart';
import 'package:avantika_lok_tourism_app/app/config/app_environment.dart';
import 'package:avantika_lok_tourism_app/core/ network/api_client.dart';
import 'package:avantika_lok_tourism_app/core/storage/secure_storage_service.dart';
import 'package:avantika_lok_tourism_app/core/services/notification_service.dart';
import 'package:avantika_lok_tourism_app/features/auth/data/repositories/verification_repository_impl.dart';
import 'package:avantika_lok_tourism_app/features/auth/domain/usecases/verification_actions.dart';
import 'package:avantika_lok_tourism_app/features/auth/presentation/pages/login_page.dart';
import 'package:avantika_lok_tourism_app/features/auth/presentation/pages/otp_verification_page.dart';
import 'auth_test_fonts.dart';

class _Notifications extends Fake implements NotificationService {
  @override
  Future<void> startSession() async {}
  @override
  Future<void> stopSession() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const reference = '10000000-0000-4000-8000-000000000001';
  late SecureStorageService storage;
  late VerificationRepositoryImpl repository;
  late List<String> calls;
  late Map<String, dynamic> lastRequest;
  Map<String, dynamic> challenge() => {
        'challengeId': reference,
        'channel': lastRequest['channel'] ?? 'email',
        'purpose': 'login',
        'maskedDestination': lastRequest['channel'] == 'sms'
            ? '******5056'
            : 't***@example.test',
        'expiresAt':
            DateTime.now().add(const Duration(minutes: 5)).toIso8601String(),
        'resendAt': DateTime.now()
            .subtract(const Duration(seconds: 1))
            .toIso8601String()
      };
  setUp(() async {
    await getIt.reset();
    await configureAuthTestFonts();
    FlutterSecureStorage.setMockInitialValues({});
    storage = SecureStorageService(const FlutterSecureStorage());
    calls = [];
    lastRequest = {};
    final client = MockClient((request) async {
      calls.add('${request.method} ${request.url.path}');
      expect(request.url.origin, 'https://api-dev.tirthsangam.com');
      final input = request.body.isEmpty
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(jsonDecode(request.body) as Map);
      Object data;
      switch ('${request.method} ${request.url.path}') {
        case 'GET /api/v1/auth/capabilities':
          data = {'emailOtp': true, 'smsOtp': true};
          break;
        case 'POST /api/v1/auth/otp/request':
          lastRequest = input;
          expect(input.containsKey('password'), isFalse);
          if (input['channel'] == 'sms') {
            expect(input['identity'], '+917405235056');
          }
          data = challenge();
          break;
        case 'POST /api/v1/auth/otp/resend':
          data = challenge();
          break;
        case 'POST /api/v1/auth/otp/cancel':
          data = {};
          break;
        case 'POST /api/v1/auth/otp/verify':
          expect(input['challengeId'], reference);
          expect(input['otp'], '654321');
          expect(input['purpose'], 'login');
          data = {
            'user': {
              'id': 'existing-user',
              'email': 'test@example.test',
              'firstName': 'Test'
            },
            'tokens': {
              'accessToken': 'test-access',
              'refreshToken': 'test-refresh'
            }
          };
          break;
        case 'GET /api/v1/auth/sessions':
        case 'GET /api/v1/auth/social':
          data = {'items': []};
          break;
        case 'DELETE /api/v1/auth/social/test-link':
        case 'POST /api/v1/auth/logout-all':
          data = {};
          break;
        default:
          return http.Response(
              jsonEncode({
                'success': false,
                'error': {
                  'code': 'NOT_FOUND',
                  'message':
                      'Route ${request.method} ${request.url.path} not found'
                }
              }),
              404);
      }
      return http.Response(jsonEncode({'success': true, 'data': data}), 200);
    });
    // Host-only base URL is the real app contract. Every endpoint owns /api/v1.
    repository = VerificationRepositoryImpl(
        ApiClient(
            baseUrl: 'https://api-dev.tirthsangam.com',
            client: client,
            secureStorage: storage),
        storage,
        _Notifications());
    getIt.registerSingleton(VerificationActions(repository));
  });
  tearDown(() async {
    await getIt.reset();
  });
  for (final flavor in [AppFlavor.user, AppFlavor.provider]) {
    for (final channel in ['email', 'sms']) {
      testWidgets(
          'real repository opens OTP and authenticates $channel in ${flavor.name} with host-only URL',
          (tester) async {
        getIt.registerSingleton(AppConfig(
            flavor: flavor,
            environment: AppEnvironment.development,
            appName: 'Test',
            baseUrl: 'https://api-dev.tirthsangam.com',
            logoAsset: ''));
        await tester.pumpWidget(MaterialApp(
            home: const LoginPage(),
            onGenerateRoute: (_) => MaterialPageRoute(
                builder: (_) =>
                    const Scaffold(body: Text('Authenticated destination')))));
        await tester.pumpAndSettle();
        if (channel == 'sms') {
          await tester.tap(find.byKey(const ValueKey('auth-channel-sms')));
          await tester.pumpAndSettle();
        }
        await tester.enterText(find.byType(TextFormField),
            channel == 'sms' ? '7405235056' : 'test@example.test');
        await tester.tap(find.text('Send verification code'));
        await tester.pumpAndSettle();
        expect(find.byType(OtpVerificationPage), findsOneWidget);
        expect(lastRequest['channel'], channel);
        expect(lastRequest['purpose'], 'login');
        await tester.enterText(find.byType(TextField), '654321');
        await tester.tap(find.text('Verify'));
        await tester.pumpAndSettle();
        expect(find.text('Authenticated destination'), findsOneWidget);
        expect(await storage.hasSession(), isTrue);
        expect(calls,
            ['POST /api/v1/auth/otp/request', 'POST /api/v1/auth/otp/verify']);
      });
    }
  }
  test('every account-security operation uses the mounted versioned API',
      () async {
    await repository.capabilities();
    final row = await repository.request(
        channel: 'sms', identity: '7405235056', purpose: 'login');
    await repository.resend(row);
    await repository.cancel(row);
    await storage.saveTokens(
        accessToken: 'test-access', refreshToken: 'test-refresh');
    await repository.sessions();
    await repository.socialIdentities();
    await repository.unlink('test-link');
    await repository.logoutAll();
    expect(calls, [
      'GET /api/v1/auth/capabilities',
      'POST /api/v1/auth/otp/request',
      'POST /api/v1/auth/otp/resend',
      'POST /api/v1/auth/otp/cancel',
      'GET /api/v1/auth/sessions',
      'GET /api/v1/auth/social',
      'DELETE /api/v1/auth/social/test-link',
      'POST /api/v1/auth/logout-all'
    ]);
  });
}
