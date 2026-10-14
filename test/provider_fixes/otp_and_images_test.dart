import 'dart:async';
import 'package:avantika_lok_tourism_app/core/widgets/error_fallback.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:avantika_lok_tourism_app/app/config/app_flavor.dart';
import 'package:avantika_lok_tourism_app/app/di/injection.dart';
import 'package:avantika_lok_tourism_app/app/theme/app_theme_config.dart';
import 'package:avantika_lok_tourism_app/core/ network/api_client.dart';
import 'package:avantika_lok_tourism_app/core/storage/secure_storage_service.dart';
import 'package:avantika_lok_tourism_app/core/errors/exceptions.dart';
import 'package:avantika_lok_tourism_app/core/widgets/app_ui.dart';
import 'package:avantika_lok_tourism_app/core/widgets/provider_ui.dart';
import 'package:avantika_lok_tourism_app/features/marketplace/data/datasources/marketplace_remote_data_source.dart';
import 'package:avantika_lok_tourism_app/features/marketplace/data/repositories/marketplace_repository_impl.dart';
import 'package:avantika_lok_tourism_app/features/marketplace/domain/entities/marketplace_entities.dart';
import 'package:avantika_lok_tourism_app/features/marketplace/domain/usecases/marketplace_actions.dart';
import 'package:avantika_lok_tourism_app/features/marketplace/presentation/marketplace_pages.dart';
// ignore: implementation_imports
import 'package:google_fonts/src/google_fonts_base.dart' as fonts;

class _Fonts implements AssetManifest {
  @override
  List<String> listAssets() => [
        for (final name in ['Karma', 'DancingScript'])
          for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold'])
            '$name-$weight.ttf'
      ];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Storage extends SecureStorageService {
  _Storage() : super(const FlutterSecureStorage());
  @override
  Future<String?> readAccessToken() async => 'test-token';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    fonts.assetManifest = _Fonts();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
      final key = const StringCodec().decodeMessage(message);
      if (key?.endsWith('.ttf') == true) return ByteData(0);
      final file = File('build/unit_test_assets/$key');
      return file.existsSync()
          ? ByteData.sublistView(file.readAsBytesSync())
          : null;
    });
    await AppThemeConfig.load(AppFlavor.provider);
  });
  tearDown(() async => getIt.reset());
  testWidgets(
      'unexpected widget failures use a neutral fallback without exposing error details',
      (tester) async {
    final old = ErrorWidget.builder;
    addTearDown(() => ErrorWidget.builder = old);
    installAppErrorFallback();
    await tester.pumpWidget(MaterialApp(
        home: ErrorWidget.builder(FlutterErrorDetails(
            exception: Exception('internal stack and token details')))));
    expect(find.textContaining('Please reopen'), findsOneWidget);
    expect(find.textContaining('internal stack'), findsNothing);
    expect(tester.takeException(), isNull);
    ErrorWidget.builder = old;
  });
  testWidgets(
      'an in-flight OTP request cannot be double-submitted or dismissed',
      (tester) async {
    final response = Completer<void>();
    var requests = 0;
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () => AppDialogs.textInput(context,
                            title: 'Verify OTP',
                            label: 'OTP', onSubmit: (_) async {
                          requests++;
                          await response.future;
                        }),
                    child: const Text('Open'))))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(requests, 1);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Cancel'))
            .onPressed,
        isNull);
    response.complete();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
  for (final service in ['pooja', 'accommodation', 'transport']) {
    testWidgets(
        '$service OTP validates, keeps backend errors inline and closes without a disposed-controller error',
        (tester) async {
      var calls = 0;
      await tester.pumpWidget(MaterialApp(
          home: Builder(
              builder: (context) => Scaffold(
                  body: TextButton(
                      onPressed: () => AppDialogs.textInput(context,
                          title: 'Start $service',
                          label: 'OTP',
                          maxLength: 6,
                          keyboardType: TextInputType.number,
                          validator: (v) => RegExp(r'^\d{6}$').hasMatch(v)
                              ? null
                              : 'Enter exactly 6 digits.',
                          onSubmit: (v) async {
                            calls++;
                            if (v != '123456') {
                              throw const ApiException(
                                  'Incorrect verification code. Please retry.',
                                  code: 'INVALID_SERVICE_START_OTP');
                            }
                          }),
                      child: const Text('Open OTP'))))));
      await tester.tap(find.text('Open OTP'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '123');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(calls, 0);
      expect(find.text('Enter exactly 6 digits.'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '111111');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(find.text('Incorrect verification code. Please retry.'),
          findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.enterText(find.byType(TextField), '123456');
      await tester.tap(find.text('Continue'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(ErrorWidget), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Open OTP'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(tester.takeException(), isNull);
    });
  }
  for (final type in [
    MarketplaceType.transport,
    MarketplaceType.accommodation
  ]) {
    testWidgets(
        '${type.name} provider orders display images and complete the OTP action without driver assignment',
        (tester) async {
      var started = false;
      final paths = <String>[];
      final client = ApiClient(
          baseUrl: 'https://backend.test',
          client: MockClient((request) async {
            paths.add(request.url.path);
            final booking = {
              'id': 'booking-1',
              'bookingNumber': 'AV-1',
              'bookingType': type.name,
              'status': 'confirmed',
              'providerDecision': 'accepted',
              'serviceDate': '2030-10-12',
              'totalAmount': 250,
              'currency': 'INR',
              'serviceStartedAt': started ? '2030-10-12T08:00:00Z' : null,
              'serviceSummary': {
                'name': 'Service name',
                'coverImageUrl': '/api/v1/media/photo/content'
              }
            };
            if (request.method == 'POST') {
              started = true;
              booking['serviceStartedAt'] = '2030-10-12T08:00:00Z';
              return http.Response(
                  jsonEncode({
                    'data': {'booking': booking}
                  }),
                  200);
            }
            return http.Response(
                jsonEncode({
                  'data': {
                    'items': [booking],
                    'pagination': {'totalPages': 1}
                  }
                }),
                200);
          }),
          secureStorage: _Storage());
      getIt.registerSingleton(MarketplaceActions(
          MarketplaceRepositoryImpl(MarketplaceRemoteDataSourceImpl(client))));
      await tester.pumpWidget(
          MaterialApp(home: ProviderMarketplaceBookingsPage(type: type)));
      await tester.pumpAndSettle();
      expect(find.text('Assign driver'), findsNothing);
      expect(find.byTooltip('Drivers & devices'), findsNothing);
      expect(
          tester
              .widget<ProviderMediaThumb>(find.byType(ProviderMediaThumb))
              .imageUrl,
          'https://backend.test/api/v1/media/photo/content');
      await tester.tap(find.text(
          type == MarketplaceType.transport ? 'Start trip' : 'Start stay'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '123456');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(started, true);
      expect(paths,
          contains('/api/v1/provider/bookings/booking-1/${type.name}/start'));
      expect(
          paths.any((path) =>
              path.contains('assignment') || path.contains('/drivers')),
          false);
      expect(find.byType(ErrorWidget), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
