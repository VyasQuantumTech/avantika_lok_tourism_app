import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avantika_lok_tourism_app/app/di/injection.dart';
import 'package:avantika_lok_tourism_app/app/config/app_config.dart';
import 'package:avantika_lok_tourism_app/app/config/app_flavor.dart';
import 'package:avantika_lok_tourism_app/app/config/app_environment.dart';
import 'package:avantika_lok_tourism_app/app/router/route_names.dart';
import 'package:avantika_lok_tourism_app/core/errors/exceptions.dart';
import 'package:avantika_lok_tourism_app/features/auth/domain/entities/verification_challenge.dart';
import 'package:avantika_lok_tourism_app/features/auth/domain/repositories/verification_repository.dart';
import 'package:avantika_lok_tourism_app/features/auth/domain/usecases/verification_actions.dart';
import 'package:avantika_lok_tourism_app/features/auth/presentation/pages/otp_verification_page.dart';
import 'package:avantika_lok_tourism_app/features/auth/presentation/pages/login_page.dart';
import 'package:avantika_lok_tourism_app/features/auth/presentation/pages/register_page.dart';
import 'package:avantika_lok_tourism_app/features/auth/presentation/widgets/auth_channel_selector.dart';
import 'auth_test_fonts.dart';

VerificationChallenge challenge({bool cooldown = false}) =>
    VerificationChallenge(
        id: 'challenge',
        channel: 'email',
        purpose: 'login',
        destination: 't***@example.test',
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
        resendAt: DateTime.now().add(Duration(seconds: cooldown ? 60 : -1)));

class FakeVerification implements VerificationRepository {
  int verified = 0, resent = 0, cancelled = 0;
  bool invalid = false;
  bool deliveryFails = false;
  Map<String, dynamic>? lastRequest;
  @override
  Future<VerificationChallenge> request({required String channel, required String identity, required String purpose, String? firstName, String? lastName}) async {
    lastRequest = {'channel': channel, 'identity': identity, 'purpose': purpose, if (firstName != null) 'firstName': firstName};
    if (deliveryFails) throw const ApiException('Email verification is temporarily unavailable.', statusCode: 503, code: 'VERIFICATION_UNAVAILABLE');
    return challenge();
  }
  @override
  Future<VerificationChallenge> resend(VerificationChallenge value) async {
    resent++;
    return challenge(cooldown: true);
  }

  @override
  Future<void> cancel(VerificationChallenge value) async {
    cancelled++;
  }

  @override
  Future<void> verify(VerificationChallenge value, String code,
      {bool confirm = false}) async {
    if (invalid) throw const ApiException('Invalid verification code.');
    verified++;
  }

