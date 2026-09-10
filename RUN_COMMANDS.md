# Avantika Lok Mobile App — Run Commands

This project supports **three app flavors** and **two environments**:

| App | Development | Production |
|---|---|---|
| User | `userDev` | `userProd` |
| Provider | `providerDev` | `providerProd` |
| Admin | `adminDev` | `adminProd` |

The project uses **FVM**, so use `fvm flutter ...` instead of plain `flutter ...`.

---

## 1. First-time / clean setup

Run from the project root:

```bash
fvm flutter clean
fvm flutter pub get
```

Check available devices:

```bash
fvm flutter devices
```

---

# 2. Android — Development

Android requires **both** the Android Gradle flavor and the matching Dart entry point.

## User Development

```bash
fvm flutter run \
  --flavor userDev \
  -t lib/main_user_dev.dart
```

## Provider Development

```bash
fvm flutter run \
  --flavor providerDev \
  -t lib/main_provider_dev.dart
```

## Admin Development

```bash
fvm flutter run \
  --flavor adminDev \
  -t lib/main_admin_dev.dart
```

---

# 3. Android — Production

## User Production

```bash
fvm flutter run \
  --flavor userProd \
  -t lib/main_user_prod.dart
```

## Provider Production

```bash
fvm flutter run \
  --flavor providerProd \
  -t lib/main_provider_prod.dart
```

## Admin Production

```bash
fvm flutter run \
  --flavor adminProd \
  -t lib/main_admin_prod.dart
```

---

# 4. Android — Run on a specific device

First:

```bash
fvm flutter devices
```

Then provide the device ID with `-d`.

Example using your currently connected Android device:

```bash
fvm flutter run \
  -d RZ8MA122VCN \
  --flavor userDev \
  -t lib/main_user_dev.dart
```

The same pattern applies to every flavor:

```bash
fvm flutter run \
  -d <DEVICE_ID> \
  --flavor <ANDROID_FLAVOR> \
  -t <DART_ENTRY_POINT>
```

Example:

```bash
fvm flutter run \
  -d RZ8MA122VCN \
  --flavor providerDev \
  -t lib/main_provider_dev.dart
```

---

# 5. Chrome / Web — Development

For Chrome, **do not use `--flavor`**.

The Dart entry point selects the app and environment.

## User Development

```bash
fvm flutter run \
  -d chrome \
  -t lib/main_user_dev.dart
```

## Provider Development

```bash
fvm flutter run \
  -d chrome \
  -t lib/main_provider_dev.dart
```

## Admin Development

```bash
fvm flutter run \
  -d chrome \
  -t lib/main_admin_dev.dart
```

---

# 6. Chrome / Web — Production configuration

These commands run the production application configuration in Chrome.

## User Production

```bash
fvm flutter run \
  -d chrome \
  -t lib/main_user_prod.dart
```

## Provider Production

```bash
fvm flutter run \
  -d chrome \
  -t lib/main_provider_prod.dart
```

## Admin Production

```bash
fvm flutter run \
  -d chrome \
  -t lib/main_admin_prod.dart
```

---

# 7. Android — Debug, Profile and Release mode

Flutter uses **debug mode by default** when running.

## User Dev — Debug

```bash
fvm flutter run \
  --debug \
  --flavor userDev \
  -t lib/main_user_dev.dart
```

## User Dev — Profile

```bash
fvm flutter run \
  --profile \
  --flavor userDev \
  -t lib/main_user_dev.dart
```

## User Prod — Release

```bash
fvm flutter run \
  --release \
  --flavor userProd \
  -t lib/main_user_prod.dart
```

The same flags can be applied to Provider and Admin.

### Provider Production — Release

```bash
fvm flutter run \
  --release \
  --flavor providerProd \
  -t lib/main_provider_prod.dart
```

### Admin Production — Release

```bash
fvm flutter run \
  --release \
  --flavor adminProd \
  -t lib/main_admin_prod.dart
```

---

# 8. Chrome — Debug, Profile and Release mode

## User Dev — Debug

```bash
fvm flutter run \
  -d chrome \
  --debug \
  -t lib/main_user_dev.dart
```

## User Dev — Profile

```bash
fvm flutter run \
  -d chrome \
  --profile \
  -t lib/main_user_dev.dart
```

## User Production — Release

```bash
fvm flutter run \
  -d chrome \
  --release \
  -t lib/main_user_prod.dart
```

Provider:

```bash
fvm flutter run \
  -d chrome \
  --release \
  -t lib/main_provider_prod.dart
```

Admin:

```bash
fvm flutter run \
  -d chrome \
  --release \
  -t lib/main_admin_prod.dart
```

---

# 9. Override API base URL while running

The project supports:

```text
AVANTIKA_API_BASE_URL
```

This is useful for testing a local backend, staging backend, another development server, or a temporary API deployment without changing Dart source files.

