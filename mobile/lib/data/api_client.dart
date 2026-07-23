import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'session_storage.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  final String baseUrl;
  final SessionStorage storage;
  final http.Client _client;
  String? _token;

  ApiClient({
    required this.baseUrl,
    required this.storage,
    http.Client? client,
  }) : _client = client ?? http.Client();

  set accessToken(String? value) => _token = value;

  Uri _uri(String path, [Map<String, String?>? query]) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final values = query == null
        ? null
        : Map<String, String>.fromEntries(
            query.entries
                .where((entry) => entry.value?.isNotEmpty ?? false)
                .map((entry) => MapEntry(entry.key, entry.value!)),
          );
    return Uri.parse('$normalizedBase$path').replace(queryParameters: values);
  }

  Map<String, String> _headers({bool authenticated = true}) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (authenticated && _token != null) 'Authorization': 'Bearer $_token',
      };

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String?>? query,
    bool authenticated = true,
  }) async {
    final response = await _client
        .get(
          _uri(path, query),
          headers: _headers(authenticated: authenticated),
        )
        .timeout(const Duration(minutes: 3));
    return _decode(response);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final response = await _client
        .post(
          _uri(path),
          headers: _headers(authenticated: authenticated),
          body: jsonEncode(body ?? const {}),
        )
        .timeout(const Duration(minutes: 4));
    return _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> payload = const {};
    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        payload = Map<String, dynamic>.from(decoded);
      }
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = payload['detail'];
      throw ApiException(
        detail is String ? detail : 'The request could not be completed.',
        statusCode: response.statusCode,
      );
    }
    return payload;
  }
}
