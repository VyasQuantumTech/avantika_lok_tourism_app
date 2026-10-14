import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avantika_lok_tourism_app/app/di/injection.dart';
import 'package:avantika_lok_tourism_app/features/explore/domain/entities/tourism_place.dart';
import 'package:avantika_lok_tourism_app/features/explore/domain/repositories/tourism_repository.dart';
import 'package:avantika_lok_tourism_app/features/explore/domain/usecases/get_tourism_place_detail.dart';
import 'package:avantika_lok_tourism_app/features/explore/presentation/pages/explore_detail_page.dart';
import 'package:avantika_lok_tourism_app/features/explore/presentation/pages/image_gallery_page.dart';
import 'package:avantika_lok_tourism_app/features/explore/presentation/pages/video_gallery_page.dart';
import 'package:avantika_lok_tourism_app/features/explore/presentation/widgets/youtube_media.dart';
// Match the repository's offline font setup.
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

TourismPlace place({int images = 3, bool video = true}) => TourismPlace(
      id: '1',
      name: 'Temple',
      slug: 'temple',
      shortDescription: '',
      description: '',
      locationLabel: '',
      address: '',
      latitude: null,
      longitude: null,
      categories: [],
      images: List.generate(
          images,
          (i) => TourismImage(
              url: 'https://example.com/$i.jpg',
              thumbnailUrl: '',
              altText: 'Image $i',
              caption: '',
              isPrimary: i == 0)),
      externalMedia: video
          ? [
              const TourismExternalMedia(
                  type: 'youtube',
                  title: 'Temple video',
                  url: 'invalid',
                  thumbnailUrl: '',
                  description: '')
            ]
          : [],
      stories: [
        const TourismStory(title: 'Hidden story', content: 'Story content')
      ],
      detailSections: [],
      visitorInfo: {},
    );

class _Repository implements TourismRepository {
  _Repository(this.value);
  final TourismPlace value;
  @override
  Future<List<TourismPlace>> getPlaces() async => [value];
  @override
  Future<TourismPlace> getPlaceDetail(
          {required String id, required String slug}) async =>
      value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawColor(Colors.orange, BlendMode.src);
    final image = await recorder.endRecording().toImage(2, 2);
    for (var i = 0; i < 3; i++) {
      PaintingBinding.instance.imageCache.putIfAbsent(
        NetworkImage('https://example.com/$i.jpg'),
        () => OneFrameImageStreamCompleter(
            Future.value(ImageInfo(image: image.clone()))),
      );
    }
    image.dispose();
    fonts.assetManifest = _FontAssets();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
      final key = const StringCodec().decodeMessage(message);
      if (key == null) return null;
      final file = key.startsWith('Roboto-')
          ? File('/System/Library/Fonts/Supplemental/Arial.ttf')
          : File('build/unit_test_assets/$key');
      return file.existsSync()
          ? ByteData.sublistView(file.readAsBytesSync())
          : null;
    });
  });
  tearDown(() async => getIt.reset());

  test('YouTube URL formats and host validation', () {
    const id = 'dQw4w9WgXcQ';
    for (final url in [
      id,
      'https://youtube.com/watch?feature=share&v=$id',
      'https://youtu.be/$id?t=10',
      'https://m.youtube.com/shorts/$id',
      'https://www.youtube.com/live/$id',
      'https://www.youtube-nocookie.com/embed/$id'
    ]) {
      expect(youtubeVideoId(url), id);
    }
    for (final url in [
      'https://notyoutube.com/watch?v=$id',
      'https://youtube.com/watch?v=bad',
      '',
      'https://youtube.com.evil.com/watch?v=$id'
    ]) {
      expect(youtubeVideoId(url), isNull);
    }
  });

  testWidgets(
      'Fullscreen starts at tapped image and supports buttons and swipe',
      (tester) async {
    await tester.pumpWidget(
        MaterialApp(home: ImageGalleryPage(place: place(), initialIndex: 1)));
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);
    await tester.tap(find.byTooltip('Next image'));
    await tester.pumpAndSettle();
    expect(find.text('3 / 3'), findsOneWidget);
    expect(
        tester
            .widget<IconButton>(find.byWidgetPredicate((widget) =>
                widget is IconButton && widget.tooltip == 'Next image'))
            .onPressed,
        isNull);
    await tester.tap(find.byTooltip('Previous image'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PageView), const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(find.text('1 / 3'), findsOneWidget);
    expect(
        tester
            .widget<IconButton>(find.byWidgetPredicate((widget) =>
                widget is IconButton && widget.tooltip == 'Previous image'))
            .onPressed,
        isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Detail opens tapped hero image; gallery contains videos only',
      (tester) async {
    final value = place();
    getIt.registerSingleton<GetTourismPlaceDetail>(
        GetTourismPlaceDetail(_Repository(value)));
    await tester
        .pumpWidget(MaterialApp(home: ExploreDetailPage(initialPlace: value)));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Open image 2 fullscreen'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);
    await tester.tap(find.byTooltip('Close viewer'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Videos'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -250));
    await tester.pumpAndSettle();
    expect(find.text('Videos'), findsOneWidget);
    expect(find.text('Images'), findsNothing);
    expect(find.text('Stories'), findsNothing);
    expect(find.textContaining('Hidden story'), findsNothing);
    expect(find.byType(VideoGalleryPage), findsNothing);
    await tester.ensureVisible(
        find.bySemanticsLabel(RegExp('Play Temple video fullscreen')));
    await tester
        .tap(find.bySemanticsLabel(RegExp('Play Temple video fullscreen')));
    await tester.pumpAndSettle();
    expect(find.byType(VideoGalleryPage), findsOneWidget);
    expect(find.text('This video does not have a valid YouTube URL.'),
        findsOneWidget);
    await tester.tap(find.byTooltip('Close viewer'));
    await tester.pumpAndSettle();
    expect(find.byType(VideoGalleryPage), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Empty galleries are safe', (tester) async {
    await tester.pumpWidget(
        MaterialApp(home: ImageGalleryPage(place: place(images: 0))));
    await tester.pumpAndSettle();
    expect(find.text('No images available.'), findsOneWidget);
    await tester.pumpWidget(
        MaterialApp(home: VideoGalleryPage(place: place(video: false))));
    await tester.pumpAndSettle();
    expect(find.text('No videos available.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
