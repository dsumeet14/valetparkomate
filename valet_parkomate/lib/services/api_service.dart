import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:valet_parkomate/config/api_config.dart';
import 'package:valet_parkomate/services/auth_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final AuthService _authService = AuthService();
  final Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
  };

  /// Retrieves a token from the AuthService and adds it to the headers.
  Future<Map<String, String>> _getAuthenticatedHeaders() async {
    final token = await _authService.getToken();
    if (token != null) {
      return {...defaultHeaders, 'Authorization': 'Bearer $token'};
    }
    return defaultHeaders;
  }

  Uri uri(String path) => Uri.parse(ApiConfig.api(path));

  Future<dynamic> get(String path) async {
    final headers = await _getAuthenticatedHeaders();
    final res = await http.get(uri(path), headers: headers).timeout(const Duration(seconds: 12));
    return _processResponse(res);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final headers = await _getAuthenticatedHeaders();
    final res = await http
        .post(uri(path), headers: headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 12));
    return _processResponse(res);
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final headers = await _getAuthenticatedHeaders();
    final res = await http
        .put(uri(path), headers: headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 12));
    return _processResponse(res);
  }

  Future<dynamic> delete(String path, {Map<String, dynamic>? body}) async {
    final headers = await _getAuthenticatedHeaders();
    final res = await http
        .delete(uri(path), headers: headers, body: body == null ? null : jsonEncode(body))
        .timeout(const Duration(seconds: 12));
    return _processResponse(res);
  }

  dynamic _processResponse(http.Response res) {
    final code = res.statusCode;
    final body = res.body.isEmpty ? '{}' : res.body;
    try {
      final parsed = jsonDecode(body);
      if (code >= 200 && code < 300) return parsed;
      throw ApiException(code, parsed is Map && parsed['message'] != null ? parsed['message'] : parsed.toString());
    } catch (e) {
      if (e is ApiException) rethrow;
      if (code >= 200 && code < 300) return body;
      throw ApiException(code, body);
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final dynamic message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => 'ApiException($statusCode): $message';
}