  @override
  Future<Map<String, dynamic>> capabilities() async =>
      {'emailOtp': true, 'smsOtp': true, 'socialProviders': []};
  @override
  Future<void> social(String provider, {bool link = false}) async {}
  @override
  Future<VerificationChallenge?> restorePending() async => null;
  @override
  Future<void> logoutAll() async {}
  @override
  Future<List<Map<String, dynamic>>> sessions() async => [];
  @override
  Future<List<Map<String, dynamic>>> socialIdentities() async => [];
  @override
  Future<void> unlink(String identityId) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeVerification fake;
  setUp(() async {
    await configureAuthTestFonts();
    await getIt.reset();
    fake = FakeVerification();
    getIt.registerSingleton(VerificationActions(fake));
  });
  tearDown(() async {
    await getIt.reset();
  });
  Future<void> open(WidgetTester tester, VerificationChallenge row) async {
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                OtpVerificationPage(challenge: row))),
                    child: const Text('Open'))))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('OTP masks destination and enforces resend cooldown in the UI',
      (tester) async {
    await open(tester, challenge(cooldown: true));
    expect(find.textContaining('t***@example.test'), findsOneWidget);
    final resend = find.widgetWithText(TextButton, 'Resend in 59 seconds');
    final buttons = tester.widgetList<TextButton>(find.byType(TextButton));
    expect(buttons.any((button) => button.onPressed == null), isTrue);
    expect(resend.evaluate().length <= 1, isTrue);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('OTP shows invalid error and supports a successful retry',
      (tester) async {
    await open(tester, challenge());
    fake.invalid = true;
    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();
    expect(find.text('Invalid verification code.'), findsOneWidget);
    expect(fake.verified, 0);
    fake.invalid = false;
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();
    expect(fake.verified, 1);
    expect(find.text('Open'), findsOneWidget);
    expect(fake.cancelled, 0);
  });
  testWidgets(
      'resend replaces challenge and change destination cancels the latest one',
      (tester) async {
    await open(tester, challenge());
    await tester.tap(find.text('Resend code'));
    await tester.pumpAndSettle();
    expect(fake.resent, 1);
    await tester.tap(find.text('Change email / mobile'));
    await tester.pumpAndSettle();
    expect(fake.cancelled, 1);
  });
  for (final flavor in [AppFlavor.user, AppFlavor.provider]) {
    testWidgets('OTP login routes ${flavor.name} to its existing destination',
        (tester) async {
      getIt.registerSingleton(AppConfig(
          flavor: flavor,
          environment: AppEnvironment.development,
          appName: 'Test',
          baseUrl: 'https://example.test',
          logoAsset: ''));
      await tester.pumpWidget(MaterialApp(
          home: const LoginPage(),
          onGenerateRoute: (settings) => MaterialPageRoute(
              builder: (_) =>
                  Scaffold(body: Text('Finished: ${settings.name}')))));
      await tester.enterText(find.byType(TextFormField), 'test@example.test');
      await tester.tap(find.text('Send verification code'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '123456');
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();
      expect(
          find.text(
              'Finished: ${flavor == AppFlavor.provider ? RouteNames.providerGate : RouteNames.home}'),
          findsOneWidget);
    });
  }
  for (final width in [320.0, 390.0]) {
    for (final signup in [false, true]) {
      testWidgets('${signup ? 'signup' : 'login'} has one channel selector and fits mobile at $width', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 844);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(MaterialApp(home: signup ? const RegisterPage() : const LoginPage()));
        await tester.pumpAndSettle();
        expect(find.byType(AuthChannelSelector), findsOneWidget);
        expect(find.text('Password'), findsNothing);
        expect(find.textContaining('Confirm Password'), findsNothing);
        await tester.tap(find.byKey(const ValueKey('auth-channel-sms'))); await tester.pumpAndSettle();
        expect(find.byType(TextFormField), findsNWidgets(signup ? 3 : 1));
        final field = find.descendant(of: find.byKey(const ValueKey('auth-identity-sms')), matching: find.byType(TextFormField));
        await tester.enterText(field, '+91 98765 43210');
        await tester.tap(find.byKey(const ValueKey('auth-channel-email'))); await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('auth-channel-sms'))); await tester.pumpAndSettle();
        expect(find.text('+91 98765 43210'), findsOneWidget);
        expect(tester.takeException(), isNull);
        tester.view.viewInsets = const FakeViewPadding(bottom: 350);
        await tester.pumpAndSettle();
        await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -450)); await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
  testWidgets('signup requests verification without a password and opens code entry', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterPage())); await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Test');
    await tester.enterText(find.byType(TextFormField).at(2), 'test@example.test');
    await tester.ensureVisible(find.text('Create Account')); await tester.tap(find.text('Create Account')); await tester.pumpAndSettle();
    expect(fake.lastRequest, {'channel': 'email', 'identity': 'test@example.test', 'purpose': 'registration', 'firstName': 'Test'});
    expect(find.byType(OtpVerificationPage), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('missing delivery configuration shows an error and cannot bypass OTP', (tester) async {
    fake.deliveryFails = true;
    await tester.pumpWidget(const MaterialApp(home: LoginPage())); await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'test@example.test');
    await tester.tap(find.text('Send verification code')); await tester.pumpAndSettle();
    expect(find.text('Email verification is temporarily unavailable.'), findsOneWidget);
    expect(find.byType(OtpVerificationPage), findsNothing); expect(fake.verified, 0);
  });

}
