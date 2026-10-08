import 'package:avantika_lok_tourism_app/app/config/environment_config.dart';
import 'package:avantika_lok_tourism_app/core/errors/exceptions.dart';
import 'package:avantika_lok_tourism_app/core/services/notification_service.dart';
import 'package:avantika_lok_tourism_app/core/storage/secure_storage_service.dart';
import 'package:avantika_lok_tourism_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:avantika_lok_tourism_app/features/auth/data/models/auth_session_model.dart';
import 'package:avantika_lok_tourism_app/features/auth/data/models/auth_user_model.dart';
import 'package:avantika_lok_tourism_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:avantika_lok_tourism_app/features/notifications/domain/usecases/notification_actions.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'notification_fakes.dart';

class _AuthStorage extends SecureStorageService {
  _AuthStorage() : super(const FlutterSecureStorage());
  String? access, refresh;
  bool active = false;
  @override
  Future<bool> hasSession() async => active;
  @override
  Future<String?> readAccessToken() async => access;
  @override
  Future<String?> readRefreshToken() async => refresh;
  @override
  Future<void> saveTokens(
      {required String accessToken, required String refreshToken}) async {
    access = accessToken;
    refresh = refreshToken;
    active = true;
  }

  @override
  Future<void> markSessionInactive() async {
    active = false;
  }

  @override
  Future<void> clearSession() async {
    active = false;
    access = null;
    refresh = null;
  }
}

class _AuthRemote implements AuthRemoteDataSource {
  Object? restoreError;
  final user = AuthUserModel.fromJson(
      {'id': 'user-1', 'email': 'user@test.com', 'firstName': 'User'});
  String? loggedOutRefresh;
  bool failLogout = false;
  void Function()? beforeLogout;
  @override
  Future<AuthSessionModel> login(
          {required String email, required String password}) async =>
      AuthSessionModel(
          user: user, accessToken: 'access', refreshToken: 'refresh');
  @override
  Future<AuthUserModel> currentUser() async {
    if (restoreError != null) throw restoreError!;
    return user;
  }

  @override
  Future<void> logout({required String refreshToken}) async {
    beforeLogout?.call();
    loggedOutRefresh = refreshToken;
    if (failLogout) throw const ApiException('offline');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _AuthStorage storage;
  late _AuthRemote remote;
  late FakeNotificationPush push;
  late NotificationService notifications;
  late AuthRepositoryImpl auth;
  setUp(() {
    storage = _AuthStorage();
    remote = _AuthRemote();
    push = FakeNotificationPush();
    notifications = NotificationService(
        NotificationActions(FakeNotificationRepository()),
        EnvironmentConfig.userDevelopment,
        push,
        FakeNotificationStorage());
    auth = AuthRepositoryImpl(remote, storage, notifications: notifications);
  });
  tearDown(() async {
    notifications.dispose();
    await push.dispose();
  });
  test('login retains persistent tokens and starts notifications', () async {
    final user = await auth.login(email: 'user@test.com', password: 'password');
    expect(user.id, 'user-1');
    expect(storage.access, 'access');
    expect(storage.refresh, 'refresh');
    expect(storage.active, true);
    expect(notifications.active, true);
  });
  test('restore without a saved session does not start notification requests',
      () async {
    expect(await auth.restoreSession(), false);
    expect(notifications.active, false);
  });
  test(
      'temporary restore failures preserve authentication and allow notification retry',
      () async {
    await storage.saveTokens(accessToken: 'access', refreshToken: 'refresh');
    remote.restoreError =
        const ApiException('Temporary server error', statusCode: 503);
    expect(await auth.restoreSession(), true);
    expect(storage.active, true);
    expect(notifications.active, true);
  });
  test('rejected restored credentials never activate notifications', () async {
    await storage.saveTokens(accessToken: 'access', refreshToken: 'refresh');
    remote.restoreError =
        const ApiException('Session expired', statusCode: 401);
    expect(await auth.restoreSession(), false);
    expect(storage.active, false);
    expect(notifications.active, false);
  });
  test(
      'logout still clears tokens after a backend failure and stops notifications first',
      () async {
    await auth.login(email: 'user@test.com', password: 'password');
    remote.failLogout = true;
    remote.beforeLogout = () {
      expect(notifications.active, false);
      expect(storage.active, false);
      expect(storage.access, 'access');
    };
    await expectLater(auth.logout(), throwsA(isA<ApiException>()));
    expect(remote.loggedOutRefresh, 'refresh');
    expect(storage.access, null);
    expect(storage.refresh, null);
    expect(notifications.unreadCount, 0);
    expect(push.deleted, true);
  });
}
