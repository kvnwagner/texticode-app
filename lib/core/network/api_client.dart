import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';

/// Error uniforme para respuestas de la API. Conserva el texto del backend.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  bool get isUnauthorized => statusCode == 401 || statusCode == 403;

  @override
  String toString() => message;
}

/// Cliente HTTP único para las rutas protegidas de Texticode.
/// La empresa nunca se envía desde el teléfono: vive dentro del JWT.
class ApiClient {
  ApiClient._();

  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'texticode_token';

  static Future<Map<String, String>> headers({bool json = true}) async {
    final token = await _storage.read(key: _tokenKey);
    return {
      if (json) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Uri uri(String path, {Map<String, String>? query}) {
    if (ApiConstants.baseUrl.isEmpty) {
      throw const ApiException(
        'Falta configurar API_BASE_URL. Inicia la app con --dart-define=API_BASE_URL=http://IP:3001/api.',
      );
    }
    return Uri.parse('${ApiConstants.baseUrl}$path')
        .replace(queryParameters: query);
  }

  static Future<dynamic> get(String path, {Map<String, String>? query}) async =>
      _send(() async =>
          http.get(uri(path, query: query), headers: await headers()));

  static Future<dynamic> post(String path, {Object? body}) async => _send(
        () async => http.post(
          uri(path),
          headers: await headers(),
          body: body == null ? null : jsonEncode(body),
        ),
      );

  static Future<dynamic> put(String path, {Object? body}) async => _send(
        () async => http.put(
          uri(path),
          headers: await headers(),
          body: body == null ? null : jsonEncode(body),
        ),
      );

  static Future<dynamic> patch(String path, {Object? body}) async => _send(
        () async => http.patch(
          uri(path),
          headers: await headers(),
          body: body == null ? null : jsonEncode(body),
        ),
      );

  static Future<dynamic> delete(String path) async =>
      _send(() async => http.delete(uri(path), headers: await headers()));

  static Future<dynamic> _send(Future<http.Response> Function() request) async {
    try {
      final response = await request();
      dynamic data;
      try {
        data = response.body.isEmpty ? null : jsonDecode(response.body);
      } catch (_) {
        data = null;
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = data is Map<String, dynamic>
            ? (data['error'] ?? data['mensaje'] ?? 'Error en el servidor.')
            : 'Error en el servidor.';
        throw ApiException('$message', statusCode: response.statusCode);
      }
      return data;
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
          'No se pudo conectar con el servidor. Verifica tu conexión e inténtalo de nuevo.');
    }
  }
}
