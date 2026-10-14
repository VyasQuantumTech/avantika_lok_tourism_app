# Mobile booking and provider alignment

The customer and provider apps use the backend's booking lifecycle and payment policy for pooja, accommodation, and transport. Booking actions pass through data sources, repositories, use cases, and the existing GetIt registrations. Shared booking/payment widgets serve all three services.

## Behavior

- Customer booking details show the saved service summary, provider decision, confirmation/payment status, and applicable hold deadline. Checkout appears only for outstanding online-required payments. Disabled and pay-on-arrival bookings retain their respective policies.
- Start codes are fetched only for confirmed, accepted bookings. Completion codes become available after the service starts. Provider controls follow the same state gates; customer cancellation disappears once the service starts.
- Transport customers can check availability and fare for a route, time interval, and passenger count before requesting a ride. Quotes do not reserve capacity. Booking details show the approved provider operating the trip, arrival, and the last reported tracking update.
- The approved vehicle-owner provider drives their own trips without a separate driver identity or manual assignment. Providers can record arrival, manage optional tracking devices, and switch vehicles between active and maintenance. Document submission stays pending for administrator review.
- Accommodation providers can pause/resume properties and inspect/edit daily room inventory with reserved stock and stay limits visible. Pricing and inventory requests retain the backend's validation.
- Provider earnings preserve unavailable totals and display separate currency summaries. Lists follow backend pagination.

## Run from the main checkout

Use the existing Flutter SDK and Android flavors:

```sh
cd /Users/dimpisharma/Documents/projects/mobileapps/avantika_lok_tourism_app
flutter pub get
flutter run --flavor userDev -t lib/main_user_dev.dart
flutter run --flavor providerDev -t lib/main_provider_dev.dart
```

The development API defaults to `https://api-dev.tirthsangam.com`. Use `--dart-define=AVANTIKA_API_BASE_URL=https://your-backend.example` when testing another backend. Firebase setup and the production/admin entry points remain documented in [MOBILE_NOTIFICATIONS.md](MOBILE_NOTIFICATIONS.md).

## Backend dependency

New/replacement private vehicle-document uploads send the private media ID returned by the upload API. The actual backend checkout now accepts `mediaAssetId`, validates ownership/private image status, and resolves the storage key internally. Legacy `storageKey` requests remain supported. The old compatibility patch is historical reference; do not apply it over the updated backend.

Vehicle setup is: draft → upload RC/insurance/permit/PUC → add current pricing (active route if route-specific) → submit → admin verifies documents → admin approves vehicle. Submission accepts pending evidence; final approval requires verified, unexpired evidence. Admin review preserves submission; provider edits clear it for a new review. The transport business profile must also be active. Approved listings cannot be taken offline by repeated submission.

These changes are local source changes. Deploy the updated backend and admin panel together, then rebuild/restart the provider and customer apps. Existing vehicles with no documents or pricing still require provider setup; this does not fabricate compliance records for them.

## Validation

Contract and widget coverage is in `test/bookings/`. It covers payment/confirmation gates, phase-specific codes, pagination, financial nullability/currencies, transport requests, and customer/provider controls and refresh. Run `flutter test` and `flutter analyze` from the main checkout after integration. Android builds use the existing flavor/entry-point pairs; real payment callbacks, location updates, inventory conflicts, document review, and device notifications require a configured backend/device smoke test.
