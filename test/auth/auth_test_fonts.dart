import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avantika_lok_tourism_app/app/theme/app_theme_config.dart';
import 'package:avantika_lok_tourism_app/app/config/app_flavor.dart';
// ignore: implementation_imports
import 'package:google_fonts/src/google_fonts_base.dart' as fonts;
class _FontAssets implements AssetManifest {
  @override
  List<String> listAssets() => [
        for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold'])
          'Roboto-$weight.ttf',
      ];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> configureAuthTestFonts() async {
    fonts.assetManifest = _FontAssets();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
      final key = const StringCodec().decodeMessage(message);
      if (key == null) return null;
      if (key.startsWith('Roboto-') && key.endsWith('.ttf')) {
        final font = File('/System/Library/Fonts/Supplemental/Arial.ttf');
        return font.existsSync()
            ? ByteData.sublistView(font.readAsBytesSync())
            : ByteData(0);
      }
      final file = File('build/unit_test_assets/$key');
      return file.existsSync()
          ? ByteData.sublistView(file.readAsBytesSync())
          : null;
    });
    final icons =
        File('build/unit_test_assets/fonts/MaterialIcons-Regular.otf');
    if (icons.existsSync()) {
      final loader = FontLoader('MaterialIcons');
      loader
          .addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
      await loader.load();
    }
    await AppThemeConfig.load(AppFlavor.user);

}
