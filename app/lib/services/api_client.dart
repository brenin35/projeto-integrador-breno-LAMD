import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => message;
}

class ApiClient {
  String? _token;

  void setToken(String? token) => _token = token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Uri _uri(String path) => Uri.parse('${AppConfig.apiBaseUrl}$path');

  Future<dynamic> get(String path) async =>
      _handle(await http.get(_uri(path), headers: _headers));

  Future<dynamic> post(String path, Map<String, dynamic> body) async =>
      _handle(await http.post(_uri(path), headers: _headers, body: jsonEncode(body)));

  Future<dynamic> put(String path, Map<String, dynamic> body) async =>
      _handle(await http.put(_uri(path), headers: _headers, body: jsonEncode(body)));

  Future<void> delete(String path) async =>
      _handle(await http.delete(_uri(path), headers: _headers));

  dynamic _handle(http.Response res) {
    final dynamic body = res.body.isNotEmpty ? jsonDecode(res.body) : null;
    if (res.statusCode >= 200 && res.statusCode < 300) return body;

    String message = 'Erro ${res.statusCode}';
    if (body is Map && body['error'] != null) {
      message = body['error'].toString();
    } else if (body is List && body.isNotEmpty) {
      final first = body.first;
      if (first is Map && first['message'] != null) message = first['message'].toString();
    }
    throw ApiException(res.statusCode, message);
  }
}