## Android — Local-network backend

Android physical devices cannot use your Mac's `localhost` directly.

Example:

```bash
fvm flutter run \
  --flavor userDev \
  -t lib/main_user_dev.dart \
  --dart-define=AVANTIKA_API_BASE_URL=http://192.168.1.10:8080
```

Provider:

```bash
fvm flutter run \
  --flavor providerDev \
  -t lib/main_provider_dev.dart \
  --dart-define=AVANTIKA_API_BASE_URL=http://192.168.1.10:8080
```

Admin:

```bash
fvm flutter run \
  --flavor adminDev \
  -t lib/main_admin_dev.dart \
  --dart-define=AVANTIKA_API_BASE_URL=http://192.168.1.10:8080
```

Replace:

```text
192.168.1.10
```

with your Mac's LAN IP.

## Chrome — Local backend

```bash
fvm flutter run \
  -d chrome \
  -t lib/main_user_dev.dart \
  --dart-define=AVANTIKA_API_BASE_URL=http://localhost:8080
```

Provider:

```bash
fvm flutter run \
  -d chrome \
  -t lib/main_provider_dev.dart \
  --dart-define=AVANTIKA_API_BASE_URL=http://localhost:8080
```

Admin:

```bash
fvm flutter run \
  -d chrome \
  -t lib/main_admin_dev.dart \
  --dart-define=AVANTIKA_API_BASE_URL=http://localhost:8080
```

## Override with another remote environment

Example staging server:

```bash
fvm flutter run \
  --flavor userDev \
  -t lib/main_user_dev.dart \
  --dart-define=AVANTIKA_API_BASE_URL=https://api-staging.tirthsangam.com
```

The same mechanism works with any of the six entry points.

---

# 10. Build Android APKs

## User Development APK

```bash
fvm flutter build apk \
  --flavor userDev \
  -t lib/main_user_dev.dart
```

## User Production APK

```bash
fvm flutter build apk \
  --release \
  --flavor userProd \
  -t lib/main_user_prod.dart
```

## Provider Development APK

```bash
fvm flutter build apk \
  --flavor providerDev \
  -t lib/main_provider_dev.dart
```

## Provider Production APK

```bash
fvm flutter build apk \
  --release \
  --flavor providerProd \
  -t lib/main_provider_prod.dart
```

## Admin Development APK

```bash
fvm flutter build apk \
  --flavor adminDev \
  -t lib/main_admin_dev.dart
```

## Admin Production APK

```bash
fvm flutter build apk \
  --release \
  --flavor adminProd \
  -t lib/main_admin_prod.dart
```

---

# 11. Build split APKs by ABI

Useful when you want smaller Android APK files:

```bash
fvm flutter build apk \
  --release \
  --split-per-abi \
  --flavor userProd \
  -t lib/main_user_prod.dart
```

Provider:

```bash
fvm flutter build apk \
  --release \
  --split-per-abi \
  --flavor providerProd \
  -t lib/main_provider_prod.dart
```

Admin:

```bash
fvm flutter build apk \
  --release \
  --split-per-abi \
  --flavor adminProd \
  -t lib/main_admin_prod.dart
```

---

# 12. Build Android App Bundle (`.aab`)

Use App Bundles for Google Play distribution.

## User Production

```bash
fvm flutter build appbundle \
  --release \
  --flavor userProd \
  -t lib/main_user_prod.dart
```

## Provider Production

```bash
fvm flutter build appbundle \
  --release \
  --flavor providerProd \
  -t lib/main_provider_prod.dart
```

## Admin Production

```bash
fvm flutter build appbundle \
  --release \
  --flavor adminProd \
  -t lib/main_admin_prod.dart
```

---

# 13. Build Web

Web does not use Android Gradle flavors.

## User Development Web build

```bash
fvm flutter build web \
  -t lib/main_user_dev.dart
```

## User Production Web build

```bash
fvm flutter build web \
  --release \
  -t lib/main_user_prod.dart
```

## Provider Development Web build

```bash
fvm flutter build web \
  -t lib/main_provider_dev.dart
```

## Provider Production Web build

```bash
fvm flutter build web \
  --release \
  -t lib/main_provider_prod.dart
```

## Admin Development Web build

```bash
fvm flutter build web \
  -t lib/main_admin_dev.dart
```

## Admin Production Web build

```bash
fvm flutter build web \
  --release \
  -t lib/main_admin_prod.dart
```

Output:

```text
build/web/
```

---

# 14. Complete run-command matrix

