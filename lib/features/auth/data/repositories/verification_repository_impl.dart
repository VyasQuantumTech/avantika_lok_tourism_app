import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../../../core/ network/api_client.dart';
import '../../../../core/ network/endpoints.dart';
import '../../../../core/utils/mobile_identity.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/verification_challenge.dart';
import '../../domain/repositories/verification_repository.dart';
import '../models/auth_session_model.dart';

class VerificationRepositoryImpl implements VerificationRepository {
  VerificationRepositoryImpl(this._api, this._storage, this._notifications);
  final ApiClient _api;
  final SecureStorageService _storage;
  final NotificationService _notifications;
  @override
  Future<void> logoutAll() async {
    await _api.post(Endpoints.authLogoutAll, authenticated: true);
    try {
      await _notifications.stopSession();
    } finally {
      await _storage.clearSession();
    }
  }

  @override
  Future<List<Map<String, dynamic>>> sessions() async =>
      (_data(await _api.get(Endpoints.authSessions, authenticated: true))[
              'items'] as List)
          .map((v) => Map<String, dynamic>.from(v as Map))
          .toList();
  @override
  Future<List<Map<String, dynamic>>> socialIdentities() async =>
      (_data(await _api.get(Endpoints.authSocial, authenticated: true))['items']
              as List)
          .map((v) => Map<String, dynamic>.from(v as Map))
          .toList();
  @override
  Future<void> unlink(String identityId) async {
    await _api.delete('${Endpoints.authSocial}/$identityId',
        authenticated: true);
  }

  @override
  Future<VerificationChallenge?> restorePending() async {
    final data = await _storage.readPendingVerification();
    if (data == null) return null;
    try {
      return VerificationChallenge.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<VerificationChallenge> _remember(Map<String, dynamic> data) async {
    final challenge = VerificationChallenge.fromJson(data);
    if (!_sensitive(challenge.purpose)) {
      await _storage.savePendingVerification(challenge.toJson());
    }
    return challenge;
  }

  bool _sensitive(String purpose) =>
      !['registration', 'login'].contains(purpose);
  Map<String, dynamic> _data(Map<String, dynamic> response) =>
      Map<String, dynamic>.from(response['data'] as Map);
  @override
  Future<Map<String, dynamic>> capabilities() async =>
      _data(await _api.get(Endpoints.authCapabilities));
  @override
  Future<VerificationChallenge> request(
      {required String channel,
      required String identity,
      required String purpose,
      String? firstName,
      String? lastName}) async {
    final response = await _api.post(Endpoints.authOtpRequest,
        authenticated: _sensitive(purpose),
        body: {
          'channel': channel,
          'identity': channel == 'sms'
              ? normalizeMobileIdentity(identity)
              : identity.trim().toLowerCase(),
          'purpose': purpose,
          if (firstName != null) 'firstName': firstName,
          if (lastName != null) 'lastName': lastName,
        });
    return _remember(_data(response));
  }

  @override
  Future<VerificationChallenge> resend(VerificationChallenge challenge) async =>
      _remember(_data(await _api.post(Endpoints.authOtpResend,
          authenticated: _sensitive(challenge.purpose),
          body: {'challengeId': challenge.id})));
  @override
  Future<void> cancel(VerificationChallenge challenge) async {
    await _api.post(Endpoints.authOtpCancel,
        authenticated: _sensitive(challenge.purpose),
        body: {'challengeId': challenge.id});
    await _storage.clearPendingVerification(challenge.id);
  }

  Future<void> _save(Map<String, dynamic> response) async {
    final session = AuthSessionModel.fromJson(response);
    if (session.accessToken.isEmpty || session.refreshToken.isEmpty) {
      throw const ApiException(
          'The server returned an invalid authentication session.');
    }
    await _storage.saveTokens(
        accessToken: session.accessToken, refreshToken: session.refreshToken);
    unawaited(_notifications.startSession());
  }

  @override
  Future<void> verify(VerificationChallenge challenge, String code,
      {bool confirm = false}) async {
    final response = await _api.post(Endpoints.authOtpVerify,
        authenticated: _sensitive(challenge.purpose),
        body: {
          'challengeId': challenge.id,
          'purpose': challenge.purpose,
          'otp': code,
          'confirm': confirm
        });
    await _storage.clearPendingVerification(challenge.id);
    if (_sensitive(challenge.purpose)) {
      try {
        await _notifications.stopSession();
      } finally {
        await _storage.clearSession();
      }
    } else {
      await _save(response);
    }
  }

  @override
  Future<void> social(String provider, {bool link = false}) async {
    String? token;
    String? challengeId;
    String? authorizationCode;
    if (provider == 'google') {
      const serverId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
      const clientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
      final account = await GoogleSignIn(
              scopes: ['email'],
              serverClientId: serverId.isEmpty ? null : serverId,
              clientId: clientId.isEmpty ? null : clientId)
          .signIn();
      if (account == null) throw const ApiException('Sign-in cancelled.');
      token = (await account.authentication).idToken;
    } else {
      final nonce = _data(await _api.post(Endpoints.authSocialNonce));
      challengeId = nonce['challengeId'] as String;
      final credential = await SignInWithApple.getAppleIDCredential(
          scopes: [AppleIDAuthorizationScopes.email],
          nonce:
              sha256.convert(utf8.encode(nonce['nonce'] as String)).toString());
      token = credential.identityToken;
      authorizationCode = credential.authorizationCode;
    }
    if (token == null) {
      throw const ApiException('Unable to obtain a sign-in credential.');
    }
    await _save(
        await _api.post(Endpoints.authSocial, authenticated: link, body: {
      'provider': provider,
      'providerToken': token,
      if (challengeId != null) 'challengeId': challengeId,
      if (authorizationCode != null) 'authorizationCode': authorizationCode
    }));
  }
}
