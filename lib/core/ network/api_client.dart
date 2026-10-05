import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../errors/exceptions.dart';
import '../storage/secure_storage_service.dart';
import 'endpoints.dart';

class ApiClient {
  ApiClient({
    required String baseUrl,
    required http.Client client,
    required SecureStorageService secureStorage,
  })  : _baseUrl = baseUrl,
        _client = client,
        _secureStorage = secureStorage;

  final String _baseUrl;
  final http.Client _client;
  final SecureStorageService _secureStorage;
  Future<bool>? _refreshInProgress;

  String get baseUrl => _baseUrl;

  Future<Map<String, dynamic>> get(
    String path, {
    bool authenticated = false,
  }) {
    return _request(
      method: 'GET',
      path: path,
      authenticated: authenticated,
    );
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) {
    return _request(
      method: 'POST',
      path: path,
      body: body,
      authenticated: authenticated,
    );
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) {
    return _request(
      method: 'PATCH',
      path: path,
      body: body,
      authenticated: authenticated,
    );
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) {
    return _request(
      method: 'PUT',
      path: path,
      body: body,
      authenticated: authenticated,
    );
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) {
    return _request(
      method: 'DELETE',
      path: path,
      body: body,
      authenticated: authenticated,
    );
  }


  Future<Map<String, dynamic>> postBytes(
    String path, {
    required Uint8List bytes,
    required String contentType,
    required Map<String, String> headers,
    bool authenticated = false,
  }) {
    return _postBytes(
      path: path,
      bytes: bytes,
      contentType: contentType,
      headers: headers,
      authenticated: authenticated,
    );
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Uint8List bytes,
    required String fileName,
    required String fieldName,
    String? contentType,
    Map<String, String> fields = const <String, String>{},
    bool authenticated = false,
  }) {
    return _postMultipart(
      path: path,
      bytes: bytes,
      fileName: fileName,
      fieldName: fieldName,
      contentType: contentType,
      fields: fields,
      authenticated: authenticated,
    );
  }

  Future<Map<String, dynamic>> _postMultipart({
    required String path,
    required Uint8List bytes,
    required String fileName,
    required String fieldName,
    required String? contentType,
    required Map<String, String> fields,
    required bool authenticated,
    bool allowRefresh = true,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Accept'] = 'application/json'
      ..fields.addAll(fields);

    if (authenticated) {
      final accessToken = await _secureStorage.readAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $accessToken';
      }
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        fieldName,
        bytes,
        filename: fileName,
        contentType: contentType == null ? null : MediaType.parse(contentType),
      ),
    );

    try {
      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 45));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 401 &&
          authenticated &&
          allowRefresh &&
          path != Endpoints.refresh) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          return _postMultipart(
            path: path,
            bytes: bytes,
            fileName: fileName,
            fieldName: fieldName,
            contentType: contentType,
            fields: fields,
            authenticated: authenticated,
            allowRefresh: false,
          );
        }
      }

      final decoded = _decodeResponse(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _toApiException(response, decoded);
      }
      return decoded;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        'The upload timed out. Please check your connection and try again.',
      );
    } on http.ClientException {
      throw const ApiException(
        'Unable to reach the server. Please check your internet connection.',
      );
    }
  }

  Future<Map<String, dynamic>> _postBytes({
    required String path,
    required Uint8List bytes,
    required String contentType,
    required Map<String, String> headers,
    required bool authenticated,
    bool allowRefresh = true,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final requestHeaders = <String, String>{
      'Accept': 'application/json',
      'Content-Type': contentType,
      ...headers,
    };

    if (authenticated) {
      final accessToken = await _secureStorage.readAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        requestHeaders['Authorization'] = 'Bearer $accessToken';
      }
    }

    try {
      final response = await _client
          .post(uri, headers: requestHeaders, body: bytes)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 401 &&
          authenticated &&
          allowRefresh &&
          path != Endpoints.refresh) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          return _postBytes(
            path: path,
            bytes: bytes,
            contentType: contentType,
            headers: headers,
            authenticated: authenticated,
            allowRefresh: false,
          );
        }
      }

      final decoded = _decodeResponse(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _toApiException(response, decoded);
      }
      return decoded;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        'The upload timed out. Please check your connection and try again.',
      );
    } on http.ClientException {
      throw const ApiException(
        'Unable to reach the server. Please check your internet connection.',
      );
    }
  }

  Future<Map<String, dynamic>> _request({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    required bool authenticated,
    bool allowRefresh = true,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');

    try {
      final headers = <String, String>{
        'Accept': 'application/json',
        if (body != null) 'Content-Type': 'application/json',
      };

      if (authenticated) {
        final accessToken = await _secureStorage.readAccessToken();
        if (accessToken != null && accessToken.isNotEmpty) {
          headers['Authorization'] = 'Bearer $accessToken';
        }
      }

      final http.Response response;
      switch (method) {
        case 'POST':
          response = await _client
              .post(
                uri,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(const Duration(seconds: 20));
          break;
        case 'PATCH':
          response = await _client
              .patch(
                uri,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(const Duration(seconds: 20));
          break;
        case 'PUT':
          response = await _client
              .put(
                uri,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(const Duration(seconds: 20));
          break;
        case 'GET':
          response = await _client
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 20));
          break;
        case 'DELETE':
          response = await _client
              .delete(
                uri,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(const Duration(seconds: 20));
          break;
        default:
          throw UnsupportedError('Unsupported HTTP method: $method');
      }

      if (response.statusCode == 401 &&
          authenticated &&
          allowRefresh &&
          path != Endpoints.refresh) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          return _request(
            method: method,
            path: path,
            body: body,
            authenticated: authenticated,
            allowRefresh: false,
          );
        }
      }

      final decoded = _decodeResponse(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _toApiException(response, decoded);
      }

      return decoded;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        'The request timed out. Please check your connection and try again.',
      );
    } on http.ClientException {
      throw const ApiException(
        'Unable to reach the server. Please check your internet connection.',
      );
    } catch (error) {
      if (error is UnsupportedError) rethrow;
      throw const ApiException(
        'Something went wrong while contacting the server. Please try again.',
      );
    }
  }

  Future<bool> _refreshAccessToken() {
    final running = _refreshInProgress;
    if (running != null) return running;

    final future = _performRefresh();
    _refreshInProgress = future;
    return future.whenComplete(() => _refreshInProgress = null);
  }

  Future<bool> _performRefresh() async {
    final refreshToken = await _secureStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.trim().isEmpty) return false;

    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl${Endpoints.refresh}'),
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(<String, dynamic>{'refreshToken': refreshToken}),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (response.statusCode == 401) {
          await _secureStorage.clearSession();
        }
        return false;
      }

      final decoded = _decodeResponse(response);
      final data = decoded['data'];
      final tokens = data is Map ? data['tokens'] : null;
      if (tokens is! Map) return false;

      final access = tokens['accessToken']?.toString();
      final refresh = tokens['refreshToken']?.toString();
      if (access == null || access.isEmpty || refresh == null || refresh.isEmpty) {
        return false;
      }

      await _secureStorage.saveTokens(
        accessToken: access,
        refreshToken: refresh,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.body.trim().isEmpty) return <String, dynamic>{};

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {
      // The error mapper below will provide a safe message for invalid JSON.
    }

    return <String, dynamic>{};
  }

  ApiException _toApiException(
    http.Response response,
    Map<String, dynamic> decoded,
  ) {
    final error = decoded['error'];
    final errorMap = error is Map
        ? error.map((key, value) => MapEntry(key.toString(), value))
        : const <String, dynamic>{};

    final details = <ApiErrorDetail>[];
    final rawDetails = errorMap['details'];
    if (rawDetails is List) {
      for (final item in rawDetails) {
        if (item is Map) {
          final field = item['field']?.toString() ?? '';
          final message = item['message']?.toString() ?? '';
          if (message.isNotEmpty) {
            details.add(ApiErrorDetail(field: field, message: message));
          }
        }
      }
    }

    final message = errorMap['message']?.toString();
    return ApiException(
      message?.trim().isNotEmpty == true
          ? message!
          : 'Request failed. Please try again.',
      statusCode: response.statusCode,
      code: errorMap['code']?.toString(),
      details: details,
    );
  }
}