| Platform | App | Environment | Command |
|---|---|---|---|
| Android | User | Development | `fvm flutter run --flavor userDev -t lib/main_user_dev.dart` |
| Android | User | Production | `fvm flutter run --flavor userProd -t lib/main_user_prod.dart` |
| Android | Provider | Development | `fvm flutter run --flavor providerDev -t lib/main_provider_dev.dart` |
| Android | Provider | Production | `fvm flutter run --flavor providerProd -t lib/main_provider_prod.dart` |
| Android | Admin | Development | `fvm flutter run --flavor adminDev -t lib/main_admin_dev.dart` |
| Android | Admin | Production | `fvm flutter run --flavor adminProd -t lib/main_admin_prod.dart` |
| Chrome | User | Development | `fvm flutter run -d chrome -t lib/main_user_dev.dart` |
| Chrome | User | Production | `fvm flutter run -d chrome -t lib/main_user_prod.dart` |
| Chrome | Provider | Development | `fvm flutter run -d chrome -t lib/main_provider_dev.dart` |
| Chrome | Provider | Production | `fvm flutter run -d chrome -t lib/main_provider_prod.dart` |
| Chrome | Admin | Development | `fvm flutter run -d chrome -t lib/main_admin_dev.dart` |
| Chrome | Admin | Production | `fvm flutter run -d chrome -t lib/main_admin_prod.dart` |

---

# 15. Entry-point mapping

Do not mix an Android flavor with the wrong Dart entry point.

Correct combinations:

```text
userDev      -> lib/main_user_dev.dart
userProd     -> lib/main_user_prod.dart

providerDev  -> lib/main_provider_dev.dart
providerProd -> lib/main_provider_prod.dart

adminDev     -> lib/main_admin_dev.dart
adminProd    -> lib/main_admin_prod.dart
```

Avoid combinations such as:

```bash
# WRONG
fvm flutter run --flavor providerDev -t lib/main_user_dev.dart
```

or:

```bash
# WRONG
fvm flutter run --flavor userProd -t lib/main_admin_prod.dart
```

The Android flavor controls Android-side identity/configuration while the Dart entry point controls the runtime `AppConfig`. They must represent the same app/environment combination.

---

# 16. About `lib/main.dart`

Now that explicit flavors exist, prefer the dedicated entry points.

For Android, **do not use this as your normal run command**:

```bash
fvm flutter run lib/main.dart
```

Instead use the explicit flavor + target commands from this README.

For example:

```bash
fvm flutter run \
  --flavor userDev \
  -t lib/main_user_dev.dart
```

This prevents Gradle or the IDE from choosing an unintended Android product flavor.

---

# 17. Recommended commands for day-to-day development

Most of the time you only need these three Android commands:

```bash
# USER
fvm flutter run --flavor userDev -t lib/main_user_dev.dart

# PROVIDER
fvm flutter run --flavor providerDev -t lib/main_provider_dev.dart

# ADMIN
fvm flutter run --flavor adminDev -t lib/main_admin_dev.dart
```

And these three Chrome commands:

```bash
# USER
fvm flutter run -d chrome -t lib/main_user_dev.dart

# PROVIDER
fvm flutter run -d chrome -t lib/main_provider_dev.dart

# ADMIN
fvm flutter run -d chrome -t lib/main_admin_dev.dart
```

Use the `*Prod` entry points only when you intentionally want the production configuration.

---

# 18. Recommended clean rebuild after changing flavor configuration

When modifying:

```text
android/app/build.gradle
AndroidManifest.xml
applicationId
manifestPlaceholders
productFlavors
entry points
environment configuration
```

run:

```bash
fvm flutter clean
fvm flutter pub get
```

Then launch the exact required flavor again.

For deeper Android Gradle cleanup if necessary:

```bash
cd android
./gradlew clean
cd ..
fvm flutter pub get
```

Then:

```bash
fvm flutter run --flavor userDev -t lib/main_user_dev.dart
```

---

# 19. Quick copy/paste section

## Android

```bash
# USER DEV
fvm flutter run --flavor userDev -t lib/main_user_dev.dart

# USER PROD
fvm flutter run --flavor userProd -t lib/main_user_prod.dart

# PROVIDER DEV
fvm flutter run --flavor providerDev -t lib/main_provider_dev.dart

# PROVIDER PROD
fvm flutter run --flavor providerProd -t lib/main_provider_prod.dart

# ADMIN DEV
fvm flutter run --flavor adminDev -t lib/main_admin_dev.dart

# ADMIN PROD
fvm flutter run --flavor adminProd -t lib/main_admin_prod.dart
```

## Chrome

```bash
# USER DEV
fvm flutter run -d chrome -t lib/main_user_dev.dart

# USER PROD
fvm flutter run -d chrome -t lib/main_user_prod.dart

# PROVIDER DEV
fvm flutter run -d chrome -t lib/main_provider_dev.dart

# PROVIDER PROD
fvm flutter run -d chrome -t lib/main_provider_prod.dart

# ADMIN DEV
fvm flutter run -d chrome -t lib/main_admin_dev.dart

# ADMIN PROD
fvm flutter run -d chrome -t lib/main_admin_prod.dart
```
