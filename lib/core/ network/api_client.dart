import 'dart:convert';

import 'package:http/http.dart' as http;

import '../errors/exceptions.dart';

class ApiClient {
  ApiClient({
    required String baseUrl,
    required http.Client client,
  })  : _baseUrl = baseUrl,
        _client = client;

  final String _baseUrl;
  final http.Client _client;

  Future<Map<String, dynamic>> get(String path) async {
    final uri = Uri.parse('$_baseUrl$path');

    try {
      final response = await _client
          .get(
            uri,
            headers: const {
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          'Request failed with status ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      if (response.body.trim().isEmpty) {
        return <String, dynamic>{};
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const ApiException('Unexpected API response format.');
      }

      return decoded;
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException('Unable to connect to API: $error');
    }
  }
}
