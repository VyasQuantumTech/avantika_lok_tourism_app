import 'dart:io';
import 'package:avantika_lok_tourism_app/app/app.dart';
import 'package:avantika_lok_tourism_app/app/config/app_flavor.dart';
import 'package:avantika_lok_tourism_app/app/config/environment_config.dart';
import 'package:avantika_lok_tourism_app/app/di/injection.dart';
import 'package:avantika_lok_tourism_app/app/theme/app_theme_config.dart';
import 'package:avantika_lok_tourism_app/features/auth/domain/usecases/restore_session.dart';
import 'package:avantika_lok_tourism_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
// Google Fonts exposes these test hooks to avoid runtime font/network loads.
// ignore: implementation_imports
import 'package:google_fonts/src/google_fonts_base.dart' as font_testing;

class _FontAssets implements AssetManifest {
  @override
  List<String> listAssets() => [
        for (final family in ['DancingScript', 'Karma'])
          for (final variant in ['Regular', 'Medium', 'SemiBold', 'Bold'])
            '$family-$variant.ttf'
      ];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SignedOut extends RestoreSession {
  _SignedOut(super.repository);
  @override
  Future<bool> call() async => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    font_testing.assetManifest = _FontAssets();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMessageHandler('flutter/assets', (message) async {
      final key = const StringCodec().decodeMessage(message);
      if (key?.endsWith('.ttf') == true) return ByteData(0);
      if (key == null) return null;
      final file = File('build/unit_test_assets/$key');
      return file.existsSync()
          ? ByteData.sublistView(file.readAsBytesSync())
          : null;
    });
    messenger.setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers.global'), (_) async => null);
    messenger.setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers.global/events'),
        (_) async => null);
    messenger.setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers'), (call) async {
      if (call.method == 'create') {
        final id = (call.arguments as Map)['playerId'];
        messenger.setMockMethodCallHandler(
            MethodChannel('xyz.luan/audioplayers/events/$id'),
            (_) async => null);
      }
      return null;
    });
  });
  tearDown(() async {
    await getIt.reset();
  });
  for (final config in [
    EnvironmentConfig.userDevelopment,
    EnvironmentConfig.userProduction,
    EnvironmentConfig.providerDevelopment,
    EnvironmentConfig.providerProduction,
    EnvironmentConfig.adminDevelopment,
    EnvironmentConfig.adminProduction
  ]) {
    testWidgets(
        '${config.flavor.name} ${config.environment.name} preserves splash startup',
        (tester) async {
      await tester.runAsync(() => AppThemeConfig.load(config.flavor));
      await configureDependencies(config);
      await getIt.unregister<RestoreSession>();
      getIt.registerSingleton<RestoreSession>(
          _SignedOut(getIt<AuthRepository>()));
      await tester.pumpWidget(AvantikaLokApp(config: config));
      if (config.flavor == AppFlavor.admin) {
        expect(find.text('Avantika Lok'), findsOneWidget);
        expect(find.text('A Holy March'), findsOneWidget);
      } else {
        expect(
            find.byWidgetPredicate((widget) =>
                widget is Image &&
                widget.image is AssetImage &&
                (widget.image as AssetImage).assetName == config.logoAsset),
            findsOneWidget);
      }
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.takeException(), null);
    });
  }
}
