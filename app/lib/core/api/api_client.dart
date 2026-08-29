import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_exception.dart';
import 'api_endpoints.dart';

class ApiClient {
  final http.Client _client;
  final Duration timeout;

  // Static callbacks to obtain credentials and trigger refresh from AuthService without circular imports
  static String? Function()? tokenProvider;
  static Future<bool> Function()? onRefreshToken;

  ApiClient({
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client();

  // Dynamic headers appending access token if available
  Map<String, String> get _headers {
    final token = tokenProvider?.call();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Perform HTTP GET Request
  Future<dynamic> get(String endpoint, {Map<String, String>? headers}) async {
    try {
      final uri = Uri.parse(endpoint.startsWith('http') ? endpoint : ApiEndpoints.endpoint(endpoint));
      var response = await _client
          .get(uri, headers: {..._headers, ...?headers})
          .timeout(timeout);

      if (response.statusCode == 401 && onRefreshToken != null) {
        final success = await onRefreshToken!();
        if (success) {
          response = await _client
              .get(uri, headers: {..._headers, ...?headers})
              .timeout(timeout);
        }
      }

      return _processResponse(response);
    } on TimeoutException {
      throw ApiException(message: 'Request timed out after ${timeout.inSeconds} seconds');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Network error occurred: ${e.toString()}');
    }
  }

  /// Perform HTTP POST Request
  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse(endpoint.startsWith('http') ? endpoint : ApiEndpoints.endpoint(endpoint));
      var response = await _client
          .post(
            uri,
            headers: {..._headers, ...?headers},
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout);

      if (response.statusCode == 401 && onRefreshToken != null) {
        final success = await onRefreshToken!();
        if (success) {
          response = await _client
              .post(
                uri,
                headers: {..._headers, ...?headers},
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(timeout);
        }
      }

      return _processResponse(response);
    } on TimeoutException {
      throw ApiException(message: 'Request timed out after ${timeout.inSeconds} seconds');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Network error occurred: ${e.toString()}');
    }
  }

  /// Perform HTTP PUT Request
  Future<dynamic> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse(endpoint.startsWith('http') ? endpoint : ApiEndpoints.endpoint(endpoint));
      var response = await _client
          .put(
            uri,
            headers: {..._headers, ...?headers},
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout);

      if (response.statusCode == 401 && onRefreshToken != null) {
        final success = await onRefreshToken!();
        if (success) {
          response = await _client
              .put(
                uri,
                headers: {..._headers, ...?headers},
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(timeout);
        }
      }

      return _processResponse(response);
    } on TimeoutException {
      throw ApiException(message: 'Request timed out after ${timeout.inSeconds} seconds');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Network error occurred: ${e.toString()}');
    }
  }

  /// Perform HTTP DELETE Request
  Future<dynamic> delete(String endpoint, {Map<String, String>? headers}) async {
    try {
      final uri = Uri.parse(endpoint.startsWith('http') ? endpoint : ApiEndpoints.endpoint(endpoint));
      var response = await _client
          .delete(uri, headers: {..._headers, ...?headers})
          .timeout(timeout);

      if (response.statusCode == 401 && onRefreshToken != null) {
        final success = await onRefreshToken!();
        if (success) {
          response = await _client
              .delete(uri, headers: {..._headers, ...?headers})
              .timeout(timeout);
        }
      }

      return _processResponse(response);
    } on TimeoutException {
      throw ApiException(message: 'Request timed out after ${timeout.inSeconds} seconds');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Network error occurred: ${e.toString()}');
    }
  }

  /// Check backend server status
  Future<Map<String, dynamic>> checkHealth() async {
    final response = await get(ApiEndpoints.health);
    return response as Map<String, dynamic>;
  }

  /// Parse and process HTTP Response
  dynamic _processResponse(http.Response response) {
    dynamic jsonBody;
    try {
      if (response.body.isNotEmpty) {
        jsonBody = jsonDecode(response.body);
      }
    } catch (_) {
      jsonBody = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonBody;
    } else {
      final message = jsonBody is Map && jsonBody.containsKey('detail')
          ? jsonBody['detail'].toString()
          : 'HTTP ${response.statusCode}: Request failed';
      throw ApiException(
        message: message,
        statusCode: response.statusCode,
        details: jsonBody,
      );
    }
  }

  void dispose() {
    _client.close();
  }
}
