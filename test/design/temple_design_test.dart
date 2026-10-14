import 'dart:io';
import 'dart:ui' as ui;

import 'package:avantika_lok_tourism_app/app/config/app_flavor.dart';
import 'package:avantika_lok_tourism_app/app/theme/app_theme.dart';
import 'package:avantika_lok_tourism_app/app/theme/app_theme_config.dart';
import 'package:avantika_lok_tourism_app/core/widgets/app_button.dart';
import 'package:avantika_lok_tourism_app/core/widgets/app_ui.dart';
import 'package:avantika_lok_tourism_app/core/widgets/temple_surface.dart';
import 'package:avantika_lok_tourism_app/features/auth/presentation/pages/login_page.dart';
import 'package:avantika_lok_tourism_app/features/auth/presentation/pages/register_page.dart';
import 'package:avantika_lok_tourism_app/features/profile/presentation/widgets/profile_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
// Use real local glyphs for offline visual checks, without font downloads.
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
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
  });

  for (final width in [320.0, 390.0]) {
    testWidgets(
        'auth forms fit $width wide screens and remain scrollable with keyboard',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 844);
      addTearDown(tester.view.reset);
      for (final page in [const LoginPage(), const RegisterPage()]) {
        await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: page));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        tester.view.viewInsets = const FakeViewPadding(bottom: 400);
        await tester.pumpAndSettle();
        await tester.drag(
            find.byType(SingleChildScrollView), const Offset(0, -600));
        await tester.pumpAndSettle();
        expect(find.byType(AppGradientButton).hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        tester.view.viewInsets = const FakeViewPadding();
        await tester.pumpWidget(const SizedBox());
      }
    });
  }

  testWidgets(
      'decorative surfaces preserve drawer, navigation, tabs and actions',
      (tester) async {
    var selected = 0;
    var pressed = 0;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: StatefulBuilder(
          builder: (context, setState) => TempleScaffold(
                drawer: const Drawer(child: Text('Drawer content')),
                appBar: AppBar(
                    title: const Text('Design check'),
                    flexibleSpace: const TempleAppBarBackground()),
                body: Center(
                    child: AppGradientButton(
                        label: 'Continue',
                        expand: false,
                        onPressed: () => pressed++)),
                bottomNavigationBar: TempleNavigationBar(
                  selectedIndex: selected,
                  onDestinationSelected: (index) =>
                      setState(() => selected = index),
                  destinations: const [
                    NavigationDestination(
                        icon: Icon(Icons.home_outlined), label: 'Home'),
                    NavigationDestination(
                        icon: Icon(Icons.person_outline), label: 'Profile'),
                  ],
                ),
              )),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    expect(pressed, 1);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(selected, 1);
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    expect(find.text('Drawer content'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('background covers system insets and nested tab headers',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 32);
    tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 32);
    addTearDown(tester.view.reset);
    var pressed = 0;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: TempleScaffold(
        body: TempleScaffold(
          appBar: AppBar(
            title: const Text('My Bookings'),
            flexibleSpace: const TempleAppBarBackground(),
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(48),
              child: SizedBox(height: 48, child: Text('Booking filters')),
            ),
          ),
          body: SafeArea(
            top: false,
            child: Center(
              child: TextButton(
                onPressed: () => pressed++,
                child: const Text('Open booking'),
              ),
            ),
          ),
        ),
        bottomNavigationBar: TempleNavigationBar(
          selectedIndex: 0,
          onDestinationSelected: (_) {},
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(
                icon: Icon(Icons.favorite), label: 'Favourite'),
          ],
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(TempleBackdrop), findsOneWidget);
    expect(tester.getRect(find.byType(TempleBackdrop)),
        const Rect.fromLTWH(0, 0, 390, 844));
    expect(AppTheme.light.appBarTheme.backgroundColor, Colors.transparent);
    expect(AppTheme.light.appBarTheme.systemOverlayStyle,
        TempleArt.systemOverlayStyle);
    expect(tester.getRect(find.byType(AppBar)).top, 0);
    expect(
        tester.getRect(find.text('My Bookings')).top, greaterThanOrEqualTo(24));
    expect(tester.getRect(find.text('Home')).bottom, lessThanOrEqualTo(812));
    await tester.tap(find.text('Open booking'));
    expect(pressed, 1);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byType(TempleBackdrop)),
        const Rect.fromLTWH(0, 0, 390, 844));
    expect(find.text('Open booking').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('render reference-aligned mobile previews', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    final previews = <String, Widget>{
      'signin': const LoginPage(),
      'register': const RegisterPage(),
      'profile': TempleScaffold(
          body: SafeArea(
              child: ListView(children: [
        ProfileHeader(
            name: 'Avantika Traveller',
            location: 'Ujjain, Madhya Pradesh',
            avatarUrl: null,
            onEdit: () {}),
        const Padding(
            padding: EdgeInsets.all(16),
            child: AppPanel(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Your pilgrimage, beautifully planned'),
                  SizedBox(height: 12),
                  AppDetailRow(
                      label: 'Destination',
                      value: 'Ujjain',
                      icon: Icons.temple_hindu),
                  AppDetailRow(
                      label: 'My bookings',
                      value: '3 upcoming',
                      icon: Icons.calendar_month),
                ]))),
      ]))),
      'details': AppPage(
          title: 'Temple details',
          child: ListView(children: [
            ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset('assets/images/destinations/ujjain.jpg',
                    height: 200, fit: BoxFit.cover)),
            const SizedBox(height: 16),
            const AppPanel(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Darshan information'),
                  SizedBox(height: 12),
                  AppDetailRow(
                      label: 'Location',
                      value: 'Ujjain',
                      icon: Icons.location_on_outlined),
                  AppDetailRow(
                      label: 'Dress code',
                      value: 'Traditional',
                      icon: Icons.check_circle_outline),
                ])),
            const SizedBox(height: 16),
            AppGradientButton(label: 'Book darshan', onPressed: () {}),
          ])),
    };
    for (final preview in previews.entries) {
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.light,
          home: RepaintBoundary(key: key, child: preview.value)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (Platform.environment['TEMPLE_PREVIEW_DIR']
          case final String directory) {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory(directory).create(recursive: true);
          await File('$directory/${preview.key}.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.pumpWidget(const SizedBox());
    }
  });
}
