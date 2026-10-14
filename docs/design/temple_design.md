# Temple-inspired mobile design

The presentation layer now follows the supplied Tirth Sangam showcase: ivory and peach surfaces, temple landscapes, coral/saffron gradients, warm borders and restrained shadows. The customer theme uses orange/coral gradients; the provider theme retains its original blue/purple gradients and cool surfaces. Both share the temple artwork and component styling. Existing routes, controllers, repositories, API requests and booking/payment behavior are retained.

Shared implementation: `lib/core/widgets/temple_surface.dart`, the existing `AppPage` and auth scaffold, and `lib/app/theme/app_theme.dart`. Screens using AppPage inherit the background automatically; standalone screens use TempleScaffold. Existing Material navigation destinations and callbacks are retained by TempleNavigationBar. The temple image is decorative and excluded from accessibility semantics.

Bundled artwork: `assets/images/common/temple_landscape.png`, generated using the built-in imagegen tool. Prompt: “A wide softly painted panorama of Ujjain temple spires and riverside ghats at golden sunset, terracotta temples, saffron flags, faint warm hills and glowing diyas. Open pale peach sky above, warm coral, peach, saffron and ivory palette. A continuous landscape for mobile headers and faded page backgrounds. No phones, interfaces, text, watermarks or close-up people.” This is illustrative artwork, not a factual temple photograph.

## Validation

- Full suite: 86 tests passed (82 existing tests plus four design checks).
- Added visual checks: sign-in/registration at 320 and 390 logical pixels, keyboard scrolling, drawer opening, primary actions and navigation selection.
- `flutter analyze`: no errors; existing lint warnings remain.
- Screenshots in this folder are widget-rendered previews. `signin.png` and `register.png` use the actual auth pages. `profile.png` uses the actual shared profile header with sample data. `details.png` demonstrates shared detail components with sample content. Offline previews use local Arial glyphs in place of runtime Google Fonts.

From the main project folder, run the existing user development entry point:

```sh
fvm flutter run --flavor userDev -t lib/main_user_dev.dart
```

Provider entry point:

```sh
fvm flutter run --flavor providerDev -t lib/main_provider_dev.dart
```

Run the checks with `fvm flutter test`. Regenerate optional previews with `TEMPLE_PREVIEW_DIR=/tmp/temple-previews fvm flutter test test/design/temple_design_test.dart`.
