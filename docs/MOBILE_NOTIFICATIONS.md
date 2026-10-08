# Mobile notification integration

The implementation is in the main mobile repository, using the existing manual GetIt registration and data → repository → use-case → presentation architecture. `lib/core/services/notification_service.dart` owns authenticated session, push token, unread count, and app lifecycle state. HTTP calls use the existing `ApiClient`, token refresh, and error handling.

## Supported builds and recipients

| Android flavor | Entry point | Backend appFlavor | Environment |
| --- | --- | --- | --- |
| userDev | lib/main_user_dev.dart | customer | development |
| userProd | lib/main_user_prod.dart | customer | production |
| providerDev | lib/main_provider_dev.dart | provider | development |
| providerProd | lib/main_provider_prod.dart | provider | production |
| adminDev | lib/main_admin_dev.dart | admin | development |
| adminProd | lib/main_admin_prod.dart | admin | production |

Pandit, accommodation, and transport provider dashboards use the shared notification bell and drawer. Providers awaiting verification can access their notifications from KYC. Customer and mobile admin builds use the existing home header/drawer. Admin operation links that have no mobile screen remain readable notification details; administration stays in the existing web panel.

## Behavior

- Paginated inbox, unread/category filters, pull-to-refresh, notification detail, read-one, and mark-all-read.
- Flavor-scoped authoritative unread count refreshes after read operations, on resume, and once per minute while the app is active. Backgrounding pauses the timer.
- Preferences include optional categories, English/Hindi, marketing consent, and quiet hours with an IANA timezone. Security remains enabled. Mandatory delivery policy is enforced by the backend.
- Push permission is requested only from the settings button. Already authorized installations register after login/session restore; retries happen on resume. Denied/unavailable push never prevents inbox use or login.
- Tokens register with a stable secure-storage installation identity, flavor, environment, and platform. Rotations serialize to prevent logout races. Logout stops listeners from displaying account content, clears badges and pending links, waits for in-flight registrations, deactivates the backend device, and deletes the FCM token. Remote deactivation/token deletion are best effort while offline.
- Foreground pushes fetch owned notification details before showing a snackbar. Background/terminated notification messages are presented by the OS; `onMessageOpenedApp` and `getInitialMessage` route taps through authenticated startup. This backend sends notification messages, so no background data-message worker is required.
- Push payloads supply only an identifier/flavor. The app fetches the owned backend row before showing detail or following its link. Only supported internal routes in the current flavor are mapped. Provider business navigation rechecks provider/KYC status. Unsupported targets remain readable details.
- Delivered (foreground push), opened, and clicked interactions are reported best effort; reporting cannot block navigation. No conversion is reported without an actual domain conversion.

## Enable Firebase push

The repository originally has empty `lib/firebase/*_options.dart` placeholders and no Firebase app configuration. Inbox and preferences work without Firebase. Push transport needs real configuration for the selected build and the backend FCM credentials described in the backend notification runbook.

The push client accepts compile-time public Firebase configuration through:

- `FIREBASE_API_KEY`
- `FIREBASE_APP_ID`
- `FIREBASE_MESSAGING_SENDER_ID`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_IOS_BUNDLE_ID` for iOS (matching the signed bundle identifier)

For each flavor/environment, create a local JSON file containing these keys with that Firebase application's actual values, then run:

```sh
flutter run --flavor userDev -t lib/main_user_dev.dart --dart-define-from-file=/absolute/path/firebase-user-dev.json
flutter run --flavor providerDev -t lib/main_provider_dev.dart --dart-define-from-file=/absolute/path/firebase-provider-dev.json
flutter run --flavor adminDev -t lib/main_admin_dev.dart --dart-define-from-file=/absolute/path/firebase-admin-dev.json
```

Use the corresponding production flavor, entry point, and Firebase config for production. Runtime `FirebaseOptions` avoid requiring a Google Services Gradle plugin/config file for builds. A native default Firebase configuration is also accepted if already provisioned by the native build.

Register the exact application IDs from `android/app/build.gradle` in Firebase, including flavor suffixes. Backend FCM credentials must be authorized for the project supplying the selected app token. Do not place service-account credentials in the mobile app.

Android's notification permission is declared in the shared manifest. For iOS, remote-notification background mode and APNs entitlements are configured; Debug uses development APNs and Release/Profile use production. Firebase's native SDK requires iOS 13, reflected in project/framework deployment targets. Upload the APNs authentication key to Firebase and enable Push Notifications for the signed Apple app ID/provisioning profile. The existing iOS project currently has only the Runner scheme and one bundle ID; use the appropriate Dart entry point/config for that app, or configure role-specific native schemes/signing before distributing distinct iOS apps. This change does not invent new iOS flavors.

Official setup/receiving references: https://firebase.google.com/docs/flutter/setup and https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages.

## Validation

```sh
flutter test
flutter analyze
flutter build apk --debug --flavor userDev -t lib/main_user_dev.dart
```

Tests cover backend envelopes and request bodies, all six registration identities, token rotation/logout races, stale unread results, push tap authentication/flavor boundaries, supported route mapping, inbox pagination/read/filter/retry, badge counts, preferences, and splash startup for every role/environment. Existing unrelated analyzer warnings are documented in the completion report. Device push delivery requires a real Firebase project, backend worker, and signed device; mock tests do not establish end-to-end delivery.

### Results for this change

- `flutter test`: 32 tests passed, including every flavor's splash startup and authentication persistence regressions.
- All six Android flavors compiled successfully as debug APKs (including the production configurations).
- `flutter analyze`: notification integration adds no diagnostics; 13 existing warnings/info remain in marketplace, pooja, profile and provider pages.
- iOS simulator build reached native compilation but failed in the existing `razorpay_flutter` 1.4.6 dependency: `RazorpayDelegate.swift:81`, `RazorpayCheckout` has no `subscribeToAnalyticsEvents` member. The payment package/version is unchanged. Notification device delivery and iOS distribution remain unverified.
- The host selects CommandLineTools by default. To invoke the installed Xcode without changing system settings, prefix iOS build commands with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.
