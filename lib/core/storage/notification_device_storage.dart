import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NotificationDeviceStorage {
  const NotificationDeviceStorage(this._storage);
  final FlutterSecureStorage _storage;
  Future<String> installationId() async {
    const key = 'notification_installation_id';
    final stored = await _storage.read(key: key);
    if (stored != null && stored.isNotEmpty) return stored;
    final random = Random.secure();
    final value = List.generate(
            24, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'))
        .join();
    await _storage.write(key: key, value: value);
    return value;
  }

  Future<String?> registrationId() =>
      _storage.read(key: 'notification_registration_id');
  Future<void> saveRegistrationId(String value) =>
      _storage.write(key: 'notification_registration_id', value: value);
  Future<void> clearRegistrationId() =>
      _storage.delete(key: 'notification_registration_id');
}